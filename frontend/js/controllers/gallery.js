export class GalleryController {
  constructor(params) {
    this.asm = params.asm;
    this.view = params.view;
    this.barView = params.barView;
    this.appBar = params.appBar;
  }

  transitionState(state, warp) {
    if(state.view == "gallery") {
      this.appBar.activateMode(this.barView, warp);
    }
  }
}
