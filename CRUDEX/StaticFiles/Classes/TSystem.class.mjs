"use strict";

import TConfig from "./TConfig.class.mjs";
import TGrid from "./TGrid.class.mjs";
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
import TActions from "./TActions.class.mjs";
import TCategory from "./TCategory.class.mjs";
import TMask from "./TMask.class.mjs";
import TSpinner from "./TSpinner.class.mjs";
export default class TSystem {
    static #Action = "";
    static #RowsPerPage = 0;
    static #PaddingGridLastPage = false;
    static #Types = [];
    static #Domains = [];
    static #Databases = [];
    static #Tables = [];
    static #Columns = [];
    static #Categories = [];
    static #Masks = [];
    static #Associations = [];
    static #Uniques = [];

    static Run(withBackgroundImage = true) {
        TConfig.GetAPI(TActions.CONFIG)
            .then(config => {
                Object.defineProperty(Object.prototype, "ClassName", {
                    get: function ClassName() {
                        return this.constructor.name;
                    }
                });
                document.addEventListener("wheel", event => {
                    if (event.ctrlKey)
                        event.preventDefault();
                },
                    { passive: false }
                );
                document.body.style = config.Styles.Body;
                TConfig.CreateProperties(config.Data.System[0], this);
                this.#RowsPerPage = config.RowsPerPage;
                this.#PaddingGridLastPage = config.PaddingGridLastPage;
                TConfig.IdleTimeInMinutesLimit = config.IdleTimeInMinutesLimit;
                TLogin.Initialize(config.Styles);
                TDialog.Initialize(config.Styles, config.Images);
                TSpinner.Initialize(config.Styles);
                TScreen.Initialize(config.Styles, config.Images, withBackgroundImage);
                TMenu.Initialize(config.Styles, config.Data.Menus);
                TGrid.Initialize(config.Styles, config.Images);
                TForm.Initialize(config.Styles, config.Images);
                config.Data.Categories.forEach(row => this.#Categories.push(new TCategory(row)));
                config.Data.Types.forEach(row => this.#Types.push(new TType(row)));
                config.Data.Domains.forEach(row => this.#Domains.push(new TDomain(row)));
                config.Data.Masks.forEach(row => this.#Masks.push(new TMask(row)));
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
                                });
                            config.Data.Indexes.filter(indexRow => indexRow.TableId === tableRow.Id)
                                .forEach(indexRow => {
                                    let index = new TIndex(table, indexRow);

                                    config.Data.Indexkeys.filter(indexkey => indexkey.IndexId = indexRow.Id)
                                        .forEach(indexkey => index.AddIndexkey(new TIndexkey(index, indexkey)));
                                    table.AddIndex(index);
                                });
                            database.AddTable(table);
                            this.#Tables.push(table);
                        });
                    this.#Databases.push(database);
                });
                this.Action = TActions.SCREEN;
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
    /**
     * @param {number} value
     */
    static GetCategory(id) {
        return this.#Categories.find(category => category.Id === id);
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
            case TActions.SCREEN:
                TScreen.Renderize();
                this.Action = TActions.LOGIN;
                break;
            case TActions.LOGIN:
                window.onbeforeunload = null;
                TConfig.SetIdleTime(false);
                if (lastValue !== TActions.SCREEN)
                    TLogin.Logout();
                TLogin.Renderize();
                break;
            case TActions.MENU:
                window.onbeforeunload = () => TLogin.Logout();
                TConfig.SetIdleTime();
                TMenu.Renderize();
                break;
            case TActions.GRID:
                new TGrid(newValue[1], newValue[2]).Renderize();
                break;
            case TActions.EXIT:
                TScreen.ShowQuestion(`Confirma retornar ao ${newValue[1]}?`, newValue[1], TActions.NONE);
                break;
            case TActions.NONE:
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
}