"use strict";

import TConfig from "./TConfig.class.mjs";
import TransportCrypto from "./TransportCrypto.class.mjs";
import TBrowse from "./TBrowse.class.mjs";
import TCheckbox from "./TCheckbox.class.mjs";
import TDropdown from "./TDropdown.class.mjs";
import TScrollBar from "./TScrollBar.class.mjs";
import TForm from "./TForm.class.mjs";
import TLogin from "./TLogin.class.mjs";
import TMenu from "./TMenu.class.mjs";
import TDialog from "./TDialog.class.mjs";
import TScreen from "./TScreen.class.mjs";
import TType from "./TType.class.mjs";
import TDomain from "./TDomain.class.mjs";
import TDatabase from "./TDatabase.class.mjs";
import TTable from "./TTable.class.mjs";
import TColumn from "./TColumn.class.mjs";
import TIndex from "./TIndex.class.mjs";
import TIndexkey from "./TIndexkey.class.mjs";
import TCategory from "./TCategory.class.mjs";
import TMask from "./TMask.class.mjs";
import TCategoryHtml from "./TCategoryHtml.class.mjs";
import TComparator from "./TComparator.class.mjs";
import TReference from "./TReference.class.mjs";
import TSpinner from "./TSpinner.class.mjs";
export default class TSystem {
    static #Action = "";
    static #RowsPerPage = 0;
    static #RowsPerChildPage = 0;
    static #RowsPerDropdownPage = 5;
    static #PaddingGridLastPage = false;
    static #ReverseItemsWhenOpenUp = false;
    static #Types = [];
    static #Domains = [];
    static #Databases = [];
    static #Tables = [];
    static #Columns = [];
    static #Categories = [];
    static #Masks = [];
    static #Comparators = [];
    static #Rules = [];
    static #Expressions = [];
    static #Conditions = [];
    static #Properties = [];
    static #Behaviors = [];
    static #References = [];
    static #Actions = null;

