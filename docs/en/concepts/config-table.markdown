---
title: Config Table
index: 5000
icon: page
---

The config table is where global __dynamic__ configuration parameters are stored in
the Clarive database.

_Dynamic configuration_ parameters are parameters that can be changed at any
moment by an administrator and that it will be reflected instantly by Clarive.

This is precisely what make these configuration values different from the
_static_ configuration parameters that are set in the [configuration
files](setup/config-file). Static values require a server or [dispatcher](admin/dispatcher)
restart.

For example, the following are some global dynamic configuration variables
that can be set through the config table:

    config.daemon.purge.frequency: 86400
    config.git.path: /opt/repository

