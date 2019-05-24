import {User, Photo} from "./models.js";

export class BackendInterface {
  constructor() {
    this.rq = {
      get(path) {
        return this.request(new Request(path));
      },
      
      post(path, body) {
        return this.request(new Request(path, {
          method: "POST",
          body: body
        }));
      },
      
      request(rq) {
        return fetch(rq, {
          credentials: "same-origin"
        }).then((response) => {
          if(!response.ok) {
            throw response;
          }
          return response.json();
        }).then((json) => {
          if(json.status != "success") {
            throw json;
          }
          return json;
        });
      }
    };
  }
  
  whoami() {
    if(this.user) {
      return this.user;
    }
    return this.user = this.rq.get("/api/whoami").then((json) => {
      return new User(this, json.id, json.google_id, json.grant_type);
    });
  }
  
  listPhotos(user) {
    return this.rq.get("/api/user/" + user.id + "/photo/list").then((json) => {
      if(user.id != "me" && user.id != json.owner) {
        throw "owner mismatch";
      }

      return Promise.all(json.photos.map((photo) => {
        return Photo.fromJson(this, photo);
      }));
    });
  }

  getPhoto(photoId) {
    return this.rq.get("/api/photo/" + photoId).then((json) => {
      return Photo.fromJson(this, json.photo);
    });
  }
  
  postPhoto(user, photo) {
    return this.rq.post("/api/user/" + user.id + "/photo/", {provider: photo.provider, provider_id: photo.providerId}).then((json) => {
      return Photo.fromJson(this, json.photo);
    });
  }

  importPhotosFromImgurFavorites(user, imgurUsername) {
    return this.rq.post("/api/user/" + user.id + "/photo/import/imgur/favorites/", {username: imgurUsername}).then((json) => {
      return Promise.all(json.photos.map((photo) => {
        return Photo.fromJson(this, photo);
      }));
    });
  }
}
