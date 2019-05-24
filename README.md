# PhotoTagger

A project I was interested in finishing once upon a time. The idea was that you
could log in with your Google account, then import all the photos you wanted
from your Google Photos or imgur or whatever other site. Then, you'd be able to
annotate each photo with rich metadata, labelling things like who's in the
picture or when and where it was taken, but extensible enough to be able to
define your own categories of tags to annotate photos by concepts like "macro
shot", or "nostalgic". Combined with a powerful search system, finding a photo
you've taken and tagged would be very easy.

## What does it demonstrate?

Although I never got around to implementing the actual tagging functionality,
this app gave me a chance to explore full stack web development from
implementing a backend that handles multiple users and permission management to
implementing a frontend that runs on a single page and is built with modern
ECMAScript syntax.

## Live Instance?

Unfortunately there is no live instance of this app. I was thinking to perhaps
someday run a commercial instance of this app but I don't think I'm going to
finish it.

## Setup

Clone the repo and run `bundle update`.
```
$ git clone git@github.com:collinmay/phototagger.git
Cloning into 'phototagger'...
...
$ bundle update
...
Bundle complete! 18 Gemfile dependencies, 39 gems now installed.
Use `bundle info [gemname]` to see where a bundled gem is installed.
```

Next, set up a database and a user account. MySQL/MariaDB works best with this
app. I recommend generating a random password off https://random.org/passwords
to use for the user account.

```
$ mysql -u root -p

MariaDB [(none)]> CREATE DATABASE phototagger;
Query OK, 1 row affected (0.001 sec)

MariaDB [(none)]> CREATE USER 'phototagger'@'localhost' IDENTIFIED BY 'Vq3QxhenrxekRwrgvfBjQCdJ';
Query OK, 0 rows affected (0.005 sec)

MariaDB [(none)]> GRANT ALL ON phototagger.* TO 'phototagger'@'localhost';
Query OK, 0 rows affected (0.002 sec)

```

Copy `config.yml.template` to `config.yml` and populate it. Next, run the setup
app.

```
$ ruby setup_app.rb
Listening on localhost:4567, CTRL+C to stop
```

Navigate to the URL in a web browser and proceed to "Step 1: Connect to
Database". Enter the URL to log into the database. For this example,
`mysql2://phototagger:Vq3QxhenrxekRwrgvfBjQCdJ@localhost/phototagger`. You will
see the log output from the app connecting to the database and checking the
schema version. Press "Begin" to generate the tables. If it completes
successfully, press "Next" to configure the initial permission groups. You will
likely want to enable all permissions for the "superusers" group and at least
one image hosting permission for the "default" group. Hit "Submit" to confirm
the permission groups. Next, you will be prompted to create an administrator
account. Press "Authenticate" to be redirected to Google's OAuth login. The
account you select will be added as an administrator and setup will be complete.

Ctrl-c the setup and run the actual app with `rackup`.
