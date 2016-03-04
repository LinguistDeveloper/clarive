---
title: Daemon Administration
index: 2
icon: daemon.gif
---

A daemon is a computer program that runs as a background process,
rather than being under the direct control of an interactive user.

In Clarive, daemons are special, independent background processes
started by the [Dispatcher](admin/dispatcher).

Daemons are critical to the correct operation of Clarive, including:

- Job execution

- Event processing

- [Notifications](admin/notifications)

- [Scheduled](admin/scheduler) Executions

- Semaphore control

Accessing the Daemon administration in the Admin Menu: <img class="bali-topic-editor-image"  src="/static/images/daemon.gif" /> Daemons

In the daemon screen, we can see what daemons are started at a given point in time.

These are the standard, out-of-the box daemons that should be running in any typical Clarive installation.

- `service.daemon.email` - Daemon responsible for sending notifications.

- `service.event.daemon` - Daemon responsible for the management of events.

- `service.job.daemon` - Daemon responsible for the execution of passes.

- `service.purge.daemon` - Daemon responsible for the purge.

- `service.schedule daemon` - Responsible for planning.

- `service.sem.daemon` - Daemon responsible for controlling traffic lights.

### Start / Stop

If at any time we're not interested that a particular service is run,
for example purge the demon, we can disable it from this screen.

Actions associated with the buttons on the toolbar:

<img src="/static/images/icons/add.gif" /> **Create**: Create new daemon attached to the Dispatcher.

<img src="/static/images/icons/edit.gif" /> **Edit**: Modify the configuration for existing daemons

<img src="/static/images/icons/delete.gif" /> **Delete**: Delete an existing daemon.

<img src="/static/images/icons/start.png" /> **Start**: Run a daemon that has been stopped.

<img src="/static/images/icons/stop.png" /> **Stop**: Stop a running daemon.

