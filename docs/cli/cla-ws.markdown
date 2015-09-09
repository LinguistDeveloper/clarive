---
title: cla ws - invoke webservices
---

* `cla ws`: Clarive REST tools. It finds all public methods available to a given CI. It supports two input options:   
 
      &nbsp; &nbsp; • `--classname <class_name>`:  CI class name to find available methods. Its default value is ‘*’. 
   
      &nbsp; &nbsp; • `--mid <mid>`: mid belonging to a defined CI.
    
The output shows  common methods to all CI classes, and the methods available to the given CI class.

Subcommands supported can be displayed with the help option

    >cla help ws

    Clarive|Software - Copyright (c) 2013 VASSLabs

    usage: cla [-h] [-v] [--config file] command <command-args>

    Subcommands available for ws (webservices toolchain):

        ws-list

    cla help <command> to get all subcommands.
    cla <command> -h for command options.

<br/>    

* `cla ws-list`: Same behavior as cla ws.

