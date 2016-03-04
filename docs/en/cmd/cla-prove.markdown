---
title: cla prove - Run internal testing
icon: console
---

`cla prove`: run system tests and check.

This command executes test files located in the directory and throws results to the screen.

Each test case starts with

`[start] <test case name>`


And finalize with

`[end] <test case name> [<duration of the test>]`


In case of error the output shows the error message in red.

This command accepts the following options:

- `-- type <directory>` - Passed as an argument to the command, executes only the tests defined under …/t/< directory >.

- `-- case <test_name>` - Executes only test <test_name>.

This command has a subcommand that can be displayed through the help option

        > cla help prove

        usage: cla [-h] [-v] [--config file] command <command-args>

        Subcommands available for prove (run system tests and check)
        prove-startu

        cla help <command> to get all subcommand
        cla <command> -h for command options.


`cla prove-startup`: Test  all systems involved in Clarive startup. Output shows Clarive release and version, patched installed, startup time and a message indicating if there has been any error or all system are ready.

