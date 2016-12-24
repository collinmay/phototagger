import {noTransition} from "../util.js";
import {Photo} from "../models.js";
import {FullsizeImageView} from "./fullsizeImage.js";
import * as TWEEN from "tween.js";

export class PhotoInspectorView {
  constructor() {
    this.container = document.getElementById("photo-inspector-tab");
    this.fullsizeView = new FullsizeImageView(document.getElementById("photo-inspector-fullsize-container"));
  }

  activate(photo, warp, interiorWarp) {
    if(warp) {
      noTransition([this.container], () => {
        this.container.className = "tab active";
      });
    } else {
      this.container.className = "tab active";
    }
    
    this.photo = photo;
    this.fullsizeView.activate(photo, interiorWarp);    
    this.container.scrollTop = 0;
  }

  deactivate(warp) {
    if(warp) {
      noTransition([this.container], () => {
        this.container.className = "tab";
      });
    } else {
      this.container.className = "tab";
    }

    this.fullsizeView.deactivate();
  }
}
