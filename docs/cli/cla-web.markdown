---
title: cla web - web server management
index: 10
---

`cla web`: Performs operations related to Clarive web service. By itself it starts Clarive web service. It supports the following options:

* `--env <environment>`: Used to configure parameters.

* `--r`: Server restarts if there is any change in locations

      &nbsp; &nbsp; • `lib`.    
      &nbsp; &nbsp; • `*conf`.    
      &nbsp; &nbsp; • `features/*/lib`, excepts changes in files located in features/#* directory.    

Its default value is 0.

* `--R <location>`: Server restarts if there is any change in `<location>`.   

* `--host <hostname>`: host or ip_adress to start web server. If not defined, host is taken from config files. 

* `--port <portnum>`: web port. Its default value is port 3000.

* `--daemon`: Web server starts as a daemon.

* `--workers <workersnum>`: Number of workers raised up.

* `--engine [Standalone|Twiggy|Starman|Starlet]`: PSGI web server. Its default value is Starman.

If web server starts in daemon way, previous log will be compress and a cleanup log process starts, logs will be deleted depending on the parameter log_keep that can be passed as an argument to cla web.

* `--log_keep <lognumber>`: Number of logs to keep in log directory.

* `--log_file <logfile>`: Name of log file.

Subcommands supported can be displayed with the help option

    >cla help web
    Clarive|Software - Copyright (c) 2013 VASSLabs

    usage: cla [-h] [-v] [--config file] command <command-args>

    Subcommands available for web (Start/Stop web server):

        web-tail
        web-start
        web-stop
        web-log
        web-restart

    cla help <command> to get all subcommands.
    cla <command> -h for command options.  


* `web-start`: Same as cla web, describe above.    

* `web-stop`:  Stops the web server.  This call accepts the following options:    

      &nbsp; &nbsp; • `no_wait_kill`: The dispatcher is killed without wait, if this option is not set, web will wait 30 seconds to shutdown.    
      &nbsp; &nbsp; • `keep_pidfile`: Keeps the file containing the process pid.    

* `web-restart`: Restart the web server  (signal ‘HUP’ 1).    

* `web-log`: print logfile to screen.    

* `web-tail`: follows log file, it accepts some arguments when called to configure the output, these are: 
   
      &nbsp; &nbsp; • `tail`: number of lines displayed, default is 500.    
      
      &nbsp; &nbsp; • `interval`:  The initial number of seconds will be spent sleeping, before the file is first checked, default is .5.
   
      &nbsp; &nbsp; • `maxinternal`: The maximum number of seconds that will be spent sleeping, by default is 1.    

