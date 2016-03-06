---
title: Quick Install Guide
index: 100
---

The object of this guide is to enable the administrator to install
or update the Clarive Software to version 6.4 in a simple way using the steps described below.

# Prerrequisites

The prerrequisites for the Clarive installation are
specified in the [Technical Specifications](install/specs).

# Software Download

The Clarive installable files are available here:

    http://www.clarive.com/install

In case you don’t find a good version for your operating system,
please contact our support at `support``@``clarive.com`

Follow the steps specified in the install website.
In this guide this information is extended for the users that need it.

### MongoDB

Clarive runs on top of the MongoDB database.
It could be downloaded from the website:

    https://www.mongodb.org/downloads

Choose the stable version 3.2.1.

# New Installation

## Environment variables

The directory on which you want to unzip the software of
Clarive is defined in the environment variable $CLARIVE_BASE.
You must to define four more environment variables.

```bash
export CLARIVE_BASE=/opt/clarive
export CLARIVE_HOME=$CLARIVE_BASE/clarive
export LD_LIBRARY_PATH=$CLARIVE_BASE/local/lib
export CLARIVE_ENV=your_environment
export PATH="$CLARIVE_HOME/bin:$CLARIVE_BASE/local/bin:$CLARIVE_BASE/local/sbin:$PATH"
```
Marked variables have to be adapted to the environment of
the installation. The software unzips the downloaded zipfile in `$CLARIVE_BASE`.

Inside the variable environment `$PATH`, it is needed add the route where the MongoDB is:

```bash
export MONGO_DB=/opt/mongo
export PATH="$MONGO_DB/bin:$PATH"
```

## New Directories

It's necessary to create the following directories if they weren't added when the
unzip of Clarive was done.

```bash
$CLARIVE_BASE/config
$CLARIVE_BASE/jobs
$CLARIVE_BASE/logs
$CLARIVE_BASE/tmp/nginx/client
```

## License

The configuration is by default stored in the clarive.yml file located in the
directory `$CLARIVE_HOME/config`. In addition, in this file, the current license is included.

You need to create a configuration file for your environment in
`$CLARIVE_BASE/config` called `$CLARIVE_ENV.yml`. Include the license in that file.

Use the company license if it was already purchased.

## Configuration

The configuration file which has been created for your environment
requires a minimum data that allows the correct operation of the tool.

By default, the values that are in the file are the ones that are taken:

    $CLARIVE_HOME/config/clarive.yml.

In the environment configuration file values that are necessary will be overwritten.

### NGINX Configuration

Nginx is included inside Clarive. However, it is necessary
to create a configuration file

    $CLARIVE_BASE/config/nginx.conf

Below, an example of nginx configuration:

```nginx
pid  ../logs/nginx.pid;
events {
    worker_connections  1024;
}

http {
    server {
        listen       80;
        server_name  localhost;

        access_log  ../logs/nginx.access.log  combined;
        error_log   ../logs/nginx.error.log;

        location / {
            proxy_pass http://localhost:3000;

            proxy_redirect     off;
            proxy_set_header   Host             $host;
            proxy_set_header   X-Real-IP        $remote_addr;
            proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
            proxy_set_header   X-Forwarded-Host  $host;
        }
    }
}
```

### MongoBD Configuration

Within the configuration file, it is necessary to specify the mongo database.
To do this, in the environment configuration file specify:

```yaml
mongo:
    dbname: your_database_name
```

Besides specifying the DataBase that Clarive will use, a configuration file from MongoDBis needed.
A possible location could be:

    $CLARIVE_BASE/config/mongod.conf

An example of a basic configuration of MongoDB
specified in the field could be:

```properties
fork=true
dbpath=/opt/mongo/data/
logpath=/opt/clarive/logs/mongod.log
pidfilepath=/opt/clarive/logs/mongod.pid
logappend=true
journal=true
port=27017
bind_ip=127.0.0.1
setParameter=failIndexKeyTooLong=false
```

## Start and Access

### Start Nginx

To start nginx as root:

    nginx -c $CLARIVE_BASE/config/nginx.conf

### Start MongoDB

To start MongoDB:

mongod -f $CLARIVE_BASE/config/mongod.conf

### Start Clarive

Clarive makes a difference between the web part
and the dispatcher part and both must started separately:

```bash
cla web-start --env your_environment --daemon
cla disp-start --env your_environment --daemon

cla web-stop --env your_environment
cla disp-stop --env your_environment
```

### Stop Clarive

As to start, it is necessary to stop both: the web and the dispatcher

```bash
cla web-stop --env your_environment
cla disp-stop --env your_environment

cla web-stop --env your_environment
cla disp-stop --env your_environment
```

### Access Clarive via Web

The URL to access to the instance of Clarive is:

    http://localhost:3000
    user: local/root
    password: admin

