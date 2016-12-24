import {Photo} from "../models.js";
import * as TWEEN from "tween.js";

export class AppBarTitleView {
  constructor(asm) {
    this.viewTitle = document.getElementById("view-title");
    this.transitioning = false;
    this.viewTitle.addEventListener("transitionend", (event) => {
      if(this.transitioning) {
        this.viewTitle.textContent = this.targetContent;
        this.viewTitle.className = "";
        this.transitioning = false;
      }
    }, true);
  }

  setContent(content, warp) {
    if(this.viewTitle.textContent != content) {
      if(warp) {
        this.viewTitle.textContent = content;
      } else {
        this.transitioning = true;
        this.targetContent = content;
        this.viewTitle.className = "transition";
      }
    }
  }
}
