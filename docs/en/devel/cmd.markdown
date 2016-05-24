---
title: Extending cla wth commands
---

It's posible to write programs that
extend the `cla` command with new functionality
and leverages on the Clarive Platform for accessing
agents, configuration items, and other functionality.

    cla mycommand --myoptions

## Getting started

By running the `cla` command, the list of available
commands are listed.

    $ cla
    Clarive - Copyright(C) 2010-2016 Clarive Software, Inc.

    usage: cla [-h] [-v] [--config file] command <command-args>

    Commands available:

        <service.*>  run services
        config       config & options inherited, config file generator
        db           database diff and deploy tool
        disp         Start/Stop dispatcher
        docs         Manage the Clarive Documentation
        help         This help
        init         system Initialization
        lic          license verification
        migra        run migrations
        plugin       plugin utilities
        poll         monitoring tool
        profile      print default profile
        ps           list server processes
        queue        queue management tools
        replay       Replay
        setup        run setup profile
        smoke        smoke tests
        start        start all server tasks
        stop         stop all server tasks
        trans        conversion tool, password encryption
        version      report our version
        web          Start/Stop web server
        ws           webservices toolchain

    cla help <command> to get all subcommands.
    cla <command> -h for command options.

Adding new commands is done from within a plugin.

To create a new plugin, in case you don't have one already,
run the `plugin-bootstrap` command:

    cla plugin-new --plugin myplugin

Now create a command file, let's say we want to create
the `mycmd` command, this would be the appropriate file:

    CLARIVE_BASE/plugins/myplugin/cmd/mycmd.js

A command program is just a plain JS program:

```javascript
print("Hello World");
```

### Full command configuration

Although command-line options are available,
the correct way to access the command configuration
is by calling `process.options(key)`, which retrieves
the correct configuration value from a merged, comprehensive
object, which includes:

- the global config YAML file
- the environment configuration YAML file (set with `--env`)
- the command section within the configuration file
- finally, the command line argument flags

Precedence goes from bottom to top.

The `process.options(key)` function accesses the merged
options stack.

    print( process.options('mongo.db_name') );

### Command Arguments

The command-line arguments is sent to the program
through the `process` variable:

    cla.dump( process.argv() );

You can also access the individual options as an
object, which is actually much easier to manipulate
than going though the `argv` array.

```javascript
var myoption = process.args('myoption');
print( "User entered --myoption=" + myoption );
```

