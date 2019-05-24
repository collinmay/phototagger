let knownPhotos = {};
let knownUsers = {};

export class User {
  constructor(iface, id, googleId, grantType) {
    this.iface = iface;
    this.id = id;
    this.googleId = googleId;
    this.grantType = grantType;
    knownUsers[id] = this;
  }

  listPhotos() {
    return this.iface.listPhotos(this);
  }

  postPhoto(photo) {
    return this.iface.postPhoto(this, photo);
  }

  static byId(id) {
    if(knownUsers[id]) {
      return Promise.resolve(knownUsers[id]);
    } else {
      return this.iface.getUser(id);
    }
  }
}

export class Photo {
  constructor(iface, id, owner, provider, providerId, fullresUrl, thumbnailUrl, isVideo, importDate) {
    this.iface = iface;
    this.id = id;
    this.owner = owner;
    this.provider = provider;
    this.providerId = providerId;
    this.fullresUrl = fullresUrl;
    this.thumbnailUrl = thumbnailUrl;
    this.isVideo = isVideo;
    this.importDate = importDate;
    knownPhotos[id] = this;
  }

  save() {
    return this.owner.postPhoto(this);
  }

  static byId(id) {
    if(knownPhotos[id]) {
      return Promise.resolve(knownPhotos[id]);
    } else {
      return this.iface.getPhoto(id);
    }
  }

  static fromJson(iface, photo) {
    return User.byId(photo.user).then((user) => {
      return new Photo(iface, photo.id, user, photo.provider, photo.provider_id, photo.fullres_url, photo.thumbnail_url, photo.is_video, new Date(photo.import_date));
    });
  }
}
