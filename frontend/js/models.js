export class User {
  constructor(iface, id, googleId, grantType) {
    this.iface = iface;
    this.id = id;
    this.googleId = googleId;
    this.grantType = grantType;
  }

  listPhotos() {
    return this.iface.listPhotos(this);
  }

  postPhoto(photo) {
    return this.iface.postPhoto(this, photo);
  }
}

export class Photo {
  constructor(iface, id, owner, provider, providerId, fullresUrl, thumbnailUrl) {
    this.iface = iface;
    this.id = id;
    this.owner = owner;
    this.provider = provider;
    this.providerId = providerId;
    this.fullresUrl = fullresUrl;
    this.thumbnailUrl = thumbnailUrl;
  }

  save() {
    return this.owner.postPhoto(this);
  }
}
