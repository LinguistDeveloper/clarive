---
title: Run a Local Script
icon: cog_java
---

<img src="/static/images/icons/cog_java.png" /> Execute a local script and rollback if needed. 

* Form to configure has the following fields: <br />

&nbsp; &nbsp;• **Path**: Path where script to run is located.<br />

&nbsp; &nbsp;• **Options**: Tab panel with the different options to manage local script. These are:<br />

&nbsp; &nbsp;&nbsp; &nbsp; • *Arguments* - List of different input parameters script is waiting for.   <br /> 

&nbsp; &nbsp;&nbsp; &nbsp; • *Environment* - Env variables needed to execute the script.     <br />

&nbsp; &nbsp;&nbsp; &nbsp; • *Output files* - Files script generates. This files are published in monitor.  <br />

&nbsp; &nbsp;• **Home**: Directory from which the local script is launched.<br />

&nbsp; &nbsp;• **Stdin** <br />

&nbsp; &nbsp;• **Output**: Tab panel to manage output script return value in case of success or failure. They can be: <br />

&nbsp; &nbsp;&nbsp; &nbsp; • *Output error* - Search for configurated error pattern in script output. If found, an error message is displayed in monitor showing the match.   <br />

&nbsp; &nbsp;&nbsp; &nbsp; • *Output warn* - Search for configurated warning pattern in script output. If found, an error message is displayed in monitor showing the match.  <br /> 

&nbsp; &nbsp;&nbsp; &nbsp; • *Output OK* - Search for configurated ok pattern in script output. If found, a message is displayed in monitor showing the match, possible errors will be ignored. <br />

&nbsp; &nbsp;&nbsp; &nbsp; • *Output captured* - Search for configurated pattern in script output. If found, expression will be added to the stash, showing a message.

