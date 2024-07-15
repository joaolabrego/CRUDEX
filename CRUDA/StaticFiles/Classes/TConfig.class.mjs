"use strict"

import TActions from "./TActions.class.mjs"
import TLogin from "./TLogin.class.mjs"
import TScreen from "./TScreen.class.mjs"
import TSystem from "./TSystem.class.mjs"

export default class TConfig {
    static #Locale = string.Empty
    static #DecimalSeparator = string.Empty
    static #ThousandSeparator = string.Empty
    static #MinusSignal = string.Empty
    static #IdleTimeInMinutesLimit = 0
    static #Timer = null

    static async GetAPI(action, parameters = {}) {
        let headers = {
                "Accept": "application/json",
                "Content-Type": "application/json",
            }
        if (action !== TActions.CONFIG) {
            headers.Login = JSON.stringify({
                LoginId: TLogin.LoginId,
                UserName: TLogin.UserName,
                Password: TLogin.Password,
                Action: `${TActions.LOGIN};${TActions.LOGOUT}`.search(action) === -1 ? TActions.AUTHENTICATE : action,
                LastAction: TSystem.Action,
            })
        }
        const response = await fetch(`${location}/${action}`, {
            method: "POST",
            headers,
            body: JSON.stringify(parameters),
        })
        let result = await response.json()

        if (result.ClassName === "Error")
            throw result

        return result
    }
    static SetIdleTime(activate = true) {
        const resetTimer = () => {
            clearTimeout(this.#Timer)
            this.#Timer = setTimeout(() => {
                clearTimeout(this.#Timer)
                TScreen.ShowAlert(`Sistema ocioso por mais de ${this.#IdleTimeInMinutesLimit} minuto(s).`, TActions.RELOAD, 10000)
            }, this.#IdleTimeInMinutesLimit * 60000)
        }
        if (activate)
            resetTimer()
        else
            clearTimeout(this.#Timer)
        window.onload = window.onmousemove = window.onmousedown = window.ontouchstart = window.onclick =
            window.onbeforeinput = activate ? resetTimer : null
    }
    static get Locale() {
        if (this.#Locale)
            return this.#Locale

        return this.#Locale = navigator.languages && navigator.languages.length ? navigator.languages[0] : navigator.language
    }
    static get DecimalSeparator() {
        if (this.#DecimalSeparator)
            return this.#DecimalSeparator

        return this.#DecimalSeparator = (0.1).toLocaleString(this.Locale).replace(/\d/g, string.Empty)
    }
    static get ThousandSeparator() {
        if (this.#ThousandSeparator)
            return this.#ThousandSeparator

        return this.#ThousandSeparator = (1000).toLocaleString(this.Locale).replace(/\d/g, string.Empty)
    }
    static get MinusSignal() {
        if (this.#MinusSignal)
            return this.#MinusSignal

        return this.#MinusSignal = (-1).toLocaleString(this.Locale).replace(/\d/g, string.Empty)
    }
    static GetScripts(databaseAlias = "cruda", withDDL = true) {
        let script = string.Empty

        this.GetAPI(TActions.CONFIG)
            .then(config => {
                if (withDDL) {
                    config.Data.Databases
                        .filter(database => database.Alias === databaseAlias)
                        .forEach(database => {
                            let tables = config.Data.Tables.filter(datatable => datatable.DatabaseId === database.Id)

                            script += this.#GetDatabaseScript(database)
                            tables.forEach(table => {
                                let columns = config.Data.Columns.filter(column => column.TableId === table.Id)

                                script += this.#GetTableScript(database, table, columns, config.Data.Domains, config.Data.Types)
                            })
                        })
                }
                config.Data.Databases
                    .forEach(database => {
                        let tables = config.Data.Tables.filter(table => table.DatabaseId === database.Id)

                        tables.forEach(table => {
                            let columns = config.Data.Columns.filter(column => column.TableId === table.Id)

                            script += this.#GetCreateScript(database, table, columns, config.Data.Domains, config.Data.Types)
                            script += this.#GetReadScript(database, table, columns, config.Data.Domains, config.Data.Types)
                            script += this.#GetUpdateScript(database, table, columns, config.Data.Domains, config.Data.Types)
                            script += this.#GetDeleteScript(database, table, columns, config.Data.Domains, config.Data.Types)
                            script += this.#GetListScript(database, table, columns)
                        })
                    })
                //console.log(script)
            })
            .catch(error => {
                console.log(error)
            })
    }

    static #GetDatabaseScript(database) {
        let sql = string.Empty

        sql = sql + `USE[master]\n`
        sql = sql + `GO\n`
        sql = sql + `CREATE DATABASE[${database.Alias}]\n`
        sql = sql + `CONTAINMENT = NONE\n`
        sql = sql + `ON  PRIMARY\n`
        sql = sql + `(NAME = N'cruda', FILENAME = N'${database.Folder}${database.Name}.mdf', SIZE = 8192KB, MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB)\n`
        sql = sql + `LOG ON\n`
        sql = sql + `(NAME = N'cruda_log', FILENAME = N'${database.Folder}${database.Name}_log.ldf', SIZE = 8192KB, MAXSIZE = 2048GB, FILEGROWTH = 65536KB)\n`
        sql = sql + `WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET COMPATIBILITY_LEVEL = 160\n`
        sql = sql + `GO\n`
        sql = sql + `IF(1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))\n`
        sql = sql + `BEGIN\n`
        sql = sql + `EXEC[${database.Alias}].[dbo].[sp_fulltext_database] @action = 'enable'\n`
        sql = sql + `END\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET ANSI_NULL_DEFAULT OFF\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET ANSI_NULLS OFF\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET ANSI_PADDING OFF\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET ANSI_WARNINGS OFF\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET ARITHABORT OFF\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET AUTO_CLOSE OFF\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET AUTO_SHRINK OFF\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET AUTO_UPDATE_STATISTICS ON\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET CURSOR_CLOSE_ON_COMMIT OFF\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET CURSOR_DEFAULT  GLOBAL\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET CONCAT_NULL_YIELDS_NULL OFF\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET NUMERIC_ROUNDABORT OFF\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET QUOTED_IDENTIFIER OFF\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET RECURSIVE_TRIGGERS OFF\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET  DISABLE_BROKER\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET AUTO_UPDATE_STATISTICS_ASYNC OFF\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET DATE_CORRELATION_OPTIMIZATION OFF\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET TRUSTWORTHY OFF\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET ALLOW_SNAPSHOT_ISOLATION OFF\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET PARAMETERIZATION SIMPLE\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET READ_COMMITTED_SNAPSHOT OFF\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET HONOR_BROKER_PRIORITY OFF\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET RECOVERY SIMPLE\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET  MULTI_USER\n` 
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET PAGE_VERIFY CHECKSUM\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET DB_CHAINING OFF\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET FILESTREAM(NON_TRANSACTED_ACCESS = OFF)\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET TARGET_RECOVERY_TIME = 60 SECONDS\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET DELAYED_DURABILITY = DISABLED\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET ACCELERATED_DATABASE_RECOVERY = OFF\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET QUERY_STORE = ON\n`
        sql = sql + `GO\n`
        sql = sql + `ALTER DATABASE[${database.Alias}] SET QUERY_STORE(OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)\n`
        sql = sql + `GO\n`

        return sql
    }
    static #GetTableScript(database, table, columns, domains, types) {
        let sql = string.Empty

        if (columns.length && table.ProcedureCreate) {
            let primarykeys = columns.filter(column => column.IsPrimarykey)

            sql += `USE [${database.Alias}]\n`
            sql += `GO\n`
            sql += `SET ANSI_NULLS ON\n`
            sql += `GO\n`
            sql += `SET QUOTED_IDENTIFIER ON\n`
            sql += `GO\n`
            sql += `IF(SELECT object_id('${table.Name}')) IS NULL\n`
            sql += `CREATE TABLE [dbo].[${table.Name}](\n`
            columns.forEach(column => {
                let domain = domains.find(domain => domain.Id === column.DomainId),
                    type = types.find(type => type.Id === domain.TypeId)

                sql += `[${column.Name}] [${type.Name}]`
                if (column.Length) {
                    sql += `(${column.Length}`
                    if (column.Decimals)
                        sql += `, ${column.Length}`
                    sql += `)`
                }
                if (column.IsAutoincrement)
                    sql += ` IDENTITY(1,1)`
                if (column.IsUnique)
                    sql += ` UNIQUE`
                if (column.IsRequired)
                    sql += ` NOT NULL`
                sql += ",\n"
            })
            if (primarykeys.length) {
                let comma = string.Empty

                sql += `CONSTRAINT [PK_${table.Name}] PRIMARY KEY CLUSTERED (\n`
                primarykeys.forEach(column => {
                    sql += `${comma}[${column.Name}] ASC\n`
                    comma = ","
                })
                sql += `)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]\n`
                sql += `) ON [PRIMARY]\n`
            }
            sql += `GO\n`
        }

        return sql
    }
    static #GetCreateScript(database, table, columns, domains, types) {
        let sql = string.Empty

        if (columns.length && table.ProcedureCreate) {
            let values = "VALUES (",
                listColumns = "("

            sql += `USE [${database.Alias}]\n`
            sql += `GO\n`
            sql += `SET ANSI_NULLS ON\n`
            sql += `GO\n`
            sql += `SET QUOTED_IDENTIFIER ON\n`
            sql += `GO\n`
            sql += `IF(SELECT object_id('${table.ProcedureCreate}')) IS NULL\n`
            sql += `EXEC('CREATE PROCEDURE [dbo].[${table.ProcedureCreate}] AS PRINT 1')\n`
            sql += `GO\n`
            sql += `ALTER PROCEDURE [dbo].[${table.ProcedureCreate}](\n`

            let comma = string.Empty

            columns.forEach(column => {
                if (!column.IsAutoincrement) {
                    let domain = domains.find(domain => domain.Id === column.DomainId)
                    let type = types.find(type => type.Id === domain.TypeId)
    
                    sql += `${comma}@${column.Name} ${type.Name}`
                    if (column.Length) {
                        sql += `(${column.Length}`
                        if (column.Decimals)
                            sql += `, ${column.Length}`
                        sql += `)`
                    }
                    sql += ` = NULL\n`
                    values += `${comma}@${column.Name}\n`
                    listColumns += `${comma}[${column.Name}]\n`
                    comma = ","
                }
            })
            values += `)\n`
            listColumns += `)\n`
            sql += `) AS\n`
            sql += `BEGIN\n`
            sql += `SET NOCOUNT ON\n`
            sql += `SET TRANSACTION ISOLATION LEVEL READ COMMITTED\n`
            sql += `INSERT INTO [dbo].[${table.Name}] \n ${listColumns} ${values}`
            sql += `RETURN @@IDENTITY\n`
            sql += `END\n`
            sql += `GO\n`
        }

        return sql
    }
    static #GetReadScript(database, table, columns, domains, types) {
        let sql = string.Empty

        if (columns.length && table.ProcedureRead) {
            let where = string.Empty,
                listColumns = `'${table.Name}' AS [ClassName]`

            sql += `USE [${database.Alias}]\n`
            sql += `GO\n`
            sql += `SET ANSI_NULLS ON\n`
            sql += `GO\n`
            sql += `SET QUOTED_IDENTIFIER ON\n`
            sql += `GO\n`
            sql += `IF(SELECT object_id('${table.ProcedureRead}')) IS NULL\n`
            sql += `    EXEC('CREATE PROCEDURE [dbo].[${table.ProcedureRead}] AS PRINT 1')\n`
            sql += `GO\n`
            sql += `ALTER PROCEDURE [dbo].[${table.ProcedureRead}](\n`
            sql += `@PageNumber INT OUT\n`
            sql += `,@LimitRows INT OUT\n`
            sql += `,@MaxPage INT OUT\n`
            sql += `,@PaddingGridLastPage BIT OUT\n`

            let and = string.Empty

            columns.forEach(column => {
                if (column.IsFilterable) {
                    let domain = domains.find(domain => domain.Id === column.DomainId),
                        type = types.find(type => type.Id === domain.TypeId)
    
                    sql += `,@${column.Name} ${type.Name}`
                    if (column.Length) {
                        sql += `(${column.Length}`
                        if (column.Decimals)
                            sql += `, ${column.Length}`
                        sql += `)`
                    }
                    sql += ` = NULL\n`
                    where += `${and}(@${column.Name} IS NULL OR [${column.Name}] = @${column.Name})\n`
                    and = "AND "
                }
                listColumns += `\n,[${column.Name}] AS [${table.Alias}_${column.Name}]`
            })
            sql += `) AS\n`
            sql += `BEGIN\n`
            sql += `    SET NOCOUNT ON\n`
            sql += `    SET TRANSACTION ISOLATION LEVEL READ COMMITTED\n`
            sql += `    SELECT ${listColumns}\n`
            sql += `        INTO [dbo].[#tmp]\n`
            sql += `        FROM [dbo].[${table.Name}]\n`
            sql += `        WHERE ${where}\n`
            sql += `    DECLARE @offset INT,\n`
            sql += `            @ROWCOUNT INT = @@ROWCOUNT\n`
            sql += `    IF @ROWCOUNT = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN\n`
            sql += `        SET @offset = 0\n`
            sql += `        SET @LimitRows = CASE WHEN @ROWCOUNT = 0 THEN 1 ELSE @ROWCOUNT END\n`
            sql += `        SET @PageNumber = 1\n`
            sql += `        SET @MaxPage = 1\n`
            sql += `    END ELSE BEGIN\n`
            sql += `        SET @MaxPage = @ROWCOUNT / @LimitRows + CASE WHEN @ROWCOUNT % @LimitRows = 0 THEN 0 ELSE 1 END\n`
            sql += `        IF ABS(@PageNumber) > @MaxPage\n`
            sql += `            SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END\n`
            sql += `            IF @PageNumber < 0\n`
            sql += `                SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1\n`
            sql += `            SET @offset = (@PageNumber - 1) * @LimitRows\n`
            sql += `            IF @PaddingGridLastPage = 1 AND @offset + @LimitRows > @ROWCOUNT\n`
            sql += `                SET @offset = CASE WHEN @ROWCOUNT > @LimitRows THEN @ROWCOUNT - @LimitRows ELSE 0 END\n`
            sql += `    END\n`
            sql += `    SELECT *\n`
            sql += `        FROM [dbo].[#tmp]\n`
            sql += `        ORDER BY 1\n`
            sql += `        OFFSET @offset ROWS\n`
            sql += `        FETCH NEXT @LimitRows ROWS ONLY\n`
            sql += `    RETURN @ROWCOUNT\n`
            sql += `END\n`
            sql += `GO\n`
        }

        return sql
    }
    static #GetListScript(database, table, columns) {
        let sql = string.Empty
        let referencedColumns = columns.filter(column => column.IsReferenced)

        if (columns.length && table.ProcedureList && referencedColumns.length) {
            let listColumns = `'LIST_${table.Name}' AS [ClassName]`,
                orders = string.Empty

            sql += `USE [${database.Alias}]\n`
            sql += `GO\n`
            sql += `SET ANSI_NULLS ON\n`
            sql += `GO\n`
            sql += `SET QUOTED_IDENTIFIER ON\n`
            sql += `GO\n`
            sql += `IF(SELECT object_id('${table.ProcedureList}')) IS NULL\n`
            sql += `    EXEC('CREATE PROCEDURE [dbo].[${table.ProcedureList}] AS PRINT 1')\n`
            sql += `GO\n`
            sql += `ALTER PROCEDURE [dbo].[${table.ProcedureList}]\n`

            let ordersComma = string.Empty

            columns.filter(column => column.IsPrimarykey)
                .forEach(column => listColumns += `\n,[${column.Name}] AS [${table.Alias}_${column.Name}]\n`)
            referencedColumns.forEach(column => {
                listColumns += `,[${column.Name}] AS [${table.Alias}_${column.Name}]\n`
                orders += `${ordersComma}[${column.Name}]\n`
                ordersComma = ","
            })
            sql += `AS\n`
            sql += `BEGIN\n`
            sql += `    SELECT ${listColumns}\n`
            sql += `        FROM [dbo].[${table.Name}]\n`
            sql += `        ORDER BY ${orders}\n`
            sql += `    RETURN @@ROWCOUNT\n`
            sql += `END\n`
            sql += `GO\n`
        }

        return sql
    }
    static #GetUpdateScript(database, table, columns, domains, types) {
        let sql = string.Empty

        if (columns.length && table.ProcedureUpdate) {
            let assignments = "SET ",
                where = "WHERE "

            sql += `USE [${database.Alias}]\n`
            sql += `GO\n`
            sql += `SET ANSI_NULLS ON\n`
            sql += `GO\n`
            sql += `SET QUOTED_IDENTIFIER ON\n`
            sql += `GO\n`
            sql += `IF(SELECT object_id('${table.ProcedureUpdate}')) IS NULL\n`
            sql += `EXEC('CREATE PROCEDURE [dbo].[${table.ProcedureUpdate}] AS PRINT 1')\n`
            sql += `GO\n`
            sql += `ALTER PROCEDURE[dbo].[${table.ProcedureUpdate}](\n`

            let parametersComma = string.Empty,
                assignmentsComma = string.Empty,
                and = string.Empty

            columns.forEach(column => {
                let domain = domains.find(domain => domain.Id === column.DomainId),
                    type = types.find(type => type.Id === domain.TypeId)

                sql += `${parametersComma}@${column.Name} ${type.Name}`
                if (column.Length) {
                    sql += `(${column.Length}`
                    if (column.Decimals)
                        sql += `, ${column.Length}`
                    sql += `)`
                }
                sql += ` = NULL\n`
                if (column.IsPrimarykey) {
                    where += `${and}[${column.Name}] = @${column.Name}\n`
                    and = "AND "
                }
                else {
                    assignments += `${assignmentsComma}[${column.Name}] = @${column.Name}\n`
                    assignmentsComma = ","
                }
                parametersComma = ","
            })
            sql += `) AS\n`
            sql += `BEGIN\n`
            sql += `SET NOCOUNT ON\n`
            sql += `SET TRANSACTION ISOLATION LEVEL READ COMMITTED\n`
            sql += `UPDATE [dbo].[${table.Name}] \n ${assignments} ${where}\n`
            sql += `RETURN @@ROWCOUNT\n`
            sql += `END\n`
            sql += `GO\n`
        }

        return sql
    }
    static #GetDeleteScript(database, table, columns, domains, types) {
        let sql = string.Empty

