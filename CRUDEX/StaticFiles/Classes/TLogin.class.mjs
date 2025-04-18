"use strict";

import TActions from "./TActions.class.mjs";
import TConfig from "./TConfig.class.mjs";
import TScreen from "./TScreen.class.mjs";
import TSystem from "./TSystem.class.mjs";

export default class TLogin {
    static #LoginId = 0;
    static #PublicKey = "";
    static #HTML = {
        Container: null,
        UserName: null,
        Password: null,
        ChangePassword: null,
        NewPassword: null,
        RetypePassword: null,
        Submit: null,
        Style: null,
    };
    static Initialize(styles) {
        if (styles.ClassName !== "Styles")
            throw new Error("Argumento styles não é do tipo Styles.");
        this.#HTML.Container = document.createElement("form");
        this.#HTML.Container.className = "login box";
        this.#HTML.Container.onkeyup = (event) => {
            if (event.key === "Enter")
                this.#HTML.Submit.click();
        };

        this.#HTML.Style = document.createElement("style");
        this.#HTML.Style.innerText = styles.Login;
        this.#HTML.Container.appendChild(this.#HTML.Style);

        this.#HTML.UserName = document.createElement("input");
        this.#HTML.UserName.setAttribute("id", "textUserName");
        this.#HTML.UserName.setAttribute("type", "text");
        this.#HTML.UserName.setAttribute("title", "Digite seu nome de usuário");
        this.#HTML.UserName.setAttribute("placeholder", "username");
        this.#HTML.UserName.setAttribute("required", "true");
        this.#HTML.UserName.setAttribute("autocomplete", "off");
        this.#HTML.UserName.setAttribute("value", "labrego");
        this.#HTML.UserName.onfocus = () => this.#HTML.UserName.select();
        this.#HTML.UserName.oninput = () => TScreen.UserName = this.#HTML.UserName.value;

        this.#HTML.Container.appendChild(this.#HTML.UserName);

        this.#HTML.Password = document.createElement("input");
        this.#HTML.Password.setAttribute("id", "textPassword");
        this.#HTML.Password.setAttribute("type", "password");
        this.#HTML.Password.setAttribute("title", "Digite sua senha");
        this.#HTML.Password.setAttribute("placeholder", "password");
        this.#HTML.Password.setAttribute("required", "true");
        this.#HTML.Password.setAttribute("autocomplete", "off");
        this.#HTML.Password.setAttribute("value", "diva");
        this.#HTML.Password.onfocus = () => this.#HTML.Password.select();

        this.#HTML.Container.appendChild(this.#HTML.Password);

        this.#HTML.ChangePassword = document.createElement("input");
        this.#HTML.ChangePassword.setAttribute("id", "checkboxChangePassword");
        this.#HTML.ChangePassword.setAttribute("type", "checkbox");
        this.#HTML.ChangePassword.setAttribute("tabindex", "-1");
        this.#HTML.ChangePassword.setAttribute("title", "Marque para trocar senha");
        this.#HTML.ChangePassword.onchange = () => {
            TScreen.ErrorMessage = "";
            if (this.#HTML.ChangePassword.checked) {
                this.#HTML.NewPassword.removeAttribute("hidden");
                this.#HTML.RetypePassword.removeAttribute("hidden");
            }
            else {
                this.#HTML.NewPassword.setAttribute("hidden", "hidden");
                this.#HTML.RetypePassword.setAttribute("hidden", "hidden");
                this.#HTML.NewPassword.value = this.#HTML.RetypePassword.value = ""
            }
            this.#HTML.UserName.focus();
        }

        this.#HTML.Container.appendChild(this.#HTML.ChangePassword);

        let label = document.createElement("label");

        label.htmlFor = "checkboxChangePassword";
        label.innerHTML = "&nbsp;&nbsp;&nbsp;Trocar senha";

        this.#HTML.Container.appendChild(label);

        this.#HTML.NewPassword = document.createElement("input");
        this.#HTML.NewPassword.setAttribute("type", "password");
        this.#HTML.NewPassword.setAttribute("title", "Digite sua nova senha");
        this.#HTML.NewPassword.setAttribute("placeholder", "new password");
        this.#HTML.NewPassword.setAttribute("required", "true");
        this.#HTML.NewPassword.setAttribute("autocomplete", "off");
        this.#HTML.NewPassword.setAttribute("value", "");
        this.#HTML.NewPassword.setAttribute("hidden", "hidden");
        this.#HTML.NewPassword.onfocus = () => this.#HTML.NewPassword.select();

        this.#HTML.Container.appendChild(this.#HTML.NewPassword);

        this.#HTML.RetypePassword = document.createElement("input");
        this.#HTML.RetypePassword.setAttribute("type", "password");
        this.#HTML.RetypePassword.setAttribute("title", "Redigite sua nova senha");
        this.#HTML.RetypePassword.setAttribute("placeholder", "retype new password");
        this.#HTML.RetypePassword.setAttribute("required", "true");
        this.#HTML.RetypePassword.setAttribute("autocomplete", "off");
        this.#HTML.RetypePassword.setAttribute("value", "");
        this.#HTML.RetypePassword.setAttribute("hidden", "hidden");
        this.#HTML.RetypePassword.onfocus = () => this.#HTML.RetypePassword.select();

        this.#HTML.Container.appendChild(this.#HTML.RetypePassword);

        this.#HTML.Submit = document.createElement("button");
        this.#HTML.Submit.setAttribute("type", "button");
        this.#HTML.Submit.setAttribute("title", "Clique para confirmar nome e senha de usuário");
        this.#HTML.Submit.innerText = "Confirmar";
        this.#HTML.Submit.onclick = (event) => {
            event.preventDefault();
            event.stopPropagation();
            TScreen.ErrorMessage = "";
            if (this.#HTML.UserName.validity.valueMissing) {
                TScreen.ErrorMessage = "Nome do usuário é requerido.";
                this.#HTML.UserName.focus();
            }
            else if (this.#HTML.Password.validity.valueMissing) {
                TScreen.ErrorMessage = "Senha do usuário é requerida.";
                this.#HTML.Password.focus();
            }
            else if (this.#HTML.ChangePassword.checked) {
                if (this.#HTML.NewPassword.validity.valueMissing) {
                    TScreen.ErrorMessage = "Nova senha do usuário é requerida.";
                    this.#HTML.NewPassword.focus();
                }
                else if (this.#HTML.RetypePassword.validity.valueMissing) {
                    TScreen.ErrorMessage = "Senha redigitada do usuário é requerida.";
                    this.#HTML.RetypePassword.focus();
                }
                else if (this.#HTML.Password.value == this.#HTML.NewPassword.value) {
                    TScreen.ErrorMessage = "Nova senha deve ser diferente da anterior.";
                    this.#HTML.NewPassword.focus();
                }
                else if (this.#HTML.NewPassword.value != this.#HTML.RetypePassword.value) {
                    TScreen.ErrorMessage = "Senha redigitada do usuário não confere com a nova senha.";
                    this.#HTML.RetypePassword.focus();
                }
                else {
                    TConfig.GetAPI(TActions.CHANGE, { NewPassword: this.#HTML.NewPassword })
                        .then((result) => {
                            this.#LoginId = result.Parameters.ReturnValue;
                            this.#HTML.ChangePassword.checked = false;
                            this.#HTML.ChangePassword.dispatchEvent(new Event('change', { bubbles: true }));
                            this.#HTML.NewPassword.value = this.#HTML.RetypePassword.value = ""
                            TSystem.Action = TActions.MENU;
                        })
                        .catch(error => {
                            TScreen.ErrorMessage = error.Message;
                            if (error.Message.toLowerCase().includes("senha"))
                                this.#HTML.Password.focus();
                            else
                                this.#HTML.UserName.focus();
                        });
                }
            }
            else {
                TConfig.GetAPI(TActions.LOGIN)
                    .then((result) => {
                        this.#LoginId = result.Parameters.ReturnValue;
                        TSystem.Action = TActions.MENU;
                    })
                    .catch(error => {
                        TScreen.ErrorMessage = error.Message;
                        if (error.Message.toLowerCase().includes("senha"))
                            this.#HTML.Password.focus();
                        else
                            this.#HTML.UserName.focus();
                    });
            }
        };
        this.#HTML.Container.appendChild(this.#HTML.Submit);
    }
    static Renderize() {
        TScreen.Title = "Acesso do Usuário";
        TScreen.Message = "Digite seu login e senha de usuário.";
        TScreen.Main = this.#HTML.Container;
        this.#HTML.UserName.focus();
    }
    static Logout() {
        if (this.#LoginId)
            TConfig.GetAPI(TActions.LOGOUT)
                .catch(error => TScreen.ShowError(error.message || error.Message, error.Action));
    }
    static set LoginId(value) {
        this.#LoginId = value;
    }
    static get LoginId() {
        return this.#LoginId;
    }
    static get PublicKey() {
        return this.#PublicKey;
    }
    static set UserName(value) {
        this.#HTML.UserName.value = TScreen.UserName = value;
    }
    static get UserName() {
        return this.#HTML.UserName.value;
    }
    static set Password(value) {
        this.#HTML.Password.value = value;
    }
    static get Password() {
        return this.#HTML.Password.value;
    }
}