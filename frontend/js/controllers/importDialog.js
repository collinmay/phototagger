export class ImportDialogController {
  constructor(params) {
    this.asm = params.asm;
    this.view = params.view;
    this.viewManager = params.dialogViewManager;

    this.imgurDialog = params.imgurDialog;
    
    this.view.onCancelButtonPressed((e) => this.viewManager.deactivate());
    this.view.onCardPressed("imgur", (e) => this.imgurDialog.activate());
  }

  activate() {
    this.viewManager.activate(this.view);
  }
};