        if (columns.length && table.procedureDelete) {
            let where = "WHERE "

            sql += `USE [${database.Alias}]\n`
            sql += `GO\n`
            sql += `SET ANSI_NULLS ON\n`
            sql += `GO\n`
            sql += `SET QUOTED_IDENTIFIER ON\n`
            sql += `GO\n`
            sql += `IF(SELECT object_id('${table.ProcedureDelete}')) IS NULL\n`
            sql += `EXEC('CREATE PROCEDURE [dbo].[${table.ProcedureDelete}] AS PRINT 1')\n`
            sql += `GO\n`
            sql += `ALTER PROCEDURE[dbo].[${table.ProcedureDelete}](\n`

            let comma = string.Empty,
                and = string.Empty
            datacolumns.forEach(column => {
                let domain = domains.find(domain => domain.Id === column.DomainId)
                let type = types.find(type => type.Id === domain.TypeId)

                sql += `${comma}@${column.Name} ${type.Name}`
                if (column.Length) {
                    sql += `(${column.Length}`
                    if (column.Decimals)
                        sql += `, ${column.Length}`
                    sql += `)`
                }
                sql += ` = NULL\n`
                if (column.IsFilterable) {
                    where += `${and}(@${column.Name} IS NULL OR [${column.Name}] = @${column.Name})\n`
                    and = "AND "
                }
                comma = ","

            })
            sql += `) AS\n`
            sql += `BEGIN\n`
            sql += `SET NOCOUNT ON\n`
            sql += `SET TRANSACTION ISOLATION LEVEL READ COMMITTED\n`
            sql += `DELETE FROM [dbo].[${table.Name}]\n${where}`
            sql += `RETURN @@ROWCOUNT\n`
            sql += `END\n`
            sql += `GO\n`
        }

        return sql
    }
    /**
     * @param {number} value
     */
    static set IdleTimeInMinutesLimit(value) {
        this.#IdleTimeInMinutesLimit = value
    }
}