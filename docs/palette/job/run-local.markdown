---
title: Run a Local Script
---

Execute a local script and rollback if needed. Form to configure has the following fields:     

* **path**: path where script to run is located.      

* **options**: tab panel with the different options to manage local script. These are:     

      &nbsp; &nbsp; • arguments: list of different input parameters script is waiting for.     
      &nbsp; &nbsp; • environment: Env variables needed to execute the script.     
      &nbsp; &nbsp; • output files: files script generates. This files are published in monitor.     

* **home**: directory from which the local script is launched.     

* **stdin**     

* **Output**: tab panel to manage output script return value in case of success or failure. They can be:         

      &nbsp; &nbsp; • output error: search for configurated error pattern in script output. If found, an error message is displayed in monitor showing the match.        

      &nbsp; &nbsp; • output warn: search for configurated warning pattern in script output. If found, an error message is displayed in monitor showing the match.    

      &nbsp; &nbsp; • output ok: search for configurated ok pattern in script output. If found, a message is displayed in monitor showing the match, possible errors will be ignored.    

      &nbsp; &nbsp; • output captured: search for configurated pattern in script output. If found, expression will be added to the stash, showing a message.    

