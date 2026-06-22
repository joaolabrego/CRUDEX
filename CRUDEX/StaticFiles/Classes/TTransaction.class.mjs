"use strict";

import TConfig from "./TConfig.class.mjs";
import TLogin from "./TLogin.class.mjs";
import TSystem from "./TSystem.class.mjs";
import TTable from "./TTable.class.mjs";

/**
 * Ciclo de transação do CRUDEX (Trs → Ope → Commit).
 *
 * Abrir transação: create na tabela de transação ({alias}_create / {Alias}Create).
 * Só abre transação quando há persist de facto (stage/save). Abrir formulário,
 * filtro, pesquisa ou cancelar não chama create.
 *
 * Formulário sem filhos: Confirmar → save() (stage + commit).
 * Formulário pai com tabelas filhas: Persistir → stage(); Confirmar → commit().
 * Formulário filho (masterForm): só Confirmar → stage() e volta ao pai (nunca commit).
 */
export default class TTransaction {
    static #transactionId = 0;

    static get id() {
        return this.#transactionId;
    }

    static get isOpen() {
        return this.#transactionId > 0;
    }

    static #transactionTable() {
        const table = TSystem.GetTable("Transactions");
        if (!table)
            throw new Error("Tabela Transactions não encontrada na configuração.");
        return table;
    }

    static #executeParameters(table, action, inParams = {}, ioParams = {}, targetTable = null) {
        const target = targetTable ?? table;
        return {
            DatabaseName: target.Database.Name,
            TableName: target.Name,
            Action: action,
            InParams: inParams,
            OutParams: {},
            IOParams: ioParams,
        };
    }

    static async #callExecute(parameters) {
        return await TConfig.GetAPI(TSystem.Actions.EXECUTE, parameters);
    }

    static async #begin(table) {
        const result = await this.#callExecute(this.#executeParameters(table, TSystem.Actions.CREATE, {
            SessionId: TLogin.LoginId,
            UserName: TLogin.UserName,
        }, {}, this.#transactionTable()));
        const transactionId = Number(result.Parameters?.ReturnValue ?? 0);
        if (!transactionId)
            throw new Error("Transação não iniciada.");
        return transactionId;
    }

    static async #persist(table, formAction, actualRecord, lastRecord = null) {
        if (!this.#transactionId)
            throw new Error("TransactionId é requerido.");
        await this.#callExecute(this.#executeParameters(table, TSystem.Actions.PERSIST, {
            TransactionId: this.#transactionId,
            Action: formAction,
            LastRecord: lastRecord ? JSON.stringify(lastRecord) : null,
            ActualRecord: formAction === TSystem.Actions.DELETE ? null : JSON.stringify(actualRecord),
        }));
    }

    static async #commit(table, transactionId) {
        await this.#callExecute(this.#executeParameters(table, TSystem.Actions.COMMIT, {
            TransactionId: transactionId,
        }, {}, this.#transactionTable()));
    }

    static async #rollback(table, transactionId) {
        await this.#callExecute(this.#executeParameters(table, TSystem.Actions.ROLLBACK, {
            TransactionId: transactionId,
            UserName: TLogin.UserName,
        }, {}, this.#transactionTable()));
    }

    static #assertTable(table) {
        if (!(table instanceof TTable))
            throw new Error("Argumento table não é do tipo TTable.");
    }

    static async open(table) {
        this.#assertTable(table);
        if (this.#transactionId)
            return this.#transactionId;
        const transactionId = await this.#begin(table);
        this.#transactionId = transactionId;
        return transactionId;
    }

    static async stage(table, formAction, actualRecord, lastRecord = null) {
        this.#assertTable(table);
        await this.open(table);
        await this.#persist(table, formAction, actualRecord, lastRecord);
    }

    static async commit(table) {
        this.#assertTable(table);
        if (!this.#transactionId)
            return;
        const transactionId = this.#transactionId;
        await this.#commit(table, transactionId);
        this.#transactionId = 0;
    }

    static async rollback(table) {
        this.#assertTable(table);
        if (!this.#transactionId)
            return;
        const transactionId = this.#transactionId;
        await this.#rollback(table, transactionId);
        this.#transactionId = 0;
    }

    /** Formulário simples: valida, grava na Ope e confirma na mesma chamada. */
    static async save(table, formAction, actualRecord, lastRecord = null) {
        this.#assertTable(table);
        await this.open(table);
        await this.#persist(table, formAction, actualRecord, lastRecord);
        await this.commit(table);
    }
}
