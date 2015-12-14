---
title: Daemon Administration
icon: daemon.gif
---

* A daemon is a computer program that runs as a background process, rather than being under the direct control of an interactive user. 

* In Clarive, daemons are special, independent background processes started by the [Dispatcher](admin/dispatcher). 

* Daemons are critical to the correct operation of Clarive, including: <br />

&nbsp; &nbsp;• Job execution <br />
&nbsp; &nbsp;• Event processing <br />
&nbsp; &nbsp;• [Notifications](admin/notifications) <br />
&nbsp; &nbsp;• [Scheduled](admin/scheduler) Executions <br />
&nbsp; &nbsp;• Semaphore control

* Accessing the Daemon administration in the Admin Menu: <img class="bali-topic-editor-image"  src="/static/images/daemon.gif" /> Daemons

* In the daemon screen, we can see what daemons are started at a given point in time. 

* These are the standard, out-of-the box daemons that should be running in any typical Clarive installation. <br />

&nbsp; &nbsp;• `service.daemon.email` - Daemon responsible for sending notifications. <br />
&nbsp; &nbsp;• `service.event.daemon` - Daemon responsible for the management of events. <br />
&nbsp; &nbsp;• `service.job.daemon` - Daemon responsible for the execution of passes. <br />
&nbsp; &nbsp;• `service.purge.daemon` - Daemon responsible for the purge. <br />
&nbsp; &nbsp;• `service.schedule daemon` - Responsible for planning. <br />
&nbsp; &nbsp;• `service.sem.daemon` - Daemon responsible for controlling traffic lights.


<br />
### Start / Stop

* If at any time we're not interested that a particular service is run, for example purge the demon, we can disable it from this screen.

* Actions associated with the buttons on the toolbar: 

<img class="bali-topic-editor-image" src="/static/images/start.gif" /> **Start**: Run a daemon that has been stopped 

<img src="/static/images/stop.gif" /> **Stop**: Stop a running daemon

<img src="/static/images/icons/add.gif" /> **Create**: Create new daemon attached to the Dispatcher

<img src="/static/images/icons/edit.gif" /> **Edit**: Modify the configuration for existing daemons

<img src="/static/images/icons/delete.gif" /> **Delete**: Delete an existing daemon.




