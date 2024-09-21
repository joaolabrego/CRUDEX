"use strict"

import TActions from "./TActions.class.mjs"
import TSystem from "./TSystem.class.mjs"
import TConfig from "./TConfig.class.mjs"
export default class TColumn {
    #Id = 0
    #TableId = 0
    #Sequence = 0
    #DomainId = 0
    #ReferenceTableId = 0
    #Name = ""
    #Description = ""
    #Title = ""
    #Caption = ""
    #Default = null
    #Minimum = null
    #Maximum = null
    #IsPrimarykey = false
    #IsAutoincrement = false
    #IsRequired = false
    #IsListable = false
    #IsFilterable = false
    #IsEditable = false
    #IsGridable = false
    #IsEncrypted = false
    #IsCalculated = false

    #LastValue = null
    #Value = null
    #FilterValue = null

    #Table = null
    #Domain = null
    #InputControl = null
    #CheckBoxControl = null

    constructor(table, rowColumn) {
        if (table.ClassName !== "TTable")
            throw new Error("Argumento table não é do tipo TTable.")
        if (rowColumn.ClassName !== "RecordColumn")
            throw new Error("Argumento rowColumn não é do tipo Column.")
        this.#Id = rowColumn.Id
        this.#TableId = rowColumn.TableId
        this.#Sequence = rowColumn.Sequence
        this.#ReferenceTableId = rowColumn.ReferenceTableId
        this.#DomainId = rowColumn.DomainId
        this.#Name = rowColumn.Name
        this.#Description = rowColumn.Description
        this.#Title = rowColumn.Title
        this.#Caption = rowColumn.Caption
        this.#IsPrimarykey = rowColumn.IsPrimarykey
        this.#IsAutoincrement = rowColumn.IsAutoincrement
        this.#IsRequired = rowColumn.IsRequired
        this.#IsListable = rowColumn.IsListable
        this.#IsFilterable = rowColumn.IsFilterable
        this.#IsEditable = rowColumn.IsEditable
        this.#IsGridable = rowColumn.IsGridable
        this.#IsEncrypted = rowColumn.IsEncrypted
        this.#IsCalculated = rowColumn.IsCalculated

        this.#Table = table
        this.#Domain = TSystem.GetDomain(rowColumn.DomainId)
    }
    #GeTGridCheckBox(value) {
        let control = document.createElement("input")

        control.type = this.#Domain.Type.Category.HtmlInputType
        control.indeterminate = TConfig.IsEmpty(value)
        control.checked = value
        control.title = TConfig.IsEmpty(value) ? "nulo" : value ? "sim" : "não"
        control.readOnly = true
        control.onclick = () => false

