---
title: Run a Local Script
index: 5000
icon: cog-java-orange
---

Execute a local script and rollback if needed.

Form to configure has the following fields:

- **Path** - Path where script to run is located.
- **Options** - Tab panel with the different options to manage local script. These are:
   - Arguments - List of different input parameters script is waiting for.
   - Environment - Env variables needed to execute the script.
   - Output files - Files script generates. This files are published in monitor.
- **Home Directory** - Directory from which the local script is launched.
- **Stdin** - Standard input data to be sent to the script.
- **Output** - Tab panel to manage output script return value in case of success or failure. They can be:
   - Error - Search for configurated error pattern in script output.
If found, an error message is displayed in monitor showing the match.
   - Warn - Search for configurated warning pattern in script output.
If found, an error message is displayed in monitor showing the match.
   - OK - Search for configurated ok pattern in script output.
If found, a message is displayed in monitor showing the match, 
possible errors will be ignored.
  - Captured - Search for configurated pattern in script output.
If found, expression will be added to the stash, showing a message.

