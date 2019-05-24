export class ImgurImportDialogController {
  constructor(params) {
    this.asm = params.asm;
    this.view = params.view;
    this.viewManager = params.dialogViewManager;

    this.view.onCancelButtonPressed((e) => this.viewManager.deactivate());
    this.view.onImportButtonPressed((e) => {
      this.viewManager.deactivate();
      switch(this.view.importMode()) {
      case "favorites":
        this.api.importPhotosFromImgurFavorites(params.user, this.view.username())
      }
    });
  }

  activate() {
    this.viewManager.activate(this.view);
  }
};
