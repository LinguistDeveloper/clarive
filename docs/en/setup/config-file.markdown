---
title: Clarive Configuration File
index: 500
---

The Clarive configuration file is an
user-customized [YAML](concepts/yaml) file that contains installation specific
parameters.

## Environments and --env

The configuration file is also called **configuration environment file** in
Clarive, and designated as `[env].yml` in this manual.

Everytime we start a Clarive process from the command-line, or install
a Windows service, we define a configuration environment by referring
to a configuration filename.

For example, to start the Clarive Web Server:

   cla web-start --env [env].yml

## Configuration Variables

These are the configuration parameters (or keys)
that can be set in a config file.

They can be set also in the command-line,
using the `--parameter value` command-line format.

For examples on how to create or set certain values,
please refer to the Clarive product configuration
file, located at `CLARIVE_HOME/config/config.yml`.
**Do not change this file, as it may be overwritten
by upgrades or patches**

### tmp_dir

Directory location for temporary files.

By default it is set to `CLARIVE_HOME/tmp`.

### log_dir

Directory location for Clarive log files,
such as web server and dispatcher logs.

By default it is set to `CLARIVE_HOME/log`.

### job_dir

Directory location for jobs.

### pid_dir

Directory location for pid and process
pid and lock files (`.pid` and `.lock`).

### debug

Set this value to 1 or greater to start Clarive
processes in debug mode. The higher the value,
the greater the number of debug messages and verbosity.

### mongo

The `mongo:` configuration section is
described [separately in the MongoDB installation document](setup/mongo).

