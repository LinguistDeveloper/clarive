---
title: cla config - Configuration tool
icon: console
---

`cla config`:  Tool for generate a custom config file or display the config and opts parameters.

Running alone, this command **asks the user to generate a custom configuration file*
through a template.

This template can be defined:

- As an argument passed through the command line as following: `--template <template file>`.

- If no argument is passed, the template is located in `$CLARIVE_HOME/config/clarive.yml.template`. 

After executing, it asks **some questions about some configuration parameters**, these are:

- `host`: Name of the instance that identifies the server.

- `web host`: Host added to published urls in emails.

- `web port`: Port added to published urls in emails and the interface.

- `site_key`: A random key used to encrypt passwords.

- `default theme`.

-  `time_zone_offset`: To establish time zone.

After answering all these questions **a configuration file is created*
in `$CLARIVE_HOME/config` directory. It is  called:

- `<$env>.yml`: If an option has been passed as an argument in the form: `--env <environment_name>` .

- `<$CLARIVE_ENV>.yml.`:If no env argument is passed.


This command has three different subcommands that can be displayed through the help option:

        > cla help config

        usage: cla [-h] [-v] [--config file] command <command-args>

        Subcommands available for config (show all inherited config & options):
        config-show
        config-opts
        config-gen

        cla help <command> to get all subcommands.
        cla <command> -h for command options


`cla config-show`: this command shows all configuration parameters defined in the following configuration files:

      - `clarive.yml`.
      - `global.yml`.


File defined in option `--env` passed as argument in the command call with yml extension, or file `$CLARIVE_ENV` with yml extension.

With the option `--key <parameter>`, the output shows only the parameters defined in <parameter> field.

`cla config-opts`: this command shows:

      - All configuration parameters from the config files mentioned above.

      - Some key configuration parameters from the environment.

      - Arguments passed through command line.


`cla config-gen`: Same behavior as cla config.

