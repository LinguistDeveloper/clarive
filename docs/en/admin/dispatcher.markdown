---
title: Dispatcher
index: 5000
icon: daemon
---

The dispatcher is the process responsible for keeping all the Clarive [daemons](admin/daemon) started and running.  

If a daemon fails to run or stops running, the dispatcher will take care of restarting the process.  

The dispatcher can be started in one or more servers, where it will control server process affinity, failover and load-balancing. 
