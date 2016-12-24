export class SnackbarController {
  constructor(params) {
    this.view = params.view
    this.currentSnackPromise = Promise.resolve();
  }
  snack(text, option, button) {
    return this.currentSnackPromise = this.currentSnackPromise.then(() => {
      return this.view.setContent(text, option, button);
    });
  }
};
