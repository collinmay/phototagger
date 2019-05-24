export class ImgurImportDialogView {
  constructor(id) {
    this.id = id;
    this.container = document.getElementById(id);
    this.cancelButton = document.getElementById(id + "-cancel-button");
    this.importButton = document.getElementById(id + "-import-button");
  }

  onCancelButtonPressed(cb) {
    this.cancelButton.addEventListener("click", cb);
  }

  onImportButtonPressed(cb) {
    this.importButton.addEventListener("click", cb);
  }
};
