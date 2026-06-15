"use strict";

import TConfig from "./TConfig.class.mjs";
import TScreen from "./TScreen.class.mjs";
import TSystem from "./TSystem.class.mjs";

export default class TLogin {
    static #LoginId = 0;
    static #HTML = {
        Container: null,
        UserName: null,
        Password: null,
        ChangePassword: null,
        Label: null,
        NewPassword: null,
        RetypedPassword: null,
        Confirm: null,
        Style: null,
    };
    static #Observer = new IntersectionObserver((entries, observer) => {
        for (let entry of entries) {
            if (entry.isIntersecting) {
                entry.target.focus();
                observer.disconnect();
            }
        }
    });

    static Initialize(styles) {
        if (styles.ClassName !== "Styles")
            throw new Error("Argumento styles não é do tipo Styles.");
        this.#HTML.Container = document.createElement("form");
        this.#HTML.Container.className = "login box";
        this.#HTML.Style = document.createElement("style");
        this.#HTML.Style.innerText = styles.Login;
        this.#HTML.Container.appendChild(this.#HTML.Style);

        let onfocus = event => { event.target.select(); },
            onkeydown = event => {
                if (event.key === "Enter" || event.key === "Tab") {
                    event.preventDefault();
                    event.stopPropagation();

                    let focusableElements = Array.from(document.querySelectorAll("input[type='text'], input[type='password']"))
                        .filter(e => e.offsetParent !== null),
                        currentIndex = focusableElements.indexOf(document.activeElement);

                    if (currentIndex > -1) {
                        let nextIndex;
                        if (event.shiftKey)
                            nextIndex = (currentIndex > 0) ? currentIndex - 1 : focusableElements.length - 1;
                        else
                            nextIndex = (currentIndex < focusableElements.length - 1) ? currentIndex + 1 : 0;

                        focusableElements[nextIndex].focus();
                    }
                }
            },
            oninput = () => {
                if (this.#HTML.UserName.value === "" || this.#HTML.Password.value === "") {
                    this.#HTML.ChangePassword.setAttribute("hidden", "hidden");
                    this.#HTML.Label.setAttribute("hidden", "hidden")
                    this.#HTML.ChangePassword.checked = false;
                    this.#HTML.ChangePassword.dispatchEvent(new Event("change"));
                }
                else {
                    this.#HTML.ChangePassword.removeAttribute("hidden");
                    this.#HTML.Label.removeAttribute("hidden")
                }
            },
            onchange = (event) => {
                TScreen.ErrorMessage = "";
                if (event.target.checked) {
                    this.#HTML.NewPassword.removeAttribute("hidden");
                    this.#HTML.RetypedPassword.removeAttribute("hidden");
                    this.#HTML.NewPassword.focus();
                }
                else {
                    this.#HTML.NewPassword.setAttribute("hidden", "hidden");
                    this.#HTML.RetypedPassword.setAttribute("hidden", "hidden");
                    this.#HTML.NewPassword.value = this.#HTML.RetypedPassword.value = ""
                    if (this.#HTML.UserName.value === "")
                        this.#HTML.UserName.focus();
                    else if (this.#HTML.Password.value === "")
                        this.#HTML.Password.focus();
                    else
                        this.#HTML.UserName.focus();
                }
            }

        this.#HTML.UserName = document.createElement("input");
        this.#HTML.UserName.setAttribute("id", "textUserName");
        this.#HTML.UserName.setAttribute("type", "text");
        this.#HTML.UserName.setAttribute("title", "Digite seu nome de usuário");
        this.#HTML.UserName.setAttribute("placeholder", "username");
        this.#HTML.UserName.setAttribute("required", "true");
        this.#HTML.UserName.setAttribute("autocomplete", "off");
        this.#HTML.UserName.setAttribute("value", "labrego");
        this.#HTML.UserName.onfocus = onfocus;
        this.#HTML.UserName.onkeydown = onkeydown;
        this.#HTML.UserName.oninput = () => {
            oninput();
            TScreen.UserName = this.#HTML.UserName.value;
        }

        this.#HTML.Container.appendChild(this.#HTML.UserName);

        this.#HTML.Password = document.createElement("input");
        this.#HTML.Password.setAttribute("id", "textPassword");
        this.#HTML.Password.setAttribute("type", "password");
        this.#HTML.Password.setAttribute("title", "Digite sua senha");
        this.#HTML.Password.setAttribute("placeholder", "password");
        this.#HTML.Password.setAttribute("required", "true");
        this.#HTML.Password.setAttribute("autocomplete", "off");
        this.#HTML.Password.setAttribute("value", "diva");
        this.#HTML.Password.onfocus = onfocus;
        this.#HTML.Password.onkeydown = onkeydown;
        this.#HTML.Password.oninput = oninput;

        this.#HTML.Container.appendChild(this.#HTML.Password);

        this.#HTML.ChangePassword = document.createElement("input");
        this.#HTML.ChangePassword.setAttribute("id", "checkboxChangePassword");
        this.#HTML.ChangePassword.setAttribute("type", "checkbox");
        this.#HTML.ChangePassword.setAttribute("tabindex", "-1");
        this.#HTML.ChangePassword.setAttribute("title", "Marque para trocar senha");
        this.#HTML.ChangePassword.onchange = onchange;

        this.#HTML.Container.appendChild(this.#HTML.ChangePassword);

        this.#HTML.Label = document.createElement("label");
        this.#HTML.Label.htmlFor = "checkboxChangePassword";
        this.#HTML.Label.innerHTML = "&nbsp;Trocar senha";

        this.#HTML.Container.appendChild(this.#HTML.Label);

        this.#HTML.NewPassword = document.createElement("input");
        this.#HTML.NewPassword.setAttribute("type", "password");
        this.#HTML.NewPassword.setAttribute("title", "Digite sua nova senha");
        this.#HTML.NewPassword.setAttribute("placeholder", "new password");
        this.#HTML.NewPassword.setAttribute("required", "true");
        this.#HTML.NewPassword.setAttribute("autocomplete", "off");
        this.#HTML.NewPassword.setAttribute("value", "");
        this.#HTML.NewPassword.setAttribute("hidden", "hidden");
        this.#HTML.NewPassword.onfocus = onfocus;
        this.#HTML.NewPassword.onkeydown = onkeydown;

        this.#HTML.Container.appendChild(this.#HTML.NewPassword);

        this.#HTML.RetypedPassword = document.createElement("input");
        this.#HTML.RetypedPassword.setAttribute("type", "password");
        this.#HTML.RetypedPassword.setAttribute("title", "Redigite sua nova senha");
        this.#HTML.RetypedPassword.setAttribute("placeholder", "retype new password");
        this.#HTML.RetypedPassword.setAttribute("required", "true");
        this.#HTML.RetypedPassword.setAttribute("autocomplete", "off");
        this.#HTML.RetypedPassword.setAttribute("value", "");
        this.#HTML.RetypedPassword.setAttribute("hidden", "hidden");
        this.#HTML.RetypedPassword.onfocus = onfocus;
        this.#HTML.RetypedPassword.onkeydown = onkeydown;

        this.#HTML.Container.appendChild(this.#HTML.RetypedPassword);

        this.#HTML.Confirm = document.createElement("button");
        this.#HTML.Confirm.setAttribute("title", "Clique para confirmar nome e senha de usuário");
        this.#HTML.Confirm.innerText = "Confirmar";
        this.#HTML.Confirm.onclick = (event) => {
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
                else if (this.#HTML.RetypedPassword.validity.valueMissing) {
                    TScreen.ErrorMessage = "Senha redigitada do usuário é requerida.";
                    this.#HTML.RetypedPassword.focus();
                }
                else if (this.#HTML.Password.value == this.#HTML.NewPassword.value) {
                    TScreen.ErrorMessage = "Nova senha deve ser diferente da anterior.";
                    this.#HTML.NewPassword.focus();
                }
                else if (this.#HTML.NewPassword.value != this.#HTML.RetypedPassword.value) {
                    TScreen.ErrorMessage = "Senha redigitada do usuário não confere com a nova senha.";
                    this.#HTML.RetypedPassword.focus();
                }
                else {
                    TConfig.GetAPI(TSystem.Actions.CHANGE, {
                        NewPassword: this.#HTML.NewPassword.value,
                        RetypedPassword: this.#HTML.RetypedPassword.value,
                    })
                        .then((result) => {
                            this.#LoginId = result.Parameters.ReturnValue;
                            this.#HTML.ChangePassword.checked = false;
                            this.#HTML.Password.value = this.#HTML.NewPassword.value;
                            this.#HTML.ChangePassword.dispatchEvent(new Event('change', { bubbles: true }));
                            TSystem.Action = TSystem.Actions.MENU;
                        })
                        .catch(error => {
                            TScreen.ErrorMessage = error.message || error.Message;
                            if ((error.message || error.Message || "").toLowerCase().includes("senha"))
                                this.#HTML.Password.focus();
                            else
                                this.#HTML.UserName.focus();
                        });
                }
            }
            else {
                TConfig.GetAPI(TSystem.Actions.LOGIN)
                    .then((result) => {
                        this.#LoginId = result.Parameters.ReturnValue;
                        TSystem.Action = TSystem.Actions.MENU;
                    })
                    .catch(error => {
                        TScreen.ErrorMessage = error.message || error.Message;
                        if ((error.message || error.Message || "").toLowerCase().includes("senha"))
                            this.#HTML.Password.focus();
                        else
                            this.#HTML.UserName.focus();
                    });
            }
        };
        this.#HTML.Container.appendChild(this.#HTML.Confirm);
    }
    static Renderize() {
        TScreen.Title = "Acesso do Usuário";
        TScreen.Message = "Digite seu login e senha de usuário.";
        TScreen.Main = this.#HTML.Container;
        this.#Observer.observe(this.#HTML.UserName);
    }
    static Logout() {
        if (this.#LoginId)
            TConfig.GetAPI(TSystem.Actions.LOGOUT)
                .catch(error => TScreen.ShowError(error.message || error.Message, error.Action));
    }
    static set LoginId(value) {
        this.#LoginId = value;
    }
    static get LoginId() {
        return this.#LoginId;
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