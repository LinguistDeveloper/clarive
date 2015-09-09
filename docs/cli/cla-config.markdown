---
title: cla config - configuration tool
---

`cla config`:  Tool for generate a custom config file or display the config and opts parameters. Running alone, this command **asks the user to generate a custom configuration file** through a template. This template can be defined: 
     
  &nbsp;  &nbsp; &nbsp;  &nbsp; &nbsp; • As an argument passed through the command line as following: `--template <template file>`.     
  &nbsp;  &nbsp; &nbsp;  &nbsp; &nbsp; • If no argument is passed, the template is located in `$CLARIVE_HOME/config/clarive.yml.template`.       

 
After executing, it asks **some questions about some configuration parameters**, these are:    

* `host`: Name of the instance that identifies the server.
* `web host`: host added to published urls in emails.
* `web port`: port added to published urls in emails and the interface.
* `site_key`: a random key used to encrypt passwords.    
* `default theme`.  
* `time_zone_offset`: To establish time zone.

<br/>
After answering all these questions **a configuration file is created** in `$CLARIVE_HOME/config` directory. It is  called:    
&nbsp; &nbsp; • `<$env>.yml`: if an option has been passed as an argument in the form: `--env <environment_name>` .          
&nbsp; &nbsp; • `<$CLARIVE_ENV>.yml.`:if no env argument is passed.      

This command has three different subcommands that can be displayed through the help option

    >cla help config

    Clarive|Software - Copyright (c) 2013 VASSLabs

    usage: cla [-h] [-v] [--config file] command <command-args>

    Subcommands available for config (show all inherited config & options):

    config-show
    config-opts
    config-gen

    cla help <command> to get all subcommands.
    cla <command> -h for command options
<br/>    

* `cla config-show`: this command shows all configuration parameters defined in the following configuration files: 

      &nbsp; &nbsp; • `clarive.yml`.     
      &nbsp; &nbsp; • `global.yml`.     

File defined in option `--env` passed as argument in the command call with yml extension, or file `$CLARIVE_ENV` with yml extension.

With the option `--key <parameter>`, the output shows only the parameters defined in <parameter> field.    
<br/>

* `cla config-opts`: this command shows:

      &nbsp; &nbsp; • all configuration parameters from the config files mentioned above.    
      &nbsp; &nbsp; • some key configuration parameters from the environment.    
      &nbsp; &nbsp; • arguments passed through command line.        
<br/>

* `cla config-gen`: Same behavior as cla config.

