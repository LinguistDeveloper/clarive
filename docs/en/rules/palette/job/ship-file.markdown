---
title: Ship File Remotely
icon: file.gif
---

Get files from a remote site according to user options from the configuration window.

Form to configure has the following fields:

**Server**: Server that holds the remote file, server to connect to.

**User**: User allowed to connect to remote server.

**Recursive**: Get files in a recursive way through directories behind base path.

**Local mode**: Specifies what files are part of the list to get from remote server. They can be:

- Local files: All files found.

- Nature items: Files involved in current nature.

- Exist Mode Local: Choose kill the process if the file does not exist.

**Rel mode**: Relative path to place files in local server. Options are:

- File only: To take only file names.

- Rel path job: Files path relative to job dir.

- Rel path anchor: Files path relative to a path configured by the user.

**Anchor path**: Path to anchor files relative path.

**Remote path**: Path in remote server to get files to ship to the local server.
