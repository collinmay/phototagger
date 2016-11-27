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
    return this.rq.get("/api/whoami").then((json) => {
      return new User(this, json.id, json.google_id, json.grant_type);
    });
  }
  
  listPhotos(user) {
    return this.rq.get("/api/user/" + user.id + "/photo/list").then((json) => {
      if(user.id != "me" && user.id != json.owner) {
        throw "owner mismatch";
      }

      return json.photos.map((photo) => {
        return new Photo(this, photo.id, user, photo.provider, photo.provider_id, photo.fullres_url, photo.thumbnail_url);
      });
    });
  }

  postPhoto(user, photo) {
    return this.rq.post("/api/user/" + user.id + "/photo/", {provider: photo.provider, provider_id: photo.providerId}).then((json) => {
      jp = json.photo;
      return new Photo(this, jp.id, user, jp.provider, jp.provider_id, jp.fullres_url, jp.thumbnail_url);
    });
  }
}
