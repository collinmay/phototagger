import {BackendInterface} from "./backend.js";
import {Gallery} from "./views/gallery.js";
import {PhotoInspector} from "./views/photoInspector.js";
import {AppBar} from "./views/appBar.js";
import {AppStateMachine} from "./application.js";
import co from "co";
import * as TWEEN from "tween.js";

window.onload = () => {
  if(history.state) {
    currentState = history.state; //overrides
  }

  let asm = window.appStateMachine = new AppStateMachine(currentState);
      
  window.onpopstate = (e) => {
    asm.transitionState(e.state || asm.defaultState());
  };
  
  let backend = new BackendInterface();
  
  co(function*() {
    let me = yield backend.whoami();
    let photos = yield me.listPhotos();

    let gallery = new Gallery(asm, photos);
    let photoInspector = new PhotoInspector(asm);
    let appBar = new AppBar(asm);
    asm.addComponent(gallery);
    asm.addComponent(photoInspector);
    asm.addComponent(appBar);
  });
};

function animate(t) {
  TWEEN.update(t);
  requestAnimationFrame(animate);
}
requestAnimationFrame(animate);
