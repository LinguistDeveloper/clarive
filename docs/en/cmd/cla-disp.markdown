---
title: cla disp - Dispatcher management
index: 5000
icon: console
---

This command starts the Clarive Dispatcher.
The Dispatcher is the process in charge of starting and managing the availability
of all active daemons. To decide which daemons to start, whether they are forked
or not, and other options, the Dispatcher will use the Daemon configuration options
set by the administrator (see Daemon administration for mor info).

The Dispatcher handles the received signals and performs the appropriate operation,
every defined seconds, checking the status of each active daemon. The behavior
can be defined as the following:

- If a daemon is active in the deamons list, the dispatcher starts the service

- If daemon has been deactivate, dispatcher stops the daemon.
- If daemon has been activated, dispatcher starts the service.
- If daemon is active, checks if it is running and if not, it intends to starts the service again.

- If a daemon is active, checks if it's running and if not, it starts the service again

The frequency the dispatcher checks for daemons statuses is a configuration
parameter called `frequency` which, by default, is assigned a value of `30`
seconds.

## Subcommands

The `disp` command has several subcommands, they are:

### disp-start

Same as `cla disp`, starts the dispatcher in online mode. Use `--daemon` to
start in the background.

`--daemon`: runs the service in the background

### disp-stop

Stops the dispatcher and all managed services. This call accepts the
following options:

`--no_wait_kill`: The dispatcher is killed without wait, if this option is
  not set, the dispatcher will wait 30 seconds to shutdown.

`--keep_pidfile`: Keeps the file containing the process pid.

### disp-log

Prints logfile to screen.

### disp-tail

Tails the log file, while accepting some arguments when called to
configure the output, these are:

`--tail`: Number of lines displayed, default is 500.
`--interval`: The initial number of seconds that will be spent sleeping,
  before the file is first checked, default is .5.