    static Run(withBackgroundImage = true) {
        TConfig.GetAPI("config")
            .then(async config => {
                await TransportCrypto.Initialize(config.RsaPublicKey);
                document.addEventListener("wheel",
                    event => {
                        if (event.ctrlKey)
                            event.preventDefault();
                    },
                    { passive: false }
                );
                document.body.style = config.Styles.Body;
                TConfig.CreateProperties(config.Data.System[0], this);
                this.#RowsPerPage = config.RowsPerPage;
                this.#RowsPerChildPage = config.RowsPerChildPage;
                this.#RowsPerDropdownPage = config.RowsPerDropdownPage;
                document.documentElement.style.setProperty("--rows-per-page", String(this.#RowsPerPage));
                document.documentElement.style.setProperty("--rows-per-child-page", String(this.#RowsPerChildPage));
                document.documentElement.style.setProperty("--rows-per-dropdown-page", String(this.#RowsPerDropdownPage));
                this.#PaddingGridLastPage = config.PaddingGridLastPage;
                this.#ReverseItemsWhenOpenUp = config.ReverseItemsWhenOpenUp;
                TConfig.IdleTimeInMinutesLimit = config.IdleTimeInMinutesLimit;
                TLogin.Initialize(config.Styles);
                TDialog.Initialize(config.Styles, config.Images);
                TSpinner.Initialize(config.Styles);
                TScreen.Initialize(config.Styles, config.Images, withBackgroundImage);
                TMenu.Initialize(config.Styles, config.Data.Menus);
                TBrowse.Initialize(config.Styles, config.Images);
                TForm.Initialize(config.Styles, config.Images);
                TDropdown.Initialize(config.Styles);
                TCheckbox.Initialize(config.Styles);
                TScrollBar.Initialize(config.Styles);
                config.Data.Categories.forEach(row => this.#Categories.push(new TCategory(row)));
                config.Data.Types.forEach(row => this.#Types.push(new TType(row)));
                config.Data.Domains.forEach(row => this.#Domains.push(new TDomain(row)));
                config.Data.Masks.forEach(row => this.#Masks.push(new TMask(row)));
                (config.Data.Comparators ?? []).forEach(row => this.#Comparators.push(new TComparator(row)));
                this.#Rules = config.Data.Rules ?? [];
                this.#Expressions = config.Data.Expressions ?? [];
                this.#Conditions = config.Data.Conditions ?? [];
                this.#Properties = config.Data.Properties ?? [];
                this.#Behaviors = config.Data.Behaviors ?? [];
                const referenceKeyRows = config.Data.Referencekeys ?? [];
                (config.Data.References ?? []).forEach(row => {
                    const keys = referenceKeyRows
                        .filter(key => Number(key.ReferenceId) === Number(row.Id))
                        .sort((left, right) => Number(left.Sequence) - Number(right.Sequence));
                    this.#References.push(new TReference(row, keys));
                });
                config.Data.Databases.forEach(databaseRow => {
                    let database = new TDatabase(databaseRow);

                    config.Data.Tables.filter(tableRow => tableRow.DatabaseId === databaseRow.Id)
                        .forEach(tableRow => {
                            let table = new TTable(database, tableRow);

                            config.Data.Columns.filter(columnRow => columnRow.TableId === tableRow.Id)
                                .forEach(columnRow => {
                                    let column = new TColumn(table, columnRow);

                                    table.AddColumn(column);
                                    this.#Columns.push(column);
                                    const inWordsColumn = table.GetColumn(`${column.Name}InWords`);
                                    if (inWordsColumn?.IsVirtual)
                                        this.#Columns.push(inWordsColumn);
                                });
                            config.Data.Indexes.filter(indexRow => indexRow.TableId === tableRow.Id)
                                .forEach(indexRow => {
                                    let index = new TIndex(table, indexRow);

                                    config.Data.Indexkeys.filter(indexkey => indexkey.IndexId === indexRow.Id)
                                        .forEach(indexkey => index.AddIndexkey(new TIndexkey(index, indexkey)));
                                    table.AddIndex(index);
                                });
                            database.AddTable(table);
                            this.#Tables.push(table);
                        });
                    this.#Databases.push(database);
                });
                this.#resolveReferenceKeys();
                this.#patchLegacyReferenceFields();
                this.#Actions = config.Data.Actions;
                this.Action = this.#Actions.SCREEN;
            })
            .catch(error => {
                console.log(error);
                throw error;
            });
    }
    /**
     * @param {number} value
     */
    static GetType(id) {
        return this.#Types.find(type => type.Id === id);
    }
    /**
     * @param {number} value
     */
    static GetMask(id) {
        return this.#Masks.find(mask => mask.Id === id);
    }
    /**
     * @param {number} value
     */
    static GetDomain(id) {
        return this.#Domains.find(domain => domain.Id === id);
    }
    static GetTextDomain() {
        return this.#Domains.find(domain => {
            const category = domain.Type?.Category;
            return TCategoryHtml.isStringCategory(category);
        });
    }
    /**
     * @param {number} value
     */
    static GetCategory(id) {
        return this.#Categories.find(category => category.Id === id);
    }
    static GetComparator(id) {
        return this.#Comparators.find(comparator => comparator.Id === Number(id));
    }
    static GetRulesForCategory(categoryId) {
        return this.#Rules.filter(rule => Number(rule.CategoryId) === Number(categoryId));
    }
    static GetExpressionsForTable(tableId) {
        return this.#Expressions.filter(expression => Number(expression.TableId) === Number(tableId));
    }
    static GetConditionsForExpression(expressionId) {
        return this.#Conditions
            .filter(condition => Number(condition.ExpressionId) === Number(expressionId))
            .sort((left, right) => Number(left.Sequence) - Number(right.Sequence));
    }
    static GetBehaviorsForColumn(columnId) {
        return this.#Behaviors.filter(behavior => Number(behavior.ColumnId) === Number(columnId));
    }
    static GetProperty(id) {
        return this.#Properties.find(property => Number(property.Id) === Number(id));
    }
    static GetPropertyByName(name) {
        return this.#Properties.find(property =>
            String(property.Name).toLowerCase() === String(name).toLowerCase());
    }
    static GetMaskByName(name) {
        return this.#Masks.find(mask => mask.Name === name);
    }
    static get Comparators() {
        return this.#Comparators;
    }
    static get Rules() {
        return this.#Rules;
    }
    /**
     * @param {string | number} value
     */
    static GetDatabase(nameOrAliasOrId) {
        let result;

        if (typeof nameOrAliasOrId === "number")
            result = this.#Databases.find(database => database.Id === nameOrAliasOrId);
        else
            result = this.#Databases.find(database => database.Alias === nameOrAliasOrId || database.Name === nameOrAliasOrId);

        return result;
    }
    /**
     * @param {string | number} value
     */
    static GetTable(tableNameOrAliasOrId) {
        let result;

        if (typeof tableNameOrAliasOrId === "number")
            result = this.#Tables.find(table => table.Id === tableNameOrAliasOrId);
        else
            result = this.#Tables.find(table => table.Name === tableNameOrAliasOrId || table.Alias === tableNameOrAliasOrId);

        return result;
    }
    static GetChildTables(table) {
        if (!table?.Id)
            return [];
        const childIds = new Set(
            this.#References
                .filter(reference => reference.IsParentChild && Number(reference.PkTableId) === Number(table.Id))
                .map(reference => reference.FkTableId),
        );
        return this.#Tables.filter(child => childIds.has(child.Id));
    }
    static GetReference(id) {
        return this.#References.find(reference => Number(reference.Id) === Number(id));
    }
    static GetReferencesForTable(tableId) {
        return this.#References.filter(reference => Number(reference.FkTableId) === Number(tableId));
    }
    static GetReferenceByFkColumn(columnId) {
        return this.#References.find(reference =>
            reference.KeyPairs.some(pair => Number(pair.fkColumnId) === Number(columnId))
            || reference.Keys.some(key => Number(key.FkColumnId) === Number(columnId)),
        ) ?? null;
    }
    static GetReferenceKeyPair(column) {
        const reference = this.GetReferenceByFkColumn(column?.Id);
        return reference?.getKeyPairForFkColumn(column?.Id) ?? null;
    }
    static GetPrimaryKeyColumns(table) {
        if (!table?.Columns)
            return [];
        return table.Columns
            .filter(column => column.IsPrimarykey && !column.IsVirtual)
            .sort((left, right) => {
                const leftSeq = left.PkSequence ?? left.Sequence ?? 0;
                const rightSeq = right.PkSequence ?? right.Sequence ?? 0;
                return Number(leftSeq) - Number(rightSeq);
            });
    }
    static GetPrimaryKeyValues(record, table) {
        const values = {};
        for (const column of this.GetPrimaryKeyColumns(table)) {
            if (!Object.hasOwn(record, column.Name))
                return null;
            values[column.Name] = record[column.Name];
        }
        return values;
    }
    static GetPrimaryKeyScalar(record, table) {
        const columns = this.GetPrimaryKeyColumns(table);
        if (columns.length === 0)
            return record?.Id ?? null;
        if (columns.length === 1)
            return record[columns[0].Name];
        const values = this.GetPrimaryKeyValues(record, table);
        return values ? JSON.stringify(values) : null;
    }
    static GetReferenceBetween(childTable, parentTable, contextTable = null) {
        if (!childTable || !parentTable)
            return null;
        let reference = this.#References.find(item =>
            Number(item.FkTableId) === Number(childTable.Id)
            && Number(item.PkTableId) === Number(parentTable.Id),
        );
        if (!reference && contextTable) {
            reference = this.#References.find(item =>
                Number(item.FkTableId) === Number(childTable.Id)
                && Number(item.PkTableId) === Number(contextTable.Id),
            );
        }
        return reference ?? null;
    }
    static IsFkColumn(column) {
        return this.GetReferenceByFkColumn(column?.Id) != null;
    }
    static GetParentTableId(table) {
        if (!table?.Id)
            return null;
        const reference = this.#References.find(item =>
            item.IsParentChild && Number(item.FkTableId) === Number(table.Id),
        );
        return reference?.PkTableId ?? null;
    }
    static GetReferencePkTableId(column) {
        return this.GetReferenceByFkColumn(column?.Id)?.PkTableId ?? null;
    }
    static GetReferencePkTable(column) {
        const tableId = this.GetReferencePkTableId(column);
        return tableId ? this.GetTable(tableId) : null;
    }
    static GetParentLinkColumn(childTable, parentTable, contextTable = null) {
        const reference = this.GetReferenceBetween(childTable, parentTable, contextTable);
        return reference?.KeyPairs[0]?.fkColumn ?? null;
    }
    static #resolveReferenceKeys() {
        for (const reference of this.#References) {
            const fkTable = this.GetTable(reference.FkTableId);
            const pkTable = this.GetTable(reference.PkTableId);
            reference.resolve(
                fkTable,
                pkTable,
                this.GetPrimaryKeyColumns(pkTable),
                columnId => this.GetColumn(columnId),
            );
        }
    }
    static #patchLegacyReferenceFields() {
        for (const column of this.#Columns) {
            const reference = this.GetReferenceByFkColumn(column.Id);
            if (!reference)
                continue;
            Object.defineProperty(column, "ReferenceTableId", {
                get: () => reference.PkTableId,
                configurable: true,
            });
        }
        for (const table of this.#Tables) {
            const parentTableId = this.GetParentTableId(table);
            if (!parentTableId)
                continue;
            Object.defineProperty(table, "ParentTableId", {
                get: () => parentTableId,
                configurable: true,
            });
        }
    }
    static IsSimpleTable(table) {
        return this.GetChildTables(table).length === 0;
    }
    /**
     * @param {number} value
     */
    static GetColumn(id) {
        return this.#Columns.find(column => Number(column.Id) === Number(id));
    }
    /**
     * @param {number} value
     */
    static set Action(value) {
        let lastValue = this.#Action;
        let newValue = value.split("/");

        this.#Action = value;
        switch (newValue[0]) {
            case this.#Actions.SCREEN:
                TScreen.Renderize();
                this.Action = this.#Actions.LOGIN;
                break;
            case this.#Actions.LOGIN:
                window.onbeforeunload = null;
                TConfig.SetIdleTime(false);
                if (lastValue !== this.#Actions.SCREEN)
                    TLogin.Logout();
                TLogin.Renderize();
                break;
            case this.#Actions.MENU:
                window.onbeforeunload = () => TLogin.Logout();
                TConfig.SetIdleTime();
                TMenu.Renderize();
                break;
            case this.#Actions.BROWSE:
                new TBrowse(newValue[1], newValue[2]).Renderize();
                break;
            case TSystem.Actions.RELOAD:
                document.location.reload(true);
                break;
            case this.#Actions.EXIT:
                TScreen.ShowQuestion(`Confirma retornar ao ${newValue[1]}?`, newValue[1], TSystem.Actions.NONE);
                break;
            case this.#Actions.NONE:
                this.#Action = lastValue;
                break;
            default:
                throw new Error(`Ação '${value}' desconhecida.`);
        }
    }
    static get Action() {
        return this.#Action;
    }
    static get RowsPerPage() {
        return this.#RowsPerPage;
    }
    static get RowsPerChildPage() {
        return this.#RowsPerChildPage;
    }
    static get RowsPerDropdownPage() {
        return this.#RowsPerDropdownPage;
    }
    static get PaddingGridLastPage() {
        return this.#PaddingGridLastPage;
    }
    static get ReverseItemsWhenOpenUp() {
        return this.#ReverseItemsWhenOpenUp;
    }
    static get Types() {
        return this.#Types;
    }
    static get Masks() {
        return this.#Masks;
    }
    static get Databases() {
        return this.#Databases;
    }
    static get Actions() {
        return this.#Actions;
    }
}