export class SnackbarView {
  constructor(baseId) {
    this.container = document.getElementById(baseId);
    this.text = document.getElementById(baseId + "-text");
    this.option = document.getElementById(baseId + "-option");

    let hover = false;
    this.container.addEventListener("mouseenter", (e) => {
      hover = true;
    });
    this.container.addEventListener("mouseleave", (e) => {
      hover = false;
    });
    
    this.option.addEventListener("click", (e) => {
      if(this.callback) {
        this.callback();
      }
      this.hide = true;
      hover = false;
      this.container.className = "inactive";
    });
    this.container.addEventListener("transitionend", (e) => {
      if(!hover && this.hide) {
        this.resolve();
        this.resolve = null;
      }
    }, true);
  }

  setContent(text, option, callback) {
    this.text.textContent = text;
    if(option) {
      this.option.className = "";
      this.option.textContent = option;
    } else {
      this.option.className = "inactive";
    }
    this.callback = callback;
    this.container.className = "active";
    this.hide = false;
    window.setTimeout(() => {
      if(!this.hide) {
        this.hide = true;
        this.container.className = "";
      }
    }, text.length * 100 + (option ? 2000 : 0));
    if(this.resolve) {
      this.resolve();
    }
    return new Promise((resolve, reject) => {
      this.resolve = resolve;
    });
  }
}
