"use strict"

export default class TScrollbar {
    #Scrollbar = null
    #ScrollTrack = null
    #Grid = null
    #IsDragging = false
    #CurrentPage = 0
    #TotalPages = 0
    #RowsPerPage = 0

    constructor(grid) {
        if (grid.ClassName !== "TGrid")
            throw new Error("Argumento grid não é do tipo TGrid.")
        this.#Grid = grid
    }
    static Initialize(styles) {
        if (styles.ClassName !== "Styles")
            throw new Error("Argumento styles não é do tipo Styles.")

        let style = document.createElement("style")

        style.innerText = styles.Scrollbar
        this.#Scrollbar = document.createElement("div")
        this.#Scrollbar.appendChild(style)
        this.#Scrollbar.className = "scroll-container"

        this.#HTML.TableContainer = document.createElement("div")
        this.#HTML.TableContainer.appendChild(style)
        this.#HTML.TableContainer.className = "scroll-track"

        this.#HTML.Grid = document.createElement("div")
        this.#HTML.Grid.appendChild(style)
        this.#HTML.Grid.className = "scroll-thumb"

        this.scrollbar.addEventListener('mousedown', () => {
            this.isDragging = true;
            document.body.style.userSelect = 'none';
        });

        document.addEventListener('mousemove', (e) => {
            if (this.isDragging) {
                const trackRect = this.scrollTrack.getBoundingClientRect();
                let newTop = e.clientY - trackRect.top - this.scrollbar.offsetHeight / 2;
                this.updateScrollbarPosition(newTop);
            }
        });

        document.addEventListener('mouseup', () => {
            this.isDragging = false;
            document.body.style.userSelect = 'auto';
        });

        this.scrollTrack.addEventListener('click', (e) => {
            const trackRect = this.scrollTrack.getBoundingClientRect();
            const clickPosition = e.clientY - trackRect.top;
            this.updateScrollbarPosition(clickPosition - this.scrollbar.offsetHeight / 2);
        });

        this.scrollTrack.addEventListener('wheel', (e) => {
            const delta = e.deltaY;
            let currentTop = parseInt(this.scrollbar.style.top) || 0;
            let newTop = currentTop + delta * 0.2;
            this.updateScrollbarPosition(newTop);
        });


    }
    static Show() {
        this.#Container.showModal()
    }
    static Hide() {
        this.#Container.close()
    }
    static get Container() {
        return this.#Container
    }
}