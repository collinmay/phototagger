CREATE TABLE users (
       google_id char(21) UNIQUE,
       id integer UNIQUE PRIMARY KEY NOT NULL AUTO_INCREMENT
);

CREATE TABLE photos (
       photo_id integer UNIQUE NOT NULL PRIMARY KEY AUTO_INCREMENT,
       owner_id integer NOT NULL,
       host_type ENUM("gphotos", "imgur", "hotlink"),
       FOREIGN KEY(owner_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE tags (
       tag_id integer UNIQUE NOT NULL PRIMARY KEY AUTO_INCREMENT,
       owner_id integer NOT NULL,
       title char(128) NOT NULL,
       FOREIGN KEY(owner_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE photos_tags (
       tag_id integer NOT NULL,
       photo_id integer NOT NULL,
       FOREIGN KEY(tag_id) REFERENCES tags(tag_id) ON DELETE CASCADE,
       FOREIGN KEY(photo_id) REFERENCES photos(photo_id) ON DELETE CASCADE
);

CREATE TABLE google_photos (
       photo_id integer UNIQUE NOT NULL PRIMARY KEY,
       google_id char(21) NOT NULL,
       fullres_url char(128) NOT NULL,
       largethumb_url char(128) NOT NULL,
       FOREIGN KEY(photo_id) REFERENCES photos(photo_id) ON DELETE CASCADE
);

CREATE TABLE imgur_photos (
       photo_id integer UNIQUE NOT NULL PRIMARY KEY,
       imgur_id char(8) NOT NULL,
       FOREIGN KEY(photo_id) REFERENCES photos(photo_id) ON DELETE CASCADE
);

CREATE TABLE hotlink_photos (
       photo_id integer UNIQUE NOT NULL PRIMARY KEY,
       url char(256) NOT NULL
);
