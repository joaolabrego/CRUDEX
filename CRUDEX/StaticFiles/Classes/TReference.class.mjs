"use strict";

export default class TReference {
    #Id = 0;
    #FkTableId = 0;
    #PkTableId = 0;
    #Name = "";
    #IsParentChild = false;
    /** Linhas brutas de Referencekeys (Config). */
    #Keys = [];
    /** Pares FK↔PK resolvidos após carregar colunas. */
    #KeyPairs = [];

    constructor(row, keys = []) {
        this.#Id = Number(row.Id);
        this.#FkTableId = Number(row.FkTableId);
        this.#PkTableId = Number(row.PkTableId);
        this.#Name = row.Name ?? "";
        this.#IsParentChild = !!(row.IsParentChild ?? row.IsParentChildren);
        this.#Keys = keys;
    }

    get Id() {
        return this.#Id;
    }

    get FkTableId() {
        return this.#FkTableId;
    }

    get PkTableId() {
        return this.#PkTableId;
    }

    get Name() {
        return this.#Name;
    }

    get IsParentChild() {
        return this.#IsParentChild;
    }

    get Keys() {
        return this.#Keys;
    }

    get KeyPairs() {
        return this.#KeyPairs;
    }

    /** Primeira coluna FK cadastrada em Referencekeys (ordem Sequence). */
    get LinkColumnId() {
        return this.#KeyPairs[0]?.fkColumnId
            ?? (this.#Keys[0]?.FkColumnId != null ? Number(this.#Keys[0].FkColumnId) : null);
    }

    /**
     * Pareia Referencekeys com colunas PK do pai (IsPrimarykey + ordem), espelhando ReferenceModel.
     * @param {import("./TTable.class.mjs").default | null} fkTable
     * @param {import("./TTable.class.mjs").default | null} pkTable
     * @param {(columnId: number) => import("./TColumn.class.mjs").default | undefined} getColumn
     */
    resolve(fkTable, pkTable, pkColumns, getColumn) {
        const orderedPkColumns = pkColumns ?? [];
        const rawKeys = [...this.#Keys].sort((left, right) =>
            Number(left.Sequence) - Number(right.Sequence),
        );

        if (rawKeys.length !== orderedPkColumns.length) {
            throw new Error(
                `Reference ${this.#Id} ('${this.#Name}'): ${rawKeys.length} chave(s) em Referencekeys, `
                + `mas a PK de '${pkTable?.Name ?? this.#PkTableId}' tem ${orderedPkColumns.length} coluna(s).`,
            );
        }

        this.#KeyPairs = rawKeys.map((raw, index) => {
            const fkColumnId = Number(raw.FkColumnId);
            const fkColumn = fkTable?.GetColumn(fkColumnId) ?? getColumn(fkColumnId);
            const pkColumn = orderedPkColumns[index];

            if (!fkColumn)
                throw new Error(`Reference ${this.#Id}: FkColumnId ${fkColumnId} não encontrada.`);
            if (!pkColumn)
                throw new Error(`Reference ${this.#Id}: PK posição ${index + 1} não encontrada.`);

            return {
                sequence: Number(raw.Sequence),
                fkColumnId,
                pkColumnId: pkColumn.Id,
                fkColumn,
                pkColumn,
            };
        });
    }

    getKeyPairForFkColumn(columnId) {
        return this.#KeyPairs.find(pair => Number(pair.fkColumnId) === Number(columnId)) ?? null;
    }
}
