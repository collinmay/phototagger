import co from "co";

let delay = ms => new Promise(r => setTimeout(r, ms));
let newImage = (src) => {
  return new Promise((resolve, reject) => {
    let image = new Image();
    image.onload = () => {
      resolve(image);
    };
    image.onerror = reject;
    image.src = src;
  });
};

export class GalleryView {
  constructor(asm) {
    this.asm = asm;
    this.container = document.getElementById("gallery-grid");
    this.photos = [];
  }
  appendPhotos(photos) {
    let domTrees = [];
    for(let i = 0; i < photos.length; i++) {
      let photoContainer = document.createElement("div");
      let photoGrowbox = document.createElement("div");
      let photoIconbox = document.createElement("div");
      let providerIcon = document.createElement("img");
      let photoCenterbox = document.createElement("div");
      
      photoContainer.className = "gallery-photo-container";
      photoGrowbox.className = "gallery-photo-growbox initial";
      photoIconbox.className = "gallery-photo-iconbox";
      providerIcon.src = "/" + photos[i].provider + "_material.svg";
      providerIcon.className = "gallery-photo-icon";
      photoCenterbox.className = "gallery-photo-centerbox";
      
      photoIconbox.appendChild(providerIcon);
      photoGrowbox.appendChild(photoIconbox);
      photoGrowbox.appendChild(photoCenterbox);
      photoContainer.appendChild(photoGrowbox);
      this.container.appendChild(photoContainer);

      photoGrowbox.addEventListener("click", (evt) => {
        this.asm.transitionState({
          view: "photo",
          photoId: photos[i].id
        });
      });
      
      domTrees[i] = {
        photoGrowbox, photoCenterbox
      };

      this.photos.push({
        photo: photos[i], photoContainer, photoGrowbox, photoCenterbox
      });
    }

    let self = this;
    co(function*() {
      for(let i = 0; i < Math.min(photos.length, 20); i++) {
        let photo = photos[i];
        newImage(photo.thumbnailUrl).then((img) => {
          let domTree = domTrees[i];
          img.className = "gallery-photo";
          domTree.photoCenterbox.appendChild(img);
          
          setTimeout(() => {
            domTree.photoGrowbox.className = "gallery-photo-growbox";
          }, 10);
        });
        
        yield delay(1);
      }

      self.sortPhotosByDateImported();
    });
  }

  sortPhotosByDateImported() {
    this.photos.sort((a, b) => {
      return a.photo.importDate - b.photo.importDate
    });
    for(let i = 0; i < this.photos.length; i++) {
      this.photos[i].photoContainer.style.order = i;
    };
  }
  
  warpState(state) {
    // do nothing
  }

  transitionState(state) {
    // do nothing
  }
}
