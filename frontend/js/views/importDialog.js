export class ImportDialogView {
  constructor(id) {
    this.id = id;
    this.container = document.getElementById(id);
    this.cancelButton = document.getElementById(id + "-cancel-button");
  }

  onCancelButtonPressed(cb) {
    this.cancelButton.addEventListener("click", cb);
  }

  onCardPressed(name, cb) {
    document.getElementById(this.id + "-" + name + "-card").addEventListener("click", cb);
  }
};
