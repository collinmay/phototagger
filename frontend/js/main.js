import co from "co";
import * as TWEEN from "tween.js";

import {AppBarController} from "./controllers/appBar.js";
import {AppBarView} from "./views/appBar.js";
import {AppStateMachine} from "./application.js";
import {BackendInterface} from "./backend.js";
import {DialogViewManager} from "./views/dialogManager.js";
import {GalleryAppBarView} from "./views/bar/gallery.js";
import {GalleryController} from "./controllers/gallery.js";
import {GalleryView} from "./views/gallery.js";
import {ImgurImportDialogController} from "./controllers/imgurImportDialog.js";
import {ImgurImportDialogView} from "./views/imgurImportDialog.js";
import {ImportDialogController} from "./controllers/importDialog.js";
import {ImportDialogView} from "./views/importDialog.js";
import {PhotoInspectorAppBarView} from "./views/bar/photoInspector.js";
import {PhotoInspectorController} from "./controllers/photoInspector.js";
import {PhotoInspectorView} from "./views/photoInspector.js";
import {SnackbarController} from "./controllers/snackbar.js";
import {SnackbarView} from "./views/snackbar.js";

window.onload = () => {
  if(history.state) {
    currentState = history.state; //overrides
  }

  let asm = window.appStateMachine = new AppStateMachine(currentState);
      
  window.onpopstate = (e) => {
    asm.transitionState(e.state || asm.defaultState(), true);
  };
  
  let backend = new BackendInterface();
  
  co(function*() {
    let me = yield backend.whoami();
    let photos = yield me.listPhotos();

    let snackbar = new SnackbarController({asm, view: new SnackbarView("snackbar")});
    let appBar = new AppBarController({asm, view: new AppBarView()})
    let photoInspector = new PhotoInspectorController({asm, view: new PhotoInspectorView(),
                                                       barView: new PhotoInspectorAppBarView(),
                                                       appBar, snackbar});
    let dialogViewManager = new DialogViewManager();
    let importDialog = new ImportDialogController({asm, view: new ImportDialogView("import-dialog"),
                                                   dialogViewManager,
                                                   imgurDialog: new ImgurImportDialogController(
                                                     {asm,
                                                      view: new ImgurImportDialogView("imgur-import-dialog"),
                                                      dialogViewManager
                                                     })});
    let gallery = new GalleryController({asm, view: new GalleryView(asm), photos,
                                         barView: new GalleryAppBarView(), appBar, importDialog});

    
    asm.addController(gallery);
    asm.addController(photoInspector);
    asm.addController(dialogViewManager);
  });
};

function animate(t) {
  TWEEN.update(t);
  requestAnimationFrame(animate);
}
requestAnimationFrame(animate);
