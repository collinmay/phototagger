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

export class Gallery {
  constructor(container, photos, activateInspector) {
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
      container.appendChild(photoContainer);

      photoGrowbox.addEventListener("click", (evt) => {
        activateInspector(photos[i]);
      });
      
      domTrees[i] = {
        photoGrowbox, photoCenterbox
      };
    }
    
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
    });
  }
}
