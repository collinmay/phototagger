export class PhotoInspectorAppBarView {
  constructor() {
    this.container = document.getElementById("photo-navmode");
    this.deleteButton = document.getElementById("photo-inspector-bar-delete-button");
    this.galleryButton = document.getElementById("photo-inspector-bar-gallery-button");
  }

  getContainer() {
    return this.container;
  }
  
  onDeleteButtonPressed(cb) {
    this.deleteButton.addEventListener("click", cb);
  }

  onGalleryButtonPressed(cb) {
    this.galleryButton.addEventListener("click", cb);
  }
}
