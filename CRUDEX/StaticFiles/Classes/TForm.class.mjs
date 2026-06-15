"use strict";

import TScreen from "./TScreen.class.mjs";
import TConfig from "./TConfig.class.mjs";
import TEditBox from "./TEditBox.class.mjs";
import TGrid from "./TGrid.class.mjs";
import TSystem from "./TSystem.class.mjs";
import TTransaction from "./TTransaction.class.mjs";

export default class TForm {
    static #COLUMNS_TABLE = "Columns";
    static #DOMAINS_TABLE = "Domains";
    static #COLUMNS_DRIVER = "DomainId";
    static #DOMAINS_DRIVER = "TypeId";
    static #METADATA_FIELD_FLAGS = {
        Columns: {
            Default: { source: "category", flag: "AskDefault", variant: true },
            Minimum: { source: "category", flag: "AskMinimum", variant: true },
            Maximum: { source: "category", flag: "AskMaximum", variant: true },
            IsEncrypted: { source: "category", flag: "AskEncrypted" },
            IsListable: { source: "category", flag: "AskListable" },
            IsInWords: { source: "category", flag: "AskInWords" },
            IsPrimarykey: { source: "type", flag: "AskPrimarykey" },
            IsAutoIncrement: { source: "type", flag: "AskAutoincrement" },
            IsFilterable: { source: "type", flag: "AskFilterable" },
            IsGridable: { source: "type", flag: "AskGridable" },
        },
        Domains: {
            MaskId: { source: "category", flag: "AskMask" },
            Length: { source: "type", flag: "AskLength" },
            Decimals: { source: "type", flag: "AskDecimals" },
            Codification: { source: "type", flag: "AskCodification" },
            Default: { source: "category", flag: "AskDefault", variant: true },
            Minimum: { source: "category", flag: "AskMinimum", variant: true },
            Maximum: { source: "category", flag: "AskMaximum", variant: true },
        },
    };
    static #FORM_GRID_COLUMNS = 5;

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
        DetailPane: null,
        DetailTabs: null,
        DetailGridPanel: null,
    };
    #Grid = null;
    #masterForm = null;
    #childGrids = [];
    #activeChildIndex = 0;
    #isMasterDetail = false;
    #detailParentTable = null;
    #actualRecord = null;
    #lastRecord = null;
    #SourceRecord = null;
    #isStaged = false;
    #editBoxes = [];

    constructor(grid, action, options = {}) {
        if (!(grid instanceof TGrid))
            throw new Error("Argumento grid não é do tipo TGrid.");
        this.#Grid = grid;
        this.#masterForm = options.masterForm ?? null;
        this.#Action = action;
        this.#ReturnAction = `grid/${this.#Grid.Table.Database.Name}/${this.#Grid.Table.Name}`;
        this.#HTML.Container = document.createElement("div");
        this.#HTML.Container.className = "form-screen";
    }
    #resolveParentTable() {
        return this.#Grid.Table;
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
        if (!this.#isPersistAction() || this.#masterForm)
            return false;
        if (this.#Action === TSystem.Actions.DELETE)
            return !this.#isStaged;
        return this.#hasChanges();
    }
    #updateConfirmButton() {
        if (this.#Action === TSystem.Actions.QUERY)
            return;
        if (this.#masterForm && this.#isPersistAction()) {
            this.#HTML.ConfirmButton.innerText = "Confirmar";
            this.#HTML.ConfirmButton.style.backgroundImage = TForm.#Images.Confirm;
            this.#HTML.ConfirmButton.disabled =
                this.#Action === TSystem.Actions.UPDATE && !this.#hasChanges();
            return;
        }
        const persist = this.#showsPersist();
        this.#HTML.ConfirmButton.innerText = persist ? "Persistir" : "Confirmar";
        this.#HTML.ConfirmButton.style.backgroundImage = TForm.#Images.Confirm;
        if (this.#isPersistAction())
            this.#HTML.ConfirmButton.disabled = !TTransaction.isOpen && !persist;
        else
            this.#HTML.ConfirmButton.disabled = false;
    }
    #onFieldChange(name, value) {
        this.#actualRecord[name] = value;
        const driver = this.#metadataDriverColumn();
        if (driver && name === driver)
            this.#refreshMetadataVariantFields();
        this.#updateConfirmButton();
        this.#updateDetailAccess();
    }

    #collectFilterValues() {
        for (const edit of this.#editBoxes) {
            if (edit.element.style.display === "none") {
                this.#actualRecord[edit.column.Name] = null;
                continue;
            }
            const value = edit.collectFilterValue(this.#Action);
            if (value !== undefined)
                this.#actualRecord[edit.column.Name] = value;
        }
    }

    #editConfigureOptions() {
        return {
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
        };
    }

    #metadataDriverColumn() {
        if (this.#Grid.Table.Name === TForm.#COLUMNS_TABLE)
            return TForm.#COLUMNS_DRIVER;
        if (this.#Grid.Table.Name === TForm.#DOMAINS_TABLE)
            return TForm.#DOMAINS_DRIVER;
        return null;
    }

    #metadataFieldRule(column) {
        const rules = TForm.#METADATA_FIELD_FLAGS[this.#Grid.Table.Name];
        return rules?.[column.Name] ?? null;
    }

    #metadataAskContext() {
        if (this.#Grid.Table.Name === TForm.#COLUMNS_TABLE) {
            const domainId = this.#actualRecord[TForm.#COLUMNS_DRIVER];
            if (TConfig.IsEmpty(domainId))
                return null;
            const domain = TSystem.GetDomain(domainId);
            if (!domain?.Type?.Category)
                return null;
            return { category: domain.Type.Category, type: domain.Type };
        }
        if (this.#Grid.Table.Name === TForm.#DOMAINS_TABLE) {
            const typeId = this.#actualRecord[TForm.#DOMAINS_DRIVER];
            if (TConfig.IsEmpty(typeId))
                return null;
            const type = TSystem.GetType(typeId);
            if (!type?.Category)
                return null;
            return { category: type.Category, type };
        }
        return null;
    }

    #metadataFieldVisible(column) {
        const rule = this.#metadataFieldRule(column);
        if (!rule)
            return true;

        const context = this.#metadataAskContext();
        if (!context)
            return false;

        const source = rule.source === "category" ? context.category : context.type;
        return source?.[rule.flag] === true;
    }

    #metadataDomainVariant(column) {
        const rule = this.#metadataFieldRule(column);
        if (!rule?.variant)
            return undefined;

        if (this.#Grid.Table.Name === TForm.#COLUMNS_TABLE) {
            const domainId = this.#actualRecord[TForm.#COLUMNS_DRIVER];
            if (TConfig.IsEmpty(domainId))
                return null;
            return TSystem.GetDomain(domainId);
        }
        if (this.#Grid.Table.Name === TForm.#DOMAINS_TABLE) {
            const typeId = this.#actualRecord[TForm.#DOMAINS_DRIVER];
            if (TConfig.IsEmpty(typeId))
                return null;
            const type = TSystem.GetType(typeId);
            if (!type)
                return null;
            return {
                Length: this.#actualRecord.Length,
                Decimals: this.#actualRecord.Decimals,
                Type: type,
            };
        }
        return undefined;
    }

    #refreshMetadataVariantFields() {
        const baseOptions = this.#editConfigureOptions();
        for (const edit of this.#editBoxes) {
            const column = edit.column;
            if (!this.#metadataFieldRule(column))
                continue;

            const visible = this.#metadataFieldVisible(column);
            edit.element.style.display = visible ? "" : "none";
            if (!visible) {
                this.#actualRecord[column.Name] = null;
                continue;
            }

            const options = { ...baseOptions };
            const variant = this.#metadataDomainVariant(column);
            if (variant !== undefined)
                options.domainVariant = variant;
            edit.configure(options);
        }
        this.#balanceFormGridTail();
    }

    #balanceFormGridTail() {
        const form = this.#HTML.Form;
        if (!form)
            return;

        const cells = [...form.children].filter(el =>
            (el.tagName === "FIELDSET" || el.classList.contains("tedit-field"))
            && el.style.display !== "none");

        for (const el of cells)
            el.style.gridColumn = "";

        const remainder = cells.length % TForm.#FORM_GRID_COLUMNS;
        if (remainder === 0)
            return;

        const startCol = Math.floor((TForm.#FORM_GRID_COLUMNS - remainder) / 2) + 1;
        cells.slice(-remainder).forEach((el, index) => {
            el.style.gridColumn = String(startCol + index);
        });
    }
    #ensureLayout() {
        if (this.#masterForm) {
            if (!this.#HTML.Form) {
                this.#BuildForm(this.#HTML.Container);
                this.#BuildButtonsBar(this.#HTML.Container);
            }
            return;
        }
        this.#detailParentTable = this.#Grid.Table;
        const childTables = TSystem.GetChildTables(this.#detailParentTable);
        this.#isMasterDetail = childTables.length > 0;

        if (!this.#isMasterDetail) {
            if (!this.#HTML.Form) {
                this.#BuildForm(this.#HTML.Container);
                this.#BuildButtonsBar(this.#HTML.Container);
            }
            return;
        }

        if (!this.#HTML.Form) {
            const workspace = document.createElement("div");
            workspace.className = "master-detail-workspace";

            const masterPane = document.createElement("div");
            masterPane.className = "master-pane";
            this.#BuildForm(masterPane);
            this.#BuildButtonsBar(masterPane);
            workspace.appendChild(masterPane);

            const detailPane = document.createElement("div");
            detailPane.className = "detail-pane detail-pane-disabled";
            this.#HTML.DetailPane = detailPane;

            const tabsBar = document.createElement("div");
            tabsBar.className = "detail-tabs";
            this.#HTML.DetailTabs = tabsBar;
            detailPane.appendChild(tabsBar);

            const gridPanel = document.createElement("div");
            gridPanel.className = "detail-grid-panel";
            this.#HTML.DetailGridPanel = gridPanel;
            detailPane.appendChild(gridPanel);

            workspace.appendChild(detailPane);
            this.#HTML.Container.appendChild(workspace);
        }

        this.#rebuildChildGrids(childTables);
    }
    #rebuildChildGrids(childTables) {
        this.#childGrids = [];
        this.#HTML.DetailTabs.replaceChildren();
        this.#HTML.DetailGridPanel.replaceChildren();

        childTables.forEach((childTable, index) => {
            const tab = document.createElement("button");
            tab.type = "button";
            tab.className = "detail-tab";
            tab.textContent = childTable.Description;
            tab.onclick = async () => {
                try {
                    await this.#selectChildTab(index);
                } catch (error) {
                    this.#showError(error, tab);
                }
            };
            this.#HTML.DetailTabs.appendChild(tab);

            const section = document.createElement("section");
            section.className = "detail-grid-section";

            const linkColumn = TSystem.GetParentLinkColumn(
                childTable,
                this.#detailParentTable,
                this.#Grid.Table,
            );
            const childGrid = new TGrid(childTable.Database.Name, childTable.Name, {
                embedded: true,
                masterForm: this,
            });
            childGrid.setEnabled(false);
            section.appendChild(childGrid.HostElement);
            this.#HTML.DetailGridPanel.appendChild(section);
            this.#childGrids.push({ table: childTable, grid: childGrid, linkColumn, section, tab });
        });

        this.#selectChildTab(0, false);
    }
    async #returnToCaller(gridPageNumber = null) {
        if (this.#masterForm)
            await this.#masterForm.Renderize();
        else if (gridPageNumber != null)
            await this.#Grid.Renderize(gridPageNumber);
        else
            await this.#Grid.Renderize();
    }
    async #selectChildTab(index, render = true) {
        if (index < 0 || index >= this.#childGrids.length)
            return;
        this.#activeChildIndex = index;
        for (let i = 0; i < this.#childGrids.length; i++) {
            const { section, tab } = this.#childGrids[i];
            const active = i === index;
            section.classList.toggle("active", active);
            tab.classList.toggle("active", active);
        }
        if (render && this.canAccessChildren)
            await this.#renderChildGrid(index);
    }
    async #renderChildGrid(index) {
        const entry = this.#childGrids[index];
        if (!entry)
            return;
        const parentId = this.#actualRecord?.Id ?? this.#lastRecord?.Id;
        if (!parentId)
            return;
        const { grid, linkColumn } = entry;
        if (linkColumn)
            grid.setParentFilter(linkColumn.Name, parentId);
        await grid.Renderize(1);
    }
    #updateDetailAccess() {
        if (!this.#isMasterDetail)
            return;
        const enabled = this.canAccessChildren;
        this.#HTML.DetailPane?.classList.toggle("detail-pane-disabled", !enabled);
        for (const { grid } of this.#childGrids)
            grid.setEnabled(enabled);
    }
    async #refreshChildGrids() {
        if (!this.#isMasterDetail || !this.canAccessChildren)
            return;
        await this.#renderChildGrid(this.#activeChildIndex);
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
        if (this.#isPersistAction() && !this.#validateForm())
            return;
        if (this.#Action === TSystem.Actions.FILTER) {
            this.#collectFilterValues();
            this.#Grid.SaveFilters(this.#actualRecord);
            await this.#returnToCaller(1);
            return;
        }
        else if (this.#Action === TSystem.Actions.SEARCH) {
            this.#collectFilterValues();
            this.#Grid.SaveSearchs(this.#actualRecord);
            await this.#returnToCaller(1);
            this.#Grid.ClearSearches();
            return;
        }
        else if (this.#isPersistAction()) {
            if (this.#masterForm) {
                if (this.#Action === TSystem.Actions.UPDATE && !this.#hasChanges())
                    return;
                await TTransaction.stage(
                    this.#Grid.Table,
                    this.#Action,
                    this.#actualRecord,
                    this.#persistLastRecord(),
                );
                await this.#masterForm.Renderize();
                return;
            }
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
                this.#updateDetailAccess();
                await this.#refreshChildGrids();
                if (this.#isMasterDetail) {
                    TScreen.Main = this.#HTML.Container;
                    this.#HTML.FirstInput?.focus();
                }
                return;
            }
            if (TTransaction.isOpen) {
                await TTransaction.commit(this.#Grid.Table);
                this.#isStaged = false;
            }
            if (this.#Action === TSystem.Actions.CREATE && !this.#masterForm) {
                await this.#restartCreate();
                return;
            }
        }
        await this.#returnToCaller();
    }
    #clearFormFields() {
        if (!this.#HTML.Form)
            return;
        const style = this.#HTML.Form.querySelector("style");
        this.#HTML.Form.replaceChildren();
        if (style)
            this.#HTML.Form.appendChild(style);
    }
    async #restartCreate() {
        this.#HTML.FirstInput = null;
        this.#SourceRecord = null;
        await this.Configure();
        await this.Renderize();
    }
    #validateForm() {
        for (const edit of this.#editBoxes) {
            if (edit.element.style.display === "none")
                continue;
            if (!edit.reportValidity())
                return false;
        }
        return true;
    }
    #excludeParentLinkColumn(columns, setParentValue = false) {
        if (!this.#masterForm)
            return columns;
        const linkColumn = TSystem.GetParentLinkColumn(
            this.#Grid.Table,
            this.#masterForm.parentTable,
            this.#masterForm.Table,
        );
        if (!linkColumn)
            return columns;
        if (setParentValue) {
            const parentId = this.#masterForm.actualRecord?.Id
                ?? this.#masterForm.lastRecord?.Id;
            if (parentId != null)
                this.#actualRecord[linkColumn.Name] = parentId;
        }
        return columns.filter(column => column !== linkColumn);
    }
    async Configure() {
        let columns = this.#Grid.Table.Columns;

        this.#actualRecord = this.#blankRecord();
        this.#lastRecord = this.#blankRecord();
        this.#isStaged = false;
        this.#editBoxes = [];
        switch (this.#Action) {
            case TSystem.Actions.CREATE:
                columns = this.#excludeParentLinkColumn(
                    columns.filter(column => column.IsEditable),
                    true,
                );
                break;
            case TSystem.Actions.SEARCH:
                columns = columns.filter(column => column.IsFilterable);
                for (const column of columns)
                    this.#actualRecord[column.Name] = this.#Grid.SearchValues[column.Name];
                break;
            case TSystem.Actions.FILTER:
                columns = columns.filter(column => column.IsFilterable);
                for (const column of columns)
                    this.#actualRecord[column.Name] = this.#Grid.FilterValues[column.Name];
                break;
            case TSystem.Actions.UPDATE:
                columns = columns.filter(column => column.IsEditable);
                await this.#LoadRecord(columns);
                columns = this.#excludeParentLinkColumn(columns);
                break;
            case TSystem.Actions.DELETE:
                await this.#LoadRecord(columns);
                columns = this.#excludeParentLinkColumn(columns);
                break;
            default:
                await this.#LoadRecord(columns);
        }
        this.#ensureLayout();
        this.#clearFormFields();
        const baseOptions = this.#editConfigureOptions();
        for (const column of columns) {
            const options = { ...baseOptions };
            const variant = this.#metadataDomainVariant(column);
            if (variant !== undefined)
                options.domainVariant = variant;
            const edit = TEditBox.Create(column, this.#HTML.Form).configure(options);
            if (!this.#metadataFieldVisible(column))
                edit.element.style.display = "none";
            this.#editBoxes.push(edit);
        }
        if (this.#metadataDriverColumn())
            this.#refreshMetadataVariantFields();
        else
            this.#balanceFormGridTail();
        this.#updateConfirmButton();
        this.#updateDetailAccess();
        await this.#refreshChildGrids();

        return this;
    }
    async Renderize() {
        let title = "",
            message = "";

        switch (this.#Action) {
            case TSystem.Actions.CREATE:
                title = "Inclusão";
                message = this.#masterForm
                    ? "Preencha os dados e clique em confirmar..."
                    : "Preencha os dados, clique em persistir e depois em confirmar...";
                break;
            case TSystem.Actions.UPDATE:
                title = "Alteração";
                message = this.#masterForm
                    ? "Altere os dados e clique em confirmar..."
                    : "Altere os dados, clique em persistir e depois em confirmar...";
                break;
            case TSystem.Actions.DELETE:
                title = "Exclusão";
                message = this.#masterForm
                    ? "Clique em confirmar para excluir..."
                    : "Clique em persistir e depois em confirmar para excluir...";
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
        if (this.#isMasterDetail && this.canAccessChildren)
            await this.#refreshChildGrids();
        this.#updateConfirmButton();
        this.#updateDetailAccess();
        if (this.#HTML.FirstInput)
            this.#HTML.FirstInput.focus();
    }
    #BuildForm(parent) {
        this.#HTML.Form = document.createElement("form");
        this.#HTML.Form.method = "post";
        this.#HTML.Form.autocomplete = "off";
        this.#HTML.Form.className = "form";

        let style = document.createElement("style");

        style.innerText = TForm.#Style;
        this.#HTML.Form.appendChild(style);
        parent.appendChild(this.#HTML.Form);
    }
    #BuildButtonsBar(parent) {
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
                    if (this.#masterForm) {
                        await this.#masterForm.Renderize();
                        return;
                    }
                    await TTransaction.rollback(this.#Grid.Table);
                    this.#isStaged = false;
                    await this.#returnToCaller();
                } catch (error) {
                    this.#showError(error, focusTarget);
                }
            };
            this.#HTML.ButtonsBar.appendChild(this.#HTML.CancelButton);
        }

        parent.appendChild(this.#HTML.ButtonsBar);
    }
    get actualRecord() {
        return this.#actualRecord;
    }
    get Table() {
        return this.#Grid.Table;
    }
    get parentTable() {
        return this.#resolveParentTable();
    }
    get lastRecord() {
        return this.#lastRecord;
    }
    get canAccessChildren() {
        const parentId = this.#actualRecord?.Id ?? this.#lastRecord?.Id;
        if (this.#Action === TSystem.Actions.QUERY)
            return parentId != null;
        if (!this.#isPersistAction() || this.#Action === TSystem.Actions.DELETE)
            return false;
        if (this.#Action === TSystem.Actions.CREATE)
            return this.#isStaged;
        return parentId != null && !this.#showsPersist();
    }
}
