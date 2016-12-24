export class AppStateMachine {
  constructor(initialState) {
    this.components = [];
    this.warpState(initialState || this.defaultState());
  }

  defaultState() {
    return {view: "gallery"};
  }
  
  addComponent(component) {
    component.warpState(this.state);
    this.components.push(component);
  }
  
  warpState(state) {
    this.components.forEach((component) => {
      component.warpState(state);
    });
    history.replaceState(state, "", this.urlFor(state));
    this.state = state;
  }

  transitionState(state) {
    this.components.forEach((component) => {
      component.transitionState(state);
    });
    history.pushState(state, "", this.urlFor(state));
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
