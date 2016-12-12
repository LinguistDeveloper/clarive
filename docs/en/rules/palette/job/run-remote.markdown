---
title: Run a Remote Script
index: 5000
icon: cog_java
---

Execute a remote script and rollback if needed.

Associate server agent will execute the script.

Form to configure has the following fields:

- **Server** - Server that holds the remote file, server to connect to.
- **User** - User allowed to connect to remote server.
- **Command** - Commands to be executed in Server.
- **Arguments** - List of input parameters script is waiting for.
- **Environments** - List of variables that can be use in Command field.
- **Home directory** - Directory from which the local script is launched.
- **Errors and output** - These two fields are related to manage control errors. Options are:
   - Fail and output error - Search for configurated error pattern in script output. If found, an error message is displayed in monitor showing the match.
   - Warn and output warn - Search for configurated warning pattern in script output. If found, an error message is displayed in monitor showing the match.,
   - Custom - In case combo box errors is set to custom a new form is showed to define the behavior with these fields:
   - OK - Range of return code values for the script to have succeeded. No message will be displayed in monitor.
   - Warn - Range of return code values to warn the user. A warn message will be displayed in monitor.
   - Error - Range of return code values for the script to have failed. An error message will be displayed in monitor.

