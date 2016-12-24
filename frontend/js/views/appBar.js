import {noTransition} from "../util.js";
import {Photo} from "../models.js";
import * as TWEEN from "tween.js";

export class AppBar {
  constructor(asm) {
    this.viewTitle = document.getElementById("view-title");
    this.transitioning = false;
    this.viewTitle.addEventListener("transitionend", (event) => {
      if(this.transitioning) {
        this.warpState(asm.state);
        this.viewTitle.className = "navbar-brand";
        console.log("finish transition");
        this.transitioning = false;
      }
    }, true);
  }

  warpState(state) {
    switch(state.view) {
    case "gallery":
      this.viewTitle.textContent = "Gallery";
      break;
    case "photo":
      this.viewTitle.textContent = "Photo";
      break;
    }
  }

  transitionState(state) {
    this.transitioning = true;
    this.viewTitle.className = "transition navbar-brand";
  }
}
