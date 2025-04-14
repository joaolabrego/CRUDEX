export default class TScrollBar {
    #HTML = {
        Container: null,
        Track: null,
        Thumb: null,
    };
    constructor(onScrollCallback) {
        this.#HTML.Container = document.createElement("div");
        this.#HTML.Container.className = "scroll-container";

        this.#HTML.Track = document.createElement("div");
        this.#HTML.Track.className = "scroll-track";
        this.#HTML.Container.appendChild(this.#HTML.Scroll.Track);

        this.#HTML.Thumb = document.createElement("div");
        this.#HTML.Thumb.className = "scroll-thumb";
        this.#HTML.Track.appendChild(this.#HTML.Scroll.Thumb);
        this.#HTML.Track.onmousemove = (event) => {
            if (event.buttons === 1) {
                let trackRect = this.#HTML.Scroll.Track.getBoundingClientRect(),
                    newTop = event.clientY - trackRect.top;

                this.#UpdateScrollbarPosition(newTop);
            } else {
                let trackRect = this.#HTML.Scroll.Track.getBoundingClientRect(),
                    relativeY = event.clientY - trackRect.top;

                relativeY = Math.max(
                    0,
                    Math.min(
                        relativeY,
                        this.#HTML.Track.clientHeight -
                        this.#HTML.Thumb.clientHeight
                    )
                );

                let pageNumber = this.#CalculatePage(relativeY);

                this.#HTML.Scroll.Track.title = `Página ${pageNumber}${pageNumber === this.#PageCount ? " (última)" : ""}`;
            }
        };
        this.#HTML.Track.addEventListener("wheel", (event) => {
            event.preventDefault();

            let delta = event.deltaY,
                currentTop = parseFloat(this.#HTML.Scroll.Thumb.style.top) || 0,
                trackHeight = this.#HTML.Scroll.Track.clientHeight,
                thumbHeight = this.#HTML.Scroll.Thumb.clientHeight,
                maxTop = trackHeight - thumbHeight,
                scrollStep = maxTop / (this.#PageCount - 1),
                newTop = currentTop + (delta > 0 ? scrollStep : -scrollStep);

            this.#UpdateScrollbarPosition(newTop);
        });
        this.#HTML.Scroll.Track.onclick = (event) => {
            const trackRect = this.#HTML.Scroll.Track.getBoundingClientRect();
            const clickPosition = event.clientY - trackRect.top;
            this.#UpdateScrollbarPosition(
                clickPosition - this.#HTML.Scroll.Thumb.offsetHeight / 2
            );
        };
    }
    #CalculatePage(relativeY) {
        let trackHeight = this.#HTML.Scroll.Track.clientHeight,
            thumbHeight = this.#HTML.Scroll.Thumb.clientHeight,
            maxTop = trackHeight - thumbHeight;

        relativeY = Math.max(0, Math.min(relativeY, maxTop));

        if (this.#PageCount <= 1)
            return 1;

        let pageSize = maxTop / (this.#PageCount - 1);

        return Math.trunc(relativeY / pageSize + 1);
    }
    #UpdateScrollThumbFromInputs() {
        let trackHeight = this.#HTML.Scroll.Track.clientHeight,
            maxTop = trackHeight - this.#HTML.Scroll.Thumb.clientHeight,
            scrollPosition = Math.trunc(((this.#PageNumber - 1) / (this.#PageCount - 1)) * maxTop);

        this.#HTML.Scroll.Thumb.style.top = `${scrollPosition}px`;
    }
    #UpdateScrollbarPosition(newTop) {
        let trackHeight = this.#HTML.Scroll.Track.clientHeight,
            thumbHeight = this.#HTML.Scroll.Thumb.clientHeight,
            maxTop = trackHeight - thumbHeight;

        newTop = Math.max(0, Math.min(newTop, maxTop));
        this.#HTML.Scroll.Thumb.style.top = `${newTop}px`;

        let pageSize = maxTop / (this.#PageCount - 1);

        this.#IsNavigateByScroll = true;
        this.#LastPageNumber = this.#PageNumber;
        this.#PageNumber = newTop / pageSize + 1;
        this.#HTML.NumberInput.value = Math.trunc(this.#PageNumber);
        this.#HTML.NumberInput.dispatchEvent(new Event("change"));
    }
}
