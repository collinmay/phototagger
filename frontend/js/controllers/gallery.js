export class GalleryController {
  constructor(params) {
    this.asm = params.asm;
    this.view = params.view;
    this.barView = params.barView;
    this.appBar = params.appBar;

    this.importDialog = params.importDialog;
    
    this.barView.onImportButtonPressed((e) => {
      this.importDialog.activate();
    });

    this.view.appendPhotos(params.photos);
  }

  transitionState(state, warp) {
    if(state.view == "gallery") {
      this.appBar.activateMode(this.barView, warp);
    }
  }

  appendPhotos(photos) {
    this.view.appendPhotos(photos);
  }
}
