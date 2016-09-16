---
title: cla plugin - plugin helper
index: 5000
icon: console
---

This command offers options to support the Clarive
plugin system.

All of the plugin commands, just like Clarive in general,
is sensitive to the `--plugins-home` command-line option.
This option could be changed by configuration environment,
so it's good to check what plugins are availble for a Clarive
installation by running the `plugin-list` command.

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
more precisely `CLARIVE_BASE/plugins/[plugin-id]/t`.

Test output is TAP-compatible (Test Anything Protocol), which make it
compatible with severeal testing frameworks.

For more information: [https://testanything.org/ <img class='ext-link' src='static/images/icons/new_window_link.svg' />](https://testanything.org/)

#### --verbose-tests

With the verbose mode, detailed test results and
warning messages are visible in the log.

    $ cla plugin-test --verbose-tests

    /opt/clarive/plugins/cloudfoundry/t/cf-test.js ..
    ok 1
    1..1
    ok

### cla plugin-list

Lists all installed and active plugins.
This is useful to check what plugins visible
to the Clarive search path.

### cla plugin-search-path

List the current plugin home directories
in it's search order.

    $ cla plugin-search-path
    /opt/clarive/plugins
    /opt/clarive/clarive/plugins


