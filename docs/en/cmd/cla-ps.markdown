---
title: cla ps - Process monitoring
index: 5000
icon: console
---

`cla ps`: List processes directly related to Clarive services (pid files), classified depending on the type of process, it can be processes of:

- Jobs
- Dispatcher
- Server

The output displayed has the following columns: PID, PPID, CPU, MEM, STAT, START, COMMAND.

This command has a subcommand that can be displayed through the help option:

        >cla help ps

        usage: cla [-h] [-v] [--config file] command <command-args>

        Subcommands available for ps (list server processes):

        ps-filter
        cla help <command> to get all subcommands.
        cla <command> -h for command options.

`cla ps-filter`: List all processes related to server and dispatcher.
