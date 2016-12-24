export class AppStateMachine {
  constructor(initialState) {
    this.controllers = [];
    this.warpState(initialState || this.defaultState());
  }

  defaultState() {
    return {view: "gallery"};
  }
  
  addController(controller) {
    controller.transitionState(this.state, true);
    this.controllers.push(controller);
  }
  
  warpState(state) {
    this.controllers.forEach((controller) => {
      controller.transitionState(state, true);
    });
    history.replaceState(state, "", this.urlFor(state));
    this.state = state;
  }

  transitionState(state, skipHistory) {
    this.controllers.forEach((controller) => {
      controller.transitionState(state, false);
    });
    if(!skipHistory) {
      history.pushState(state, "", this.urlFor(state));
    }
    this.state = state;
  }

  urlFor(state) {
    switch(state.view) {
    case "gallery":
      return "/app/round/";
    case "photo":
      return "/app/round/photo/" + state.photoId;
    default:
      return "/app/round/";
    }
  }
}
