---
title: cla web - Web server management
index: 5000
icon: console
---

`cla web` Performs operations related to Clarive web service.

By itself it starts Clarive web service.

Supports the following options:

`--env <environment>` Used to configure parameters.

`--r` Server restarts if there is any change these locations:

- `CLARIVE_HOME/lib`
- `CLARIVE_HOME/conf`
- `features/\*/lib`, excepts changes in files located in features/#directory.

The default value is off.

`--R <location>` Server restarts if there is any change in `<location>`.

`--host <hostname>` Host or ip_adress to start web server. If not defined, host is taken from config files.

`--port <portnum>` Web port. Its default value is port 3000.

`--daemon` Web server starts as a daemon.

`--workers <workersnum>` Number of workers raised up.

`--engine [Standalone|Twiggy|Starman|Starlet]` PSGI web server. Its default value is Starman.

The web server starts in daemon way, previous log will be compress and
a cleanup log process starts, logs will be deleted depending on
the parameter log_keep that can be passed as an argument to cla web.

`--log_keep <lognumber>` Number of logs to keep in log directory.

`--log_file <logfile>` Name of log file.

Subcommands supported can be displayed with the help option:

        > cla help web

        usage: cla [-h] [-v] [--config file] command <command-args>

        Subcommands available for web (Start/Stop web server):

        web-tail
        web-start
        web-stop
        web-log
        web-restart

        cla help <command> to get all subcommands.
        cla <command> -h for command options.

`web-start` Same as cla web, describe above.

`web-stop`  Stops the web server.  This call accepts the following options:

- `--no_wait_kill` The dispatcher is killed without wait, if this option is not set, web will wait 30 seconds to shutdown.
- `--keep_pidfile` - Keeps the file containing the process pid.

`web-restart` Restart the web server  (signal ‘HUP’ 1).

`web-log` Print logfile to screen.

`web-tail` Follows log file, it accepts some arguments when called to configure the output, these are:

- `--tail [lines]` Number of lines displayed, default is 500.
- `--interval [seconds]` The initial number of seconds will be spent sleeping, before the file is first checked, default is .5.
- `--maxinterval [seconds]` The maximum number of seconds that will be spent sleeping, by default is 1.
