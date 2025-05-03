"use strict";

import TConfig from "./TConfig.class.mjs";
export default class TMask {
    constructor(rowMask) {
        if (rowMask.Kind !== "Mask")
            throw new Error("Argumento rowMask não é do tipo Mask.");
        TConfig.CreateProperties(rowMask, this);
    }
}