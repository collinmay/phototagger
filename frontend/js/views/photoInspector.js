import {noTransition} from "../util.js";
import {Photo} from "../models.js";
import * as TWEEN from "tween.js";

export class PhotoInspector {
  constructor(container, asm) {
    this.container = document.getElementById("photo-inspector-container");
    this.lastVolume = 1.0;
    this.updateViewer("img", "");
    this.asm = asm;
  }

  updateViewer(type, url) {
    let oldViewer = this.viewer;
    if(!this.viewer || this.viewer.localName != type) {
      let elem = document.createElement(type);
      elem.id = "photo-inspector-fullsize";
      if(type == "video") {
        elem.loop = true;
        elem.autoplay = true;
        elem.controls = true;
      }
      this.viewer = elem;
    }
    this.viewer.src = url;
    this.viewer.volume = this.lastVolume;
    if(oldViewer) {
      this.container.replaceChild(this.viewer, oldViewer);
    } else {
      this.container.appendChild(this.viewer);
    }
  }

  transitionState(state) {
    if(state.view == "photo") {
      this.container.className = "tab active";
      Photo.byId(state.photoId).then((photo) => {
        this.photo = photo;
        this.updateViewer(photo.isVideo ? "video" : "img", photo.fullresUrl);
      });
    } else {
      this.container.className = "tab";
      if(this.viewer.localName == "video") {
        let viewer = this.viewer;
        this.lastVolume = this.viewer.volume;
        new TWEEN.Tween({volume: this.viewer.volume})
          .to({volume: 0}, 600)
          .onUpdate(function() {
            viewer.volume = this.volume;
          }).start();
      }
    }
  }

  warpState(state) {
    noTransition([this.container], () => this.transitionState(state));
  }
}
