---
title: cla ws - Invoke webservices
index: 5000
icon: console
---

`cla ws`: Clarive REST tools. It finds all public methods available to a given CI.

It supports two input options:

`--classname <class_name>`: CI class name to find available methods. Its default value is "\*".

`--mid <mid>`: Mid belonging to a defined CI.

The output shows common methods to all CI classes, and the methods available to the given CI class.

Subcommands supported can be displayed with the help option:

    > cla help ws

    usage: cla [-h] [-v] [--config file] command <command-args>

    Subcommands available for ws (webservices toolchain):

        ws-list

    cla help <command> to get all subcommands.
    cla <command> -h for command options.

`cla ws-list`: Same behavior as cla ws.

