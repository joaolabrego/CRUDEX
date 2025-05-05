"use strict";

import TScreen from "./TScreen.class.mjs";
import TSystem from "./TSystem.class.mjs";

export default class TMenu {
    static #HTML = {
        Container: null,
        Style: null,
    };
    static #Message = "Selecione a opção desejada e clique nela.";

    static Initialize(styles, rowsMenu) {
        if (styles.ClassName !== "Styles")
            throw new Error("Argumento styles não é do tipo Styles.");
        console.log(rowsMenu)
        let menuWidth = 0,
            GetOptions = (item, isPopup, firstItem, lastItem) => {
                let li = document.createElement("li");

                li.title = item.Message;
                if (firstItem)
                    li.className = "firstItem";
                if (lastItem)
                    li.className = " lastItem";

                if (item.Caption.length > menuWidth) {
                    menuWidth = item.Caption.length
                    document.documentElement.style.setProperty("--menu-width", `${Math.ceil(menuWidth * 1.10)}ch`);
                }

                let a = document.createElement("a");

                a.innerText = item.Caption;
                li.appendChild(a);

                let subItems = rowsMenu.filter(row => row.ParentMenuId == item.Id);
                if (subItems.length) {
                    if (isPopup) {
                        let span = document.createElement("span");

                        span.className = "parentMenu";
                        span.innerText = String.fromCharCode(9654);
                        li.appendChild(span);
                    }
                    let ul = document.createElement("ul");

                    subItems.forEach((row, index) => {
                        ul.appendChild(GetOptions(row, true, index === 0, index === subItems.length - 1));
                    });
                    li.appendChild(ul);
                }
                else if (item.Action)
                    li.onclick = () => TSystem.Action = item.Action;
                li.onmouseenter = () => TScreen.Message = item.Message;
                li.onmouseleave = () => TScreen.Message = this.#Message;

                return li;
            };

        this.#HTML.Container = document.createElement("nav");
        this.#HTML.Container.className = "menu";

        this.#HTML.Style = document.createElement("style");
        this.#HTML.Style.innerText = styles.Menu;
        this.#HTML.Container.appendChild(this.#HTML.Style);

        const ul = document.createElement("ul");
        rowsMenu.filter(row => !row.ParentMenuId)
            .forEach(row => {
                if (row.Kind !== "Menu")
                    throw new Error("Item de argumento rowsMenu não é do tipo Menu.");
                ul.appendChild(GetOptions(row));
            });

        this.#HTML.Container.appendChild(ul);
    }

    static Renderize() {
        TScreen.Title = "Menu Principal";
        TScreen.Main = this.#HTML.Container;
        TScreen.Message = this.#Message;
    }
}