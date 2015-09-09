---
title: cla stop - stops all server processes
---

`cla stop`: stop all server processes. It tries to stop all systems Clarive needs to operate. They are:

* *mongo*: Stop mongo server.
* *nginx*: Stop nginx server.
* *Clarive web server*: Stop web server, options can be sent as arguments to the command to stop web server in some way.
* *Clarive dispatcher*: Stop dispatcher server, options can be sent as arguments to the command to stop dispatcher in some way.

<br/>
This command supports some options. They are:

* `--no_mongo`: To not stop mongo server.
* `--redis`: To stop redis server.
* `--no_nginx`: To not stop nginx server.


