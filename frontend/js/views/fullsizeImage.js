import {SwitcherView} from "./switcher.js";

export class FullsizeImageView {
  constructor(container) {
    this.switcher = new SwitcherView(container, document.createElement("div"));
    this.currentId = 0;
  }

  activate(photo, warp) {
    let elem;
    let currentId = this.currentId;
    let doneSwitch = false;
    let doSwitch = () => {
      if(!doneSwitch) {
        this.switcher.switchIn(elem,
                               photo.id > currentId ? "right" : "left",
                               photo.id < currentId ? "right" : "left", warp);
        doneSwitch = true;
      }
    };
    this.currentId = photo.id;
    if(photo.isVideo) {
      elem = document.createElement("video");
      elem.oncanplay = doSwitch;
      elem.src = photo.fullresUrl;
      elem.className = "switcher";
      elem.loop = true;
      elem.autoplay = true;
      elem.controls = true;
    } else {
      elem = document.createElement("img");
      elem.onload = doSwitch;
      elem.src = photo.fullresUrl;
      elem.className = "switcher";
    }
  }

  deactivate() {
  }
}
