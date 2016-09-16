---
title: Install Directories
index: 600
icon: page
---

This document describes the
directory structure of a Clarive installation.

## The Clarive Base Directories CLARIVE_BASE

The Clarive base directory, referred to in
this manual as `CLARIVE_BASE`, is where the Clarive structure
is installed to.

The base directory contains common libraries and binaries used by Clarive, and
by default, is where the temporary and data directories are located. This can
be changed by the user through the `[env].yml` file.

#### CLARIVE_BASE in Linux, OS X and Unixes

This are the default directories of a Clarive installation:

- `jobs/` - temporary directory where jobs are written to.
- `data/` - database files are kept here by default, normally under
`data/mongo`.
- `logs/` - for server log files and `.pid` and `.lock` process files.
- `tmp/` - for temporary files and directories used mostly by the web-server.
- `config/` - directory for user configuration files `[env].yml`. This
directory is in the search path for the `--env` command-line option
for the `cla` command. MongoDB and Nginx configuration files
are kept here by default.
- `features/` - here is where user-installed product features are kept.
each subdirectory here is a feature.
- `plugins/` - here is where user-installed product plugins. Each
subdirectory is a plugin.
- `local/` - where all external libraries and binaries such as Git, OpenSSL,
  MongoDB drivers or Perl are kept.  **There are no serviceable files inside**.
- `clarive/` - the CLARIVE_HOME directory. See below.

#### CLARIVE_BASE in Windows

The CLARIVE_BASE directory in a Windows installation in contained within
more layers than in a Linux/OS X install. This is due
to the special additional structure and base software needs of a Windows System.

For reading simplicity, we assume the root install dir in Windows
is `C:\Clarive` in this manual.

- `C:\Clarive` - root installation location, where each subdirectory
is a Clarive product, such as "Server" or "Agent".
- `C:\Clarive\Server` - the Server installation
- `C:\Clarive\Server\app\` - the Cygwin root installation directory,
which emulates a \*nix root directory.
- `C:\Clarive\Server\app\opt\clarive` - the CLARIVE_BASE directory. From
here down, it matches the structure of a Linux/Unix/OSX system, so refer to
the chapter above for more information.
- `C:\Clarive\Server\bin` - special Windows binaries and other application shortcuts.

## The Clarive Home Directories CLARIVE_HOME

The Clarive home directory is where the Clarive
core software files is installed, usually under the `CLARIVE_BASE`
directory.

**There are no serviceable files inside**,
so do not change files here as they may generate errors and data corruption.

## Changing the Default Installation Directories

To change the default directories, set new values in your
[configuration environment](setup/config-file) file `[env].yml`.


