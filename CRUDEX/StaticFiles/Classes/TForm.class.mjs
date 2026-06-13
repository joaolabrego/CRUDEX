"use strict";

import TScreen from "./TScreen.class.mjs";
import TEditBox from "./TEditBox.class.mjs";
import TGrid from "./TGrid.class.mjs";
import TSystem from "./TSystem.class.mjs";
import TTransaction from "./TTransaction.class.mjs";

export default class TForm {
    #Action = "";
    #ReturnAction = "";
    static #Style = "";
    static #Images = {
        Confirm: "",
        Cancel: "",
        Exit: "",
    };
    #HTML = {
        FirstInput: null,
        Container: null,
        Form: null,
        ButtonsBar: null,
        ConfirmButton: null,
        CancelButton: null,
    };
    #Grid = null;
    #actualRecord = null;
    #lastRecord = null;
    #SourceRecord = null;
    #isStaged = false;

    constructor(grid, action) {
        if (!(grid instanceof TGrid))
            throw new Error("Argumento grid não é do tipo TGrid.");
        this.#Grid = grid;
        this.#Action = action;
        this.#ReturnAction = `grid/${this.#Grid.Table.Database.Name}/${this.#Grid.Table.Name}`;
        this.#HTML.Container = document.createDocumentFragment();
        this.#BuildForm();
        this.#BuildButtonsBar();
    }
    static Initialize(styles, images) {
        if (styles.ClassName !== "Styles")
            throw new Error("Argumento styles não é do tipo Styles.");
        if (images.ClassName !== "Images")
            throw new Error("Argumento images não é do tipo Images.");
        this.#Style = styles.Form;
        this.#Images.Confirm = images.Confirm;
        this.#Images.Cancel = images.Cancel;
        this.#Images.Exit = images.Exit;
    }
    #blankRecord() {
        const record = {};
        for (const column of this.#Grid.Table.Columns)
            record[column.Name] = null;
        return record;
    }
    #copyRecord(source) {
        const record = this.#blankRecord();
        if (!source)
            return record;
        for (const column of this.#Grid.Table.Columns)
            record[column.Name] = source[column.Name] ?? null;
        return record;
    }
    #recordsAreEqual(left, right) {
        if (!left || !right)
            return false;
        for (const column of this.#Grid.Table.Columns) {
            const leftValue = left[column.Name];
            const rightValue = right[column.Name];
            if (leftValue === rightValue)
                continue;
            if (leftValue == null && rightValue == null)
                continue;
            return false;
        }
        return true;
    }
    #hasChanges() {
        return !this.#recordsAreEqual(this.#actualRecord, this.#lastRecord);
    }
    #showsPersist() {
        if (!this.#isPersistAction())
            return false;
        if (this.#Action === TSystem.Actions.DELETE)
            return !this.#isStaged;
        return this.#hasChanges();
    }
    #updateConfirmButton() {
        if (this.#Action === TSystem.Actions.QUERY)
            return;
        const persist = this.#showsPersist();
        this.#HTML.ConfirmButton.innerText = persist ? "Persistir" : "Confirmar";
        this.#HTML.ConfirmButton.style.backgroundImage = TForm.#Images.Confirm;
        if (this.#isPersistAction())
            this.#HTML.ConfirmButton.disabled = !persist && !this.#isStaged;
        else
            this.#HTML.ConfirmButton.disabled = false;
    }
    #onFieldChange(name, value) {
        this.#actualRecord[name] = value;
        this.#updateConfirmButton();
    }
    async #LoadRecord(columns) {
        let source = this.#Grid.SelectedRecord;

        if (!source) {
            source = await this.#Grid.RecordSet.readOne(this.#Grid.Primarykeys);
            if (!source)
                throw new Error("Registro não encontrado.");
        }
        this.#SourceRecord = source;
        this.#lastRecord = this.#copyRecord(source);
        this.#actualRecord = this.#copyRecord(source);
    }
    #persistLastRecord() {
        if (this.#Action === TSystem.Actions.CREATE)
            return null;
        return this.#lastRecord;
    }
    #isPersistAction() {
        return this.#Action === TSystem.Actions.CREATE
            || this.#Action === TSystem.Actions.UPDATE
            || this.#Action === TSystem.Actions.DELETE;
    }
    #captureFocus() {
        const active = document.activeElement;
        if (active instanceof HTMLElement && this.#HTML.Container.contains(active))
            return active;
        return this.#HTML.FirstInput ?? this.#HTML.ConfirmButton;
    }
    #restoreFocus(element) {
        let target = element;
        if (!(target instanceof HTMLElement) || !target.isConnected)
            target = this.#HTML.FirstInput ?? this.#HTML.ConfirmButton;
        target?.focus();
        if (target && typeof target.select === "function")
            target.select();
    }
    #showError(error, focusTarget) {
        TScreen.ShowError(
            error.message || error.Message,
            null,
            null,
            () => this.#restoreFocus(focusTarget),
        );
    }
    async #confirm() {
        if (this.#isPersistAction() && !this.#HTML.Form.reportValidity())
            return;
        if (this.#Action === TSystem.Actions.FILTER) {
            this.#Grid.SaveFilters(this.#actualRecord);
        }
        else if (this.#Action === TSystem.Actions.SEARCH) {
            this.#Grid.SaveSearchs(this.#actualRecord);
        }
        else if (this.#isPersistAction()) {
            if (!TSystem.IsSimpleTable(this.#Grid.Table))
                throw new Error("Formulário master-detail ainda não implementado.");
            if (this.#showsPersist()) {
                await TTransaction.stage(
                    this.#Grid.Table,
                    this.#Action,
                    this.#actualRecord,
                    this.#persistLastRecord(),
                );
                this.#lastRecord = this.#copyRecord(this.#actualRecord);
                this.#isStaged = true;
                this.#updateConfirmButton();
                return;
            }
            if (TTransaction.isOpen) {
                await TTransaction.commit(this.#Grid.Table);
                this.#isStaged = false;
            }
        }
        await this.#Grid.Renderize();
    }
    async Configure() {
        let columns = this.#Grid.Table.Columns;

        this.#actualRecord = this.#blankRecord();
        this.#lastRecord = this.#blankRecord();
        this.#isStaged = false;
        switch (this.#Action) {
            case TSystem.Actions.CREATE:
                columns = columns.filter(column => column.IsEditable);
                break;
            case TSystem.Actions.SEARCH:
                columns = columns.filter(column => column.IsFilterable);
                break;
            case TSystem.Actions.FILTER:
                columns = columns.filter(column => column.IsFilterable);
                for (const column of columns)
                    this.#actualRecord[column.Name] = this.#Grid.FilterValues[column.Name];
                break;
            case TSystem.Actions.UPDATE:
                columns = columns.filter(column => column.IsEditable);
                await this.#LoadRecord(columns);
                break;
            default:
                await this.#LoadRecord(columns);
        }
        for (const column of columns) {
            TEditBox.Create(column, this.#HTML.Form)
                .configure({
                    action: this.#Action,
                    record: this.#actualRecord,
                    sourceRecord: this.#SourceRecord,
                    onChange: (name, value) => this.#onFieldChange(name, value),
                    onConfirm: () => this.#HTML.ConfirmButton.click(),
                    onCancel: () => this.#HTML.CancelButton?.click(),
                    onFirstInput: (input) => {
                        if (!this.#HTML.FirstInput)
                            this.#HTML.FirstInput = input;
                    },
                });
        }
        this.#updateConfirmButton();

        return this;
    }
    Renderize() {
        let title = "",
            message = "";

        switch (this.#Action) {
            case TSystem.Actions.CREATE:
                title = "Inclusão";
                message = "Preencha os dados, clique em persistir e depois em confirmar...";
                break;
            case TSystem.Actions.UPDATE:
                title = "Alteração";
                message = "Altere os dados, clique em persistir e depois em confirmar...";
                break;
            case TSystem.Actions.DELETE:
                title = "Exclusão";
                message = "Clique em persistir e depois em confirmar para excluir...";
                break;
            case TSystem.Actions.SEARCH:
                title = "Pesquisa";
                message = "Digite as informações e clique em confirmar para pesquisá-las...";
                break;
            case TSystem.Actions.FILTER:
                title = "Filtragem";
                message = "Digite as informações e clique em confirmar para filtrá-las...";
                break;
            case TSystem.Actions.QUERY:
                title = "Consulta";
                message = "Visualize as informações e clique sair para retornar...";
                break;
        }
        TScreen.Title = `${title} de ${this.#Grid.Table.Description}`;
        TScreen.LastMessage = TScreen.Message = message;
        TScreen.WithBackgroundImage = false;
        TScreen.Main = this.#HTML.Container;
        if (this.#HTML.FirstInput)
            this.#HTML.FirstInput.focus();
    }
    #BuildForm() {
        this.#HTML.Form = document.createElement("form");
        this.#HTML.Form.method = "post";
        this.#HTML.Form.autocomplete = "off";
        this.#HTML.Form.className = "form";

        let style = document.createElement("style");

        style.innerText = TForm.#Style;
        this.#HTML.Form.appendChild(style);
        this.#HTML.Container.appendChild(this.#HTML.Form);
    }
    #BuildButtonsBar() {
        this.#HTML.ButtonsBar = document.createElement("div");
        this.#HTML.ButtonsBar.className = "buttonsBar";

        this.#HTML.ConfirmButton = document.createElement("button");
        this.#HTML.ConfirmButton.className = "button box";
        if (this.#Action === TSystem.Actions.QUERY) {
            this.#HTML.ConfirmButton.innerText = "Sair";
            this.#HTML.ConfirmButton.style.backgroundImage = TForm.#Images.Exit;
        }
        else {
            this.#HTML.ConfirmButton.innerText = "Confirmar";
            this.#HTML.ConfirmButton.style.backgroundImage = TForm.#Images.Confirm;
        }
        this.#HTML.ConfirmButton.type = "button";
        this.#HTML.ConfirmButton.onclick = async () => {
            const focusTarget = this.#captureFocus();
            try {
                await this.#confirm();
            } catch (error) {
                this.#showError(error, focusTarget);
            }
        };
        this.#HTML.ButtonsBar.appendChild(this.#HTML.ConfirmButton);

        if (this.#Action !== TSystem.Actions.QUERY) {
            this.#HTML.CancelButton = document.createElement("button");
            this.#HTML.CancelButton.innerText = "Cancelar";
            this.#HTML.CancelButton.className = "button box";
            this.#HTML.CancelButton.type = "reset";
            this.#HTML.CancelButton.style.backgroundImage = TForm.#Images.Cancel;
            this.#HTML.CancelButton.onclick = async () => {
                const focusTarget = this.#captureFocus();
                try {
                    await TTransaction.rollback(this.#Grid.Table);
                    this.#isStaged = false;
                    await this.#Grid.Renderize();
                } catch (error) {
                    this.#showError(error, focusTarget);
                }
            };
            this.#HTML.ButtonsBar.appendChild(this.#HTML.CancelButton);
        }

        this.#HTML.Container.appendChild(this.#HTML.ButtonsBar);
    }
    get actualRecord() {
        return this.#actualRecord;
    }
    get lastRecord() {
        return this.#lastRecord;
    }
    get canAccessChildren() {
        return this.#isPersistAction() && !this.#showsPersist();
    }
}
