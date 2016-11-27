import {BackendInterface} from "./backend.js";
import {Gallery} from "./views/gallery.js";
import {PhotoInspector} from "./views/photoInspector.js";
import co from "co";

window.onload = () => {
  let galleryGrid = document.getElementById("gallery-grid");
  let photoInspectorContainer = document.getElementById("photo-inspector-container");

  let activateInspector = (photo) => {
    photoInspectorContainer.className = "tab active";
    history.pushState({
      view: "photo",
      photoId: photo.id
    }, "Photo", "/app/round/photo/" + photo.id);
  };
  
  let backend = new BackendInterface();
  
  co(function*() {
    let me = yield backend.whoami();
    let photos = yield me.listPhotos();

    let gallery = new Gallery(galleryGrid, photos, activateInspector);
    
  });
};

window.onpopstate = (evt) => {
  
};
