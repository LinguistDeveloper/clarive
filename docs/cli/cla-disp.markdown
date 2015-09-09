---
title: cla disp - dispatcher management
index: 20
---

`cla-disp`: Performs operations related to the dispatcher.

Without any option this command starts the dispatcher service which it’s in charge of starting all active daemons, the way it starts, forked or not, is taken from the service config. 
Dispatcher handles the received signals and performs the appropriate operation, every defined seconds, checks the status of each active daemon, the behaviour is as following:

* If daemon has been deactivate, dispatcher stops the daemon.
* If daemon has been activated, dispatcher starts the service.
* If daemon is active, checks if it is running and if not, it intends to starts the service again.

<br/>

The frecuency that dispatcher checks daemons status is a configuration parameter called ‘frecuency’ and by default it is assigned a value of 30 seconds.

This command support two different options, they are:

1.`-h`: displays a brief help to the screen: 
       

    >cla disp –h

    Clarive Dispatcher
      Common options:

          --daemon        forks and starts the server

    stop
      stops the server.

     restart
      restarts the server.

     log
      prints the logfile to screen.

     tail
      follows the server log file.

      
2.`-daemon`: to run the service in background.

This command has different options, they are:

* `disp-start`: Same as cla disp, describe above.

* `disp-stop`:  Stops the dispatcher and the services.  This call accepts the following options:     
  
      &nbsp; &nbsp; • `no_wait_kill` : The dispatcher is killed without wait, if this option is not set, the dispatcher will wait 30 seconds to shutdown.    
      &nbsp; &nbsp; • `keep_pidfile`: Keeps the file containing the process pid.    

* `disp-log`: print logfile to screen.    

* `disp-tail`: follows log file, it accepts some arguments when called to configure the output, these are:

      &nbsp; &nbsp; • `tail`: number of lines displayed, default is 500.     
      &nbsp; &nbsp; • `interval`:  The initial number of seconds that will be spent sleeping, before the file is first checked, default is .5.     
      &nbsp; &nbsp; • `maxinternal`: The maximum number of seconds that will be spent sleeping, by default is 1.     