        return control
    }
    #GeTGridLabel(value) {
        let control = document.createElement("p")

        control.innerText = value

        return control
    }
    GeTGridControl(value) {
        if (this.#Domain.Type.Category.HtmlInputType === "checkbox")
            return this.#GeTGridCheckBox(value)

        return this.#GeTGridLabel(value)
    }
    /*
    #GetFormSelect(referenceRecordset) {
        let control = document.createElement("select")

        referenceRecordset.forEach(row => {
            let option = document.createElement("option")

            option.value = row[this.#references[0].foreignDatacolumn.name]
            option.innerText = row[this.#references[0].returnedDatacolumn.name]
        })

        return control
    }
    */
    #GetFormCheckBox() {
        let control = document.createElement("input")

        control.type = this.#Domain.Type.Category.HtmlInputType
        control.checked = this.#Value
        control.title = TConfig.IsEmpty() ? 'nulo' : control.checked ? "sim" : "não"
        control.indeterminate = TConfig.IsEmpty()
        control.onclick = (event) => {
            if (event.target.readOnly)
                return false
            if (TConfig.IsEmpty())
                this.#Value = false
            else if (this.#Value === false)
                this.#Value = true
            else
                this.#Value = null
            event.target.indeterminate = TConfig.IsEmpty()
            event.target.checked = event.target.value = this.#Value
            event.target.title = event.target.indeterminate ? "nulo" : event.target.checked ? "sim" : "não"
        }

        return control
    }
    #GetFormTextArea() {
        let control = document.createElement("textarea")

        control.rows = 5
        control.cols = 50

        return control
    }
    #GetFormNumberInput() {
        let control = document.createElement("input")

        control.type = this.#Domain.Type.HtmlInputType
        control.min = this.#Domain.Minimum
        control.max = this.#Domain.Maximum
        control.step = 1 / 10 ** (this.#Domain.Decimals || 0)

        return control
    }
    #GetFormTextInput() {
        let control = document.createElement("input")
        
        control.type = this.#Domain.Type.Category.HtmlInputType
        control.size = this.#Domain.Length ?? 20
        control.maxLength = this.#Domain.Length

        return control
    }
    GetFormControl(action) {
        let fieldset = document.createElement("fieldset"),
            legend = document.createElement("legend")

        legend.innerText = this.#Caption
        fieldset.appendChild(legend)
        if (this.#Domain.Type.Category.HtmlInputType === "checkbox")
            this.#InputControl = this.#GetFormCheckBox()
        else if (this.#Domain.Type.Category.HtmlInputType === "textarea")
            this.#InputControl = this.#GetFormTextArea()
        else if (this.#Domain.Type.Category.HtmlInputType === "number")
            this.#InputControl = this.#GetFormNumberInput()
        else if (this.#Domain.Type.Category.HtmlInputType === "text")
            this.#InputControl = this.#GetFormTextInput()
        this.#InputControl.onchange = event => {
            let value = event.target.type === "checkbox" ? eval(event.target.value) : event.target.value

            this.#Value = TConfig.IsEmpty(value) ? null : value
        }
        this.#InputControl.name = this.#Name
        this.#InputControl.onfocus = (event) => event.target.select()
        this.#InputControl.value = this.#Value
        this.#InputControl.readOnly = action === TActions.DELETE || action === TActions.QUERY
        this.#InputControl.style.textAlign = this.#Domain.Type.InputAlign
        fieldset.appendChild(this.#InputControl)

        //this.#CheckBoxControl = document.createElement("input")
        //this.#CheckBoxControl.type = "checkbox"
        //this.#CheckBoxControl.checked = true
        //this.#CheckBoxControl.title = "É null?"
        //fieldset.appendChild(this.#CheckBoxControl)

        return fieldset
    }
    get Id() {
        return this.#Id
    }
    get TableId() {
        return this.#TableId
    }
    get Sequence() {
        return this.#Sequence
    }
    get ReferenceTableId() {
        return this.#ReferenceTableId
    }
    get DomainId() {
        return this.#DomainId
    }
    get Name() {
        return this.#Name
    }
    get Description() {
        return this.#Description
    }
    get Title() {
        return this.#Title
    }
    get Caption() {
        return this.#Caption
    }
    get Default(){
        return this.#Default
    }
    get Minimum(){
        return this.#Minimum
    }
    get Maximum(){
        return this.#Maximum
    }
    get IsPrimarykey() {
        return this.#IsPrimarykey
    }
    get IsAutoincrement() {
        return this.#IsAutoincrement
    }
    get IsRequired() {
        return this.#IsRequired
    }
    get IsFilterable() {
        return this.#IsFilterable
    }
    get IsEditable() {
        return this.#IsEditable
    }
    get IsGridable(){
        return this.#IsGridable
    }    
    get IsListable() {
        return this.#IsListable
    }
    get IsEncrypted() {
        return this.#IsEncrypted
    }
    get IsCalculated(){
        return this.#IsCalculated
    }
    set LastValue(value) {
        this.#LastValue = value
    }
    get LastValue() {
        return this.#LastValue
    }
    set Value(value) {
        this.#Value = value
    }
    get Value() {
        return this.#Value
    }
    set FilterValue(value) {
        this.#FilterValue = value
    }
    get FilterValue() {
        return this.#FilterValue
    }
    get Table() {
        return this.#Table
    }
    get Domain() {
        return this.#Domain
    }
    get InputControl() {
        return this.#InputControl
    }
}