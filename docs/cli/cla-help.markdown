---
title: cla help - Help on cla commands
index: 10
icon: console
---

<img src="/static/images/icons/console.png" /> `cla help`: Clarive has a number of command lines that can be executed to manage the application. 

* These commands are called through the command cla as follow: `cla <command><command-args>`. 


* Cla command itself has two options: <br />

&nbsp; &nbsp;• `version`: displays Clarive version. <br />

&nbsp; &nbsp;• `help`: shows the available command. Help output can be accessed through the option `–h` as well.

<br/>

* Cla command is in charge of collecting all configuration data from config files, environment and arguments passed through the command line before running the command call itself.
 
* In order to describe every command, let’s show the output of cla help:
            
        > cla help

        Clarive|Software - Copyright (c) 2013 VASSLabs

        usage: cla [-h] [-v] [--config file] command <command-args>

        Commands available:
        <service.*>       run Baseliner services
        config            show all inherited config & options
        db                database diff and deploy tool
        disp              Start/Stop dispatcher
        help              This help
        install           config file generator
        lic               license verification
        poll              monitoring tool
        prove             run system tests and check
        ps                list server processes
        queue             queue management tools
        start             start all server tasks
        stop              stop all server tasks
        trans             conversion tool, password encryption
        version           report our version
        web               Start/Stop web server
        ws                webservices toolchain

        cla help <command> to get all subcommands.
        cla <command> -h for command options.


<br/>

* A common option to all this cla commands is the option `-v` (verbose) to activate the verbose mode and display all the user environment and command arguments. 


