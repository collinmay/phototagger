export class GalleryAppBarView {
  constructor() {
    this.container = document.getElementById("gallery-navmode");
    this.importButton = document.getElementById("gallery-bar-import-button");
  }

  getContainer() {
    return this.container;
  }

  onImportButtonPressed(cb) {
    this.importButton.addEventListener("click", cb);
  }
}
