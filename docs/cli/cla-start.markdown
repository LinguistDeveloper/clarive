---
title: cla start
---

`cla start`: start all server tasks. It tries to start all systems Clarive needs to operate. They are:

* *mongo*: Starts mongo server with configuration file located in `$CLARIVE_BASE/config/mongod.conf`.    

* *nginx*: Start nginx server.     

* *Clarive web server*: Web server started in daemon mode, options can be sent as arguments to the command to start web server in some way.

* *Clarive dispatcher*: Dispatcher server is started in daemon mode. Options can be sent as arguments to the command to start dispatcher server in some way.

<br/> 

This command supports some options. They are:    

* `--no_mongo`: To not start mongo server.    
* `--mongo_arbiter`: To start mongo arbiter server. It takes conf file from `$CLARIVE_BASE/conf/mongo-arb.conf`.   

<br/>  

By default, this conf file is not installed in Clarive installation,  please consult mongo documentation to create this conf file.    

* `--redis`: To start redis server.     

* `--no_nginx`: To not start nginx server.

