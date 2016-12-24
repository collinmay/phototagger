import {noTransition} from "../util.js";
import {AppBarTitleView} from "./appBarTitle.js";

export class AppBarView {
  constructor() {
//    this.titleView = new AppBarTitleView();
    this.modeContainers = [];
    this.currentMode = null;
  }

  activate(mode, warp) {
    if(warp) {
      noTransition(this.modeContainers, () => {
        this.activate(mode, false);
      });
    } else {
      if(this.currentMode) {
        this.currentMode.className = "navmode";
      }
      this.currentMode = mode.getContainer();
      this.currentMode.className = "navmode active";
    }
  //  this.titleView.setContent(mode.getTitle(), warp);
  }
  
/*  transitionState(state) {
    if(this.currentMode) {
      this.currentMode.className = "navmode"
    }
    switch(state.view) {
    case "gallery":
      this.currentMode = this.navModes.gallery;
      break;
    case "photo":
      this.currentMode = this.navModes.photo;
      break;
    }
    this.currentMode.className = "navmode active";
  }*/
}
