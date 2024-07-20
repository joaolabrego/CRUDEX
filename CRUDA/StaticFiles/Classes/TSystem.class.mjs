"use strict"

import TConfig from "./TConfig.class.mjs"
import TBrowse from "./TBrowse.class.mjs"
import TForm from "./TForm.class.mjs"
import TLogin from "./TLogin.class.mjs"
import TMenu from "./TMenu.class.mjs"
import TDialog from "./TDialog.class.mjs"
import TScreen from "./TScreen.class.mjs"
import TType from "./TType.class.mjs"
import TDomain from "./TDomain.class.mjs"
import TDatabase from "./TDatabase.class.mjs"
import TTable from "./TTable.class.mjs"
import TColumn from "./TColumn.class.mjs"
import TIndex from "./TIndex.class.mjs"
import TIndexkey from "./TIndexkey.class.mjs"
import TActions from "./TActions.class.mjs"
import TCategory from "./TCategory.mjs"
import TMask from "./TMask.mjs"
export default class TSystem {
    static #Name = ""
    static #Description = ""
    static #ClientName = ""

    static #Action = ""
    static #RowsPerPage = 0
    static #PaddingBrowseLastPage = false
    static #Types = []
    static #Domains = []
    static #Databases = []
    static #Tables = []
    static #Columns = []
    static #Categories = []
    static #Masks = []

    static Run(withBackgroundImage = true) {
        TConfig.GetAPI(TActions.CONFIG)
            .then(config => {
                //debugger
                Object.defineProperty(Object.prototype, "ClassName", {
                    get: function ClassName() {
                        return this.constructor.name
                    }
                });
                document.body.style = config.Styles.Body
                this.#Name = config.Data.System[0].Name
                this.#Description = config.Data.System[0].Description
                this.#ClientName = config.Data.System[0].ClientName
                this.#RowsPerPage = config.RowsPerPage
                this.#PaddingBrowseLastPage = config.PaddingBrowseLastPage
                TConfig.IdleTimeInMinutesLimit = config.IdleTimeInMinutesLimit
                TLogin.Initialize(config.Styles)
                TDialog.Initialize(config.Styles, config.Images)
                TScreen.Initialize(config.Styles, config.Images, withBackgroundImage)
                TMenu.Initialize(config.Styles, config.Data.Menus)
                TBrowse.Initialize(config.Styles, config.Images)
                TForm.Initialize(config.Styles, config.Images)
                config.Data.Categories.forEach(row => this.#Categories.push(new TCategory(row)))
                config.Data.Types.forEach(row => this.#Types.push(new TType(row)))
                config.Data.Domains.forEach(row => this.#Domains.push(new TDomain(row)))
                config.Data.Masks.forEach(row => this.#Masks.push(new TMask(row)))
                config.Data.Databases.forEach(databaseRow => {
                    let database = new TDatabase(databaseRow)

                    config.Data.Tables.filter(tableRow => tableRow.DatabaseId === databaseRow.Id)
                        .forEach(tableRow => {
                            let table = new TTable(database, tableRow)

                            config.Data.Columns.filter(columnRow => columnRow.TableId === tableRow.Id)
                                .forEach(columnRow => {
                                    let column = new TColumn(table, columnRow)

                                    table.AddColumn(column)
                                    this.#Columns.push(column)
                                })
                            config.Data.Indexes.filter(indexRow => indexRow.TableId === tableRow.Id)
                                .forEach(indexRow => {
                                    let index = new TIndex(table, indexRow)

                                    config.Data.Indexkeys.filter(indexkey => indexkey.IndexId = indexRow.Id)
                                        .forEach(indexkey => index.AddIndexkey(new TIndexkey(index, indexkey)))
                                    table.AddIndex(index)
                                })
                            database.AddTable(table)
                            this.#Tables.push(table)
                        })
                    this.#Databases.push(database)
                })
                this.Action = TActions.SCREEN
            })
            .catch(error => {
                console.log(error)
                throw error
            })
    }
    /**
     * @param {number} value
     */
    static GetType(id) {
        return this.#Types.find(type => type.Id === id)
    }
    /**
     * @param {number} value
     */
    static GetMask(id) {
        return this.#Masks.find(mask => mask.Id === id)
    }
    /**
     * @param {number} value
     */
    static GetDomain(id) {
        return this.#Domains.find(domain => domain.Id === id)
    }
    /**
     * @param {number} value
     */
    static GetCategory(id) {
        return this.#Categories.find(category => category.Id === id)
    }
    /**
     * @param {string | number} value
     */
    static GetDatabase(nameOrAliasOrId) {
        let result

        if (typeof nameOrAliasOrId === "number")
            result = this.#Databases.find(database => database.Id === nameOrAliasOrId)
        else
            result = this.#Databases.find(database => database.Alias === nameOrAliasOrId || database.Name === nameOrAliasOrId)

        return result
    }
    /**
     * @param {string | number} value
     */
    static GetTable(aliasOrId) {
        let result

        if (typeof aliasOrId === "number")
            result = this.#Tables.find(table => table.Id === aliasOrId)
        else
            result = this.#Tables.find(table => table.Alias === aliasOrId)

        return result
    }
    /**
     * @param {number} value
     */
    static GetColumn(id) {
        return this.#Columns.find(column => column.id === id)
    }
    /**
     * @param {number} value
     */
    static set Action(value) {
        let lastValue = this.#Action
        let newValue = value.split("/")

        this.#Action = value
        switch (newValue[0]) {
            case TActions.SCREEN:
                TScreen.Renderize()
                this.Action = TActions.LOGIN
                break
            case TActions.LOGIN:
                window.onbeforeunload = null
                TConfig.SetIdleTime(false)
                if (lastValue !== TActions.SCREEN)
                    TLogin.Logout()
                TLogin.Renderize()
                break
            case TActions.MENU:
                window.onbeforeunload = () => TLogin.Logout()
                TConfig.SetIdleTime()
                TMenu.Renderize()
                break
            case TActions.BROWSE:
                new TBrowse(this.GetDatabase(newValue[1]).GetTable(newValue[2])).Renderize()
                break
            case TActions.RELOAD:
                document.location.reload(true)
                break
            case TActions.EXIT:
                TScreen.ShowQuestion(`Confirma retornar ao ${newValue[1]}?`, newValue[1], lastValue)
                break
            case TActions.NONE:
                this.#Action = lastValue
                break
            default:
                throw new Error(`Ação '${value}' desconhecida.`)
        }
    }
    static get Action() {
        return this.#Action
    }
    static get Name() {
        return this.#Name
    }
    static get Description() {
        return this.#Description
    }
    static get ClientName() {
        return this.#ClientName
    }
    static get RowsPerPage() {
        return this.#RowsPerPage
    }
    static get PaddingBrowseLastPage() {
        return this.#PaddingBrowseLastPage
    }
    static get Types() {
        return this.#Types
    }
    static get Masks() {
        return this.#Masks
    }
    static get Databases() {
        return this.#Databases
    }
}