---
title: cla start - Start all server processes
icon: console
---

<img src="/static/images/icons/console.png" /> `cla start`: Start all server tasks. 

* It tries to start all systems Clarive needs to operate. 

* They are: <br />

&nbsp; &nbsp;• *mongo*: Starts mongo server with configuration file located in `$CLARIVE_BASE/config/mongod.conf`.

&nbsp; &nbsp;• *nginx*: Start nginx server.

&nbsp; &nbsp;• *Clarive web server*: Web server started in daemon mode, options can be sent as arguments to the command to start web server in some way.

&nbsp; &nbsp;• *Clarive dispatcher*: Dispatcher server is started in daemon mode. Options can be sent as arguments to the command to start dispatcher server in some way.

<br/> 

* This command supports some options. They are: <br/> 

&nbsp; &nbsp;•  `--no_mongo`: To not start mongo server.<br/> 

&nbsp; &nbsp;•  `--mongo_arbiter`: To start mongo arbiter server. It takes conf file from `$CLARIVE_BASE/conf/mongo-arb.conf`.

<br/>

* By default, this conf file is not installed in Clarive installation,  please consult mongo documentation to create this conf file.<br/> 

&nbsp; &nbsp;•  `--redis`: To start redis server. <br/> 

&nbsp; &nbsp;•  `--no_nginx`: To not start nginx server.

