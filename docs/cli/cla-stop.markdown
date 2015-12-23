---
title: cla stop - Stops all server processes
icon: console
---

<img src="/static/images/icons/console.png" /> `cla stop`: Stop all server processes. It tries to stop all systems Clarive needs to operate. 

* They are: <br />

&nbsp; &nbsp;• *mongo*: Stop mongo server.  <br />

&nbsp; &nbsp;• *nginx*: Stop nginx server.  <br />

&nbsp; &nbsp;• *Clarive web server*: Stop web server, options can be sent as arguments to the command to stop web server in some way.  <br />

&nbsp; &nbsp;• *Clarive dispatcher*: Stop dispatcher server, options can be sent as arguments to the command to stop dispatcher in some way.  <br />


<br/>

* This command supports some options. They are: <br />


&nbsp; &nbsp;• `--no_mongo`: To not stop mongo server. <br />

&nbsp; &nbsp;• `--redis`: To stop redis server. <br />

&nbsp; &nbsp;• `--no_nginx`: To not stop nginx server.

