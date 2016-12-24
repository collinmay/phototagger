import {Photo} from "../models.js";

export class PhotoInspectorController {
  constructor(params) {
    this.mainView = params.view;
    this.barView = params.barView;
    this.appBar = params.appBar;
    this.snackbar = params.snackbar;
    this.asm = params.asm;
    this.appBar.addMode(this.barView);

    this.barView.onDeleteButtonPressed((e) => {
      this.snackbar.snack("Deleted photo.", "Undo", () => {
        this.snackbar.snack("Undeleted photo.");
      });
    });

    this.barView.onGalleryButtonPressed((e) => {
      e.preventDefault();
      this.asm.transitionState({view: "gallery"});
    });
    
    this.isActive = false;

    window.addEventListener("keypress", (e) => {
      if(this.isActive && this.photo) {
        if(e.key == "ArrowRight") {
          this.asm.transitionState({
            view: "photo",
            photoId: this.photo.id + 1
          });
        }
        if(e.key == "ArrowLeft") {
          this.asm.transitionState({
            view: "photo",
            photoId: this.photo.id - 1
          });
        }
      }
    });
  }

  transitionState(state, warp) {
    if(state.view == "photo") {
      let interiorWarp = warp;
      if(!this.isActive) {
        interiorWarp = true;
        this.isActive = true;
      }
      Photo.byId(state.photoId).then((photo) => {
        this.photo = photo;
        this.mainView.activate(photo, warp, interiorWarp);
      });
      this.appBar.activateMode(this.barView, warp);
    } else {
      this.isActive = false;
      this.mainView.deactivate(warp);
    }
  }
}
