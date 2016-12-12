---
title: Ship File Remotely
index: 5000
icon: service-fileman-ship
---

Get files from a remote site according to user options from the configuration window.

Form to configure has the following fields:

- **Server** - Server that holds the remote file, server to connect to.
- **User** - User allowed to connect to remote server.
- **Recursive** - Get files in a recursive way through directories behind base path.
- **Local mode** - Specifies what files are part of the list to get from remote server.They can be:
   - Local files - All files found.
   - Nature items - Files involved in current nature.
   - Exist Mode Local - Choose kill the process if the file does not exist.
- **Rel mode** - Relative path to place files in local server. Options are:
   - File only - To take only file names.
   - Rel path job - Files path relative to job dir.
   - Rel path anchor - Files path relative to a path configured by the user.
- **Anchor path** - Path to anchor files relative path.
- **Remote path** - Path in remote server to get files to ship to the local server.
- **Exist Mode Remote** - Set the behaviour when the file exists in remote path.
- **Backup Mode** - To make a backup of the file.
- **Rollback Mode** - Select the action of this service when the rule executed rollback.
- **Chown** - Set the owner of the file.
- **Chmod** - Set the permissions of the file.
- **Max Transfer Chunk Size** - Allow to chunk the file sending small chunks. Set the chunk size in KB.
- **Copy File Attributes** - Check if you want to copy also file attributes.
- **Filters** - Allow to add filters to the directory.