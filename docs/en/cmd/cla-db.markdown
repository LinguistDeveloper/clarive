---
title: cla db - Database utilities
index: 5000
icon: console
---

### db-reindex

Reindexes all database tables, applying and updating the
product recommended indexes again.

`--drop` - drops known (product) indexes before reindexing.
`--collection [name]` - limit reindex to just this collection name
(ie. `topic`, `master`, etc.)

**WARNING**: a reindex can take anywhere from a few minutes to
many hours, and may block access to the database in the meanwhile.
So make sure to plan in advance for downtime.

### db-dump

Dumps a selection of collections from the MongoDB database using
the `mongodump` utility.


The collections dumped do not hold large "blobs",
it only includes things such as topics, CIs, and admin
info. The objective is to have a way of creating a quick dump
to send to support that is not as big as a full database dump.

A local installation of a MongoDB client is needed
for this command to work, and the `mongodump` command
needs to be in the path.

`--all`
dumps all collections instead, instead of just essential ones.
