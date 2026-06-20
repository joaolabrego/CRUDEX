"use strict";

/**
 * Catálogo runtime de Properties (Prp): cada Name registra get/set sobre TEditBox.
 * Resolução sempre por Name — Id é só FK no metadado.
 */
export default class TProperty {
    static #handlers = new Map();

    static register(name, handler) {
        if (!name || typeof handler?.set !== "function")
            throw new Error("TProperty.register exige name e handler.set.");
        this.#handlers.set(String(name).trim().toLowerCase(), handler);
    }

    static registerAlias(alias, targetName) {
        const target = this.#handlers.get(String(targetName).trim().toLowerCase());
        if (!target)
            throw new Error(`TProperty.registerAlias: '${targetName}' não registrada.`);
        this.#handlers.set(String(alias).trim().toLowerCase(), target);
    }

    static has(name) {
        return this.#handlers.has(String(name).trim().toLowerCase());
    }

    static apply(editBox, name, value) {
        const handler = this.#handlers.get(String(name).trim().toLowerCase());
        if (!handler)
            return false;
        handler.set(editBox, value);
        return true;
    }

    static read(editBox, name) {
        const handler = this.#handlers.get(String(name).trim().toLowerCase());
        return handler?.get?.(editBox);
    }

    static parseOnOff(value, { on = "on", off = "off" } = {}) {
        if (value === null || value === undefined)
            return true;
        const text = String(value).trim().toLowerCase();
        if (text === "")
            return true;
        if (text === on || text === "true" || text === "1" || text === "yes" || text === "sim")
            return true;
        if (text === off || text === "false" || text === "0" || text === "no" || text === "nao" || text === "não")
            return false;
        return true;
    }

    static #registerBuiltins() {
        TProperty.register("enabled", {
            set(editBox, value) {
                editBox.applyContainerEnabled(TProperty.parseOnOff(value, { on: "enabled", off: "disabled" }));
            },
            get(editBox) {
                return editBox.containerEnabled ? "enabled" : "disabled";
            },
        });

        TProperty.register("disabled", {
            set(editBox, value) {
                const disabled = TProperty.parseOnOff(value, { on: "disabled", off: "enabled" });
                editBox.applyContainerEnabled(!disabled);
            },
            get(editBox) {
                return editBox.containerEnabled ? "enabled" : "disabled";
            },
        });

        TProperty.register("hidden", {
            set(editBox, value) {
                editBox.applyContainerHidden(TProperty.parseOnOff(value, { on: "hidden", off: "visible" }));
            },
            get(editBox) {
                return editBox.containerHidden ? "hidden" : "visible";
            },
        });

        TProperty.registerAlias("visible", "hidden");

        TProperty.register("readonly", {
            set(editBox, value) {
                editBox.applyControlReadonly(TProperty.parseOnOff(value, { on: "readonly", off: "editable" }));
            },
            get(editBox) {
                return editBox.controlReadonly ? "readonly" : "editable";
            },
        });

        TProperty.register("required", {
            set(editBox, value) {
                editBox.applyControlRequired(TProperty.parseOnOff(value, { on: "required", off: "optional" }));
            },
            get(editBox) {
                return editBox.controlRequired ? "required" : "optional";
            },
        });

        TProperty.register("value", {
            set(editBox, value) {
                editBox.applyControlValue(value);
            },
            get(editBox) {
                return editBox.controlValue;
            },
        });

        TProperty.register("placeholder", {
            set(editBox, value) {
                editBox.applyControlAttribute("placeholder", value ?? "");
            },
            get(editBox) {
                return editBox.controlAttribute("placeholder");
            },
        });

        TProperty.register("title", {
            set(editBox, value) {
                editBox.applyControlAttribute("title", value ?? "");
            },
            get(editBox) {
                return editBox.controlAttribute("title");
            },
        });

        TProperty.register("class", {
            set(editBox, value) {
                editBox.applyContainerClass(value ?? "");
            },
            get(editBox) {
                return editBox.containerClass;
            },
        });

        TProperty.register("style", {
            set(editBox, value) {
                editBox.applyContainerStyle(value ?? "");
            },
            get(editBox) {
                return editBox.containerStyle;
            },
        });

        for (const name of ["max", "min", "maxlength", "minlength", "step", "patternTitle", "aria-label"]) {
            TProperty.register(name, {
                set(editBox, value) {
                    editBox.applyControlAttribute(name, value ?? "");
                },
                get(editBox) {
                    return editBox.controlAttribute(name);
                },
            });
        }

        TProperty.register("mask", {
            set(editBox, value) {
                editBox.applyBehaviorMask(value);
            },
            get(editBox) {
                return editBox.behaviorMaskSpec;
            },
        });
    }

    static {
        TProperty.#registerBuiltins();
    }
}
