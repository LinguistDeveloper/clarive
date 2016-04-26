---
title: cla plugin - plugin helper
---

This command offers options that support the Clarive
plugin system.


### cla plugin-new --plugin [plugin-id]

Bootstrap a new plugin, creating the
placeholder folder structure for developing plugins.

You're are not required to run this program to
develop plugins, it's just a good way to avoid
having to create the necessary files from zero.

    cla plugin-new --plugin myplugin

Will typically create the following plugin
home folder:

    CLARIVE_BASE/plugins/myplugin/...

### cla plugin-test [partial-name-or-dir]

Tests plugins by running the test cases
contained in each and every plugin `t` directory,
more precisely CLARIVE_BASE/plugins/[plugin-id]/t

### cla plugin-list

Lists all installed plugins.
