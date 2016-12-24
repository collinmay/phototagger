export class AppBarController {
  constructor(params) {
    this.asm = params.asm;
    this.view = params.view;
    this.modes = [];
  }

  addMode(mode) {
    this.view.modeContainers.push(mode.getContainer());
    this.modes.push(mode);
  }

  activateMode(mode, warp) {
    this.view.activate(mode, warp);
  }
  
  transitionState(state, warp) {
  }
}
