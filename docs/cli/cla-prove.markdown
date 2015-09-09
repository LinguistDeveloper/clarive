---
title: cla prove - run internal testing
---

`cla-prove`: run system tests and check. This command executes test files located in the 
directory and throws results to the screen. Each test case starts with 

====> `[start] <test case name>`  

and finalize with

====> `[end] <test case name> [<duration of the test>]`
 
in case of error the output shows the error message in red.

This command accepts the following options:

* `-- type <directory>`: Passed as an argument to the command, executes only the tests defined under …/t/< directory >.    

* `-- case <test_name>`: Executes only test <test_name>.

This command has a subcommand that can be displayed through the help option

    >cla help prove

    Clarive|Software - Copyright (c) 2013 VASSLabs

    usage: cla [-h] [-v] [--config file] command <command-args>

    Subcommands available for prove (run system tests and check):

        prove-startup

    cla help <command> to get all subcommands.
    cla <command> -h for command options.

<br/>

* `cla prove-startup`:  Test  all systems involved in Clarive startup. Output shows Clarive release and version, patched installed, startup time and a message indicating if there has been any error or all system are ready.

