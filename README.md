T3/Breedbase
====

This repository contains the project structure, helper scripts, and sample configuration files needed 
to setup and run instances of T3/Breedbase for each of T3's supported crops (wheat, oat and barley).
T3's public instances can be found at the following locations:
- T3/Wheat - [https://wheat.triticeaetoolbox.org](https://wheat.triticeaetoolbox.org)
- T3/Oat - [https://oat.triticeaetoolbox.org](https://oat.triticeaetoolbox.org)
- T3/Barley - [https://barley.triticeaetoolbox.org](https://barley.triticeaetoolbox.org)

## System Requirements

The hardware requirements will vary depending on the number of instances running, the number 
of potential concurrent users, as well as the amount and size of the data stored in the database.
It is recommended to have at least 8 CPU cores and 8 GB of RAM - more will likely be needed for 
larger databases.

T3/Breedbase is distributed using two [Docker](https://www.docker.com) images: one for the postgres
database and another for the website.  In order to install T3/Breedbase you will need to already 
have **[Docker](https://docs.docker.com/get-docker/)** and **[Docker Compose](https://docs.docker.com/compose/install/)** 
installed.

## Setup

### Clone Project Repository

To start, first clone this repository into a directory where you will want to have all of the T3/Breedbase-related 
files stored (directories in this repository will be used to store the postgres data, uploaded files, etc).

```
git clone https://github.com/TriticeaeToolbox/breedbase.git /path/to/breedbase
```

### Initial Setup

Once you have the project repository cloned, you can use the `breedbase` helper script to run the intial setup script.  This 
script has a *setup* command which will download the T3/Breedbase Docker images (it will take a while to download the T3/Breedbase Web image), 
setup the intial databases for each crop, and allow you to set the database and website passwords.  After the initial setup finishes, 
the script will automatically run the update scripts to apply any new database patches and to load the trait ontologies for 
each crop.

```
cd /path/to/breedbase
./bin/breedbase setup
```

NOTE: Depending on your Docker setup, you may need to run the breedbase setup command as root or with `sudo`  in order to 
properly communicate with the Docker Daemon.


## Updates

Updating T3/Breedbase requires getting new Docker images when they're made available.  It is also required to run database 
patches that modify the structure of your database when necessary to allow for new features.  The `breedbase` helper script 
includes an *update* command that will update the T3/Breedbase Docker images, run database patches, and update the trait 
ontologies.

```
cd /path/to/breedbase
./bin/breedbase update
```

## Running T3/Breedbase

The `breedbase` helper script can be used to start and stop all of the T3/Breedbase Docker services.  There is a database service 
that runs a postgres server that contains a database for each of the three crops and a web service for the breedbase website 
instance for each crop.

To start and stop all of the services:
```
breedbase start
breedbase stop
```

To start the website for a single crop, start the database and the web service for that crop:
```
breedbase start db triticum
breedbase stop db triticum
```

To get the status of which services are running:
```
breedbase status
```

To view the breedbase error log for a web service:
```
breedbase log triticum
```

Once the service is running, the website will be available on the exposed port for each service:
- triticum: 8080
- avena: 8081
- hordeum: 8082

To view the website in your browser, navigate to http://localhost:{port}

For production systems, it is recommended that you put the T3/Breedbase web services behind a proxy 
server, such as NGINX, and forward the traffic to the appropriate port.

