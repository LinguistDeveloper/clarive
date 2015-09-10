---
title: Run a Remote Script
---

Execute a remote script and rollback if needed. Associate server agent will execute the script. Form to configure has the following fields:         

* **server**: server that holds the remote file, server to connect to.    

* **user**: user allowed to connect to remote server.    

* **path**: path where script to run is located.    

* **arguments**: list of input parameters script is waiting for.    

* **home**: directory from which the local script is launched.    

* **Errors and output**: These two fields are related to manage control errors. Options are:    

      &nbsp; &nbsp; • fail and output error:  search for configurated error pattern in script output. If found, an error message is displayed in monitor showing the match.    

      &nbsp; &nbsp; • warn and output warn: search for configurated warning pattern in script output. If found, an error message is displayed in monitor showing the match.    

      &nbsp; &nbsp; • custom: In case combo box errors is set to custom a new form is showed to define the behavior with these fields:    
   
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - ok: range of return code values for the script to have succeeded. No message will be displayed in monitor.    

    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - warn: range of return code values to warn the user. A warn message will be displayed in monitor.    

    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - Error: range of return code values for the script to have failed. An error message will be displayed in monitor.     

