---
title: Upgrading from previous versions
index: 700
icon: page
---

After downloading the software, it is recommended to unzip
on a different directory from the current directory.
You can also use the same directory and overwrite the files.

## Keeping the same directory for Clarive

If you decide to keep the same directory as the previous version of Clarive, it is necessary to make
a backup of folders `$CLARIVE_BASE/local` and `$CLARIVE_BASE/clarive` and replace them with the new ones.

## New Directory for Clarive

When using a different directory, it is necessary to update the environment variable
$CLARIVE_BASE with the directory where you want to unzip the new version.

    export CLARIVE_BASE=/opt/clarive

We must also move the folders where the logs, the features and configurations, etc are.

    mv $CLARIVE_BASE_OLD $CLARIVE_BASE
    rm -rf $CLARIVE_BASE/local
    rm -rf $CLARIVE_BASE/clarive

Once these steps are done, the new version
of the directory is decompressed in the new directory `$CLARIVE_BASE`

## Data Migrations

Data migrations may be required when starting the server (dispatcher
or web server).

When migrations are needed, the following message will be shown:

    pid_file: /opt/clarive/logs/cla-web-host-3000.pid
    (I)2015-03-04 21:19:38.057[74032] [B::Mongo:81] Mongo: new connection to db `acmebank`
    (D)2015-03-04 21:19:38.062[74032] [cache:43] CACHE Setup ok: expire_seconds 90000 driver Mongo
    ERROR: Migrations are not up to date. Run with --migrate flag or use migra- commands

To remedy this situation, start the server or dispatcher with the `--migrate` option added:

    cla web-start --env [myenv] --migrate

This will trigger a migration run, after which it will start the server/dispatcher
normally.

