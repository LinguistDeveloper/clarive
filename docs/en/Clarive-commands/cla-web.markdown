---
title: cla web - Web server management
index: 10
icon: console
---

<img src="/static/images/icons/console.png" />  `cla web`: Performs operations related to Clarive web service. 

* By itself it starts Clarive web service. 

* Supports the following options: <br />

&nbsp; &nbsp;• `--env <environment>`: Used to configure parameters. <br />

&nbsp; &nbsp;• `--r`: Server restarts if there is any change in locations. <br />

&nbsp; &nbsp;&nbsp;&nbsp;• *lib*. <br />

&nbsp; &nbsp;&nbsp;&nbsp;• *conf*. <br />

&nbsp; &nbsp;&nbsp;&nbsp;• *features/\*/lib*, excepts changes in files located in features/#* directory. <br />

&nbsp; &nbsp;&nbsp; &nbsp; Its default value is 0.


&nbsp; &nbsp;• `--R <location>`: Server restarts if there is any change in `<location>`. <br />

&nbsp; &nbsp;• `--host <hostname>`: Host or ip_adress to start web server. If not defined, host is taken from config files.  <br />

&nbsp; &nbsp;• `--port <portnum>`: Web port. Its default value is port 3000. <br />

&nbsp; &nbsp;• `--daemon`: Web server starts as a daemon. <br />

&nbsp; &nbsp;• `--workers <workersnum>`: Number of workers raised up. <br />

&nbsp; &nbsp;• `--engine [Standalone|Twiggy|Starman|Starlet]`: PSGI web server. Its default value is Starman. <br />

&nbsp; &nbsp; If web server starts in daemon way, previous log will be compress and a cleanup log process starts, logs will be deleted depending on the parameter log_keep that can be passed as an argument to cla web.

&nbsp; &nbsp;• `--log_keep <lognumber>`: Number of logs to keep in log directory. <br />

&nbsp; &nbsp;• `--log_file <logfile>`: Name of log file. <br />

* Subcommands supported can be displayed with the help option:
            
        > cla help web

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
    

<br />
&nbsp; &nbsp;• `web-start`: Same as cla web, describe above. <br />

&nbsp; &nbsp;• `web-stop`:  Stops the web server.  This call accepts the following options: <br />

&nbsp; &nbsp;&nbsp; &nbsp;• *no_wait_kill* - The dispatcher is killed without wait, if this option is not set, web will wait 30 seconds to shutdown. <br />

&nbsp; &nbsp;&nbsp; &nbsp;• *keep_pidfile*: - Keeps the file containing the process pid. <br />

&nbsp; &nbsp;• `web-restart`: Restart the web server  (signal ‘HUP’ 1). <br />

&nbsp; &nbsp;• `web-log`: Print logfile to screen. <br />

&nbsp; &nbsp;• `web-tail`: Follows log file, it accepts some arguments when called to configure the output, these are:  <br />
   
&nbsp; &nbsp;&nbsp; &nbsp;• *tail* - Number of lines displayed, default is 500. <br />
      
&nbsp; &nbsp;&nbsp; &nbsp;• *interval* - The initial number of seconds will be spent sleeping, before the file is first checked, default is .5. <br />
   
&nbsp; &nbsp;&nbsp; &nbsp;• *maxinternal* - The maximum number of seconds that will be spent sleeping, by default is 1. <br /> 

