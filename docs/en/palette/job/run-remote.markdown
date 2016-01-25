---
title: Run a Remote Script
icon: cog_java
---

<img src="/static/images/icons/cog_java.png" /> Execute a remote script and rollback if needed. 
* Associate server agent will execute the script.

* Form to configure has the following fields: <br />

 &nbsp; &nbsp;• **Server**: Server that holds the remote file, server to connect to. <br />

 &nbsp; &nbsp;• **User**: User allowed to connect to remote server. <br />

 &nbsp; &nbsp;• **Path**: Path where script to run is located. <br />

 &nbsp; &nbsp;• **Arguments**: List of input parameters script is waiting for. <br />

 &nbsp; &nbsp;• **Home**: Directory from which the local script is launched. <br />

 &nbsp; &nbsp;• **Errors and output**: These two fields are related to manage control errors. Options are: <br />

&nbsp; &nbsp;&nbsp; &nbsp; • *Fail and output error* - Search for configurated error pattern in script output. If found, an error message is displayed in monitor showing the match. <br />

&nbsp; &nbsp;&nbsp; &nbsp; • *Warn and output warn* - search for configurated warning pattern in script output. If found, an error message is displayed in monitor showing the match.,<br />

&nbsp; &nbsp;&nbsp; &nbsp; • *Custom*: In case combo box errors is set to custom a new form is showed to define the behavior with these fields: <br />

&nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; • *OK* - Range of return code values for the script to have succeeded. No message will be displayed in monitor. <br />

&nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; • *Warn* - Range of return code values to warn the user. A warn message will be displayed in monitor.<br />

&nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; • *Error* - Range of return code values for the script to have failed. An error message will be displayed in monitor.

