"use strict";

import TConfig from "./TConfig.class.mjs";
import TransportCrypto from "./TransportCrypto.class.mjs";
import TGrid from "./TGrid.class.mjs";
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
import TComparator from "./TComparator.class.mjs";
import TSpinner from "./TSpinner.class.mjs";
export default class TSystem {
    static #Action = "";
    static #RowsPerPage = 0;
    static #RowsPerChildPage = 0;
    static #PaddingGridLastPage = false;
    static #Types = [];
    static #Domains = [];
    static #Databases = [];
    static #Tables = [];
    static #Columns = [];
    static #Categories = [];
    static #Masks = [];
    static #Comparators = [];
    static #Rules = [];
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
                document.documentElement.style.setProperty("--rows-per-page", String(this.#RowsPerPage));
                document.documentElement.style.setProperty("--rows-per-child-page", String(this.#RowsPerChildPage));
                this.#PaddingGridLastPage = config.PaddingGridLastPage;
                TConfig.IdleTimeInMinutesLimit = config.IdleTimeInMinutesLimit;
                TLogin.Initialize(config.Styles);
                TDialog.Initialize(config.Styles, config.Images);
                TSpinner.Initialize(config.Styles);
                TScreen.Initialize(config.Styles, config.Images, withBackgroundImage);
                TMenu.Initialize(config.Styles, config.Data.Menus);
                TGrid.Initialize(config.Styles, config.Images);
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
            return category?.HtmlInputType === "text" || category?.Name === "string";
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
        return this.#Tables.filter(child => child.ParentTableId == table.Id);
    }
    static IsSimpleTable(table) {
        return this.GetChildTables(table).length === 0;
    }
    static GetParentLinkColumn(childTable, parentTable, contextTable = null) {
        if (!childTable || !parentTable)
            return null;
        let link = childTable.Columns.find(column => column.ReferenceTableId == parentTable.Id);
        if (link)
            return link;
        if (contextTable)
            link = childTable.Columns.find(column => column.ReferenceTableId == contextTable.Id);
        return link ?? null;
    }
    /**
     * @param {number} value
     */
    static GetColumn(id) {
        return this.#Columns.find(column => column.id === id);
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
            case this.#Actions.GRID:
                new TGrid(newValue[1], newValue[2]).Renderize();
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
    static get PaddingGridLastPage() {
        return this.#PaddingGridLastPage;
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