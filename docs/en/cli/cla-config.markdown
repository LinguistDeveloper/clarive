---
title: cla config - Configuration tool
icon: console
---

<img src="/static/images/icons/console.png" /> `cla config`:  Tool for generate a custom config file or display the config and opts parameters. 

* Running alone, this command **asks the user to generate a custom configuration file** through a template.

* This template can be defined:  <br />
     
&nbsp; &nbsp; • As an argument passed through the command line as following: `--template <template file>`. <br />

&nbsp; &nbsp; • If no argument is passed, the template is located in `$CLARIVE_HOME/config/clarive.yml.template`.

 <br/>

* After executing, it asks **some questions about some configuration parameters**, these are: <br />


&nbsp; &nbsp;• `host`: Name of the instance that identifies the server. <br />

&nbsp; &nbsp;• `web host`: Host added to published urls in emails. <br />

&nbsp; &nbsp;• `web port`: Port added to published urls in emails and the interface. <br />

&nbsp; &nbsp;• `site_key`: A random key used to encrypt passwords. <br />

&nbsp; &nbsp;• `default theme`.  <br />

&nbsp; &nbsp;•  `time_zone_offset`: To establish time zone.


<br/>


* After answering all these questions **a configuration file is created** in `$CLARIVE_HOME/config` directory. It is  called: <br />

&nbsp; &nbsp; • `<$env>.yml`: If an option has been passed as an argument in the form: `--env <environment_name>` . <br />

&nbsp; &nbsp; • `<$CLARIVE_ENV>.yml.`:If no env argument is passed.

 <br />

* This command has three different subcommands that can be displayed through the help option:
            
        > cla help config

        Clarive|Software - Copyright (c) 2013 VASSLabs

        usage: cla [-h] [-v] [--config file] command <command-args>

        Subcommands available for config (show all inherited config & options):
        config-show
        config-opts
        config-gen

        cla help <command> to get all subcommands.
        cla <command> -h for command options

<br/>

* `cla config-show`: this command shows all configuration parameters defined in the following configuration files:  <br />

      &nbsp; &nbsp; • `clarive.yml`. <br />
      &nbsp; &nbsp; • `global.yml`.

<br/>

* File defined in option `--env` passed as argument in the command call with yml extension, or file `$CLARIVE_ENV` with yml extension.


* With the option `--key <parameter>`, the output shows only the parameters defined in <parameter> field.    


* `cla config-opts`: this command shows: <br />

      &nbsp; &nbsp; • All configuration parameters from the config files mentioned above. <br />

      &nbsp; &nbsp; • Some key configuration parameters from the environment. <br />

      &nbsp; &nbsp; • Arguments passed through command line.

<br/>

* `cla config-gen`: Same behavior as cla config.

