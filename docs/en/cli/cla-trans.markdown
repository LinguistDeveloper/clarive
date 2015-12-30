---
title: cla trans - Conversion tool
icon: console
---

<img src="/static/images/icons/console.png" /> `cla trans`: Conversion tool, password encryption. 

* Subcommands supported can be displayed with the help option:

<br/>

    >cla help trans
    Clarive|Software - Copyright (c) 2013 VASSLabs

    usage: cla [-h] [-v] [--config file] command <command-args>

    Subcommands available for trans (conversion tool, password encryption):

        trans-encrypt
        trans-password
        trans-md5

    cla help <command> to get all subcommands.
    cla <command> -h for command options.
  
 
<br/>

* `cla trans-password`: <br />

    
      &nbsp; &nbsp;• *-u <\username>*: User name to be encrypted password is a required parameter, it can be defined as an input parameter: <br />

      &nbsp; &nbsp;• *-p <\password>*: User password. <br />

      &nbsp; &nbsp;• Typed from the keyboard when command asked for it. <br />

<br />

* Encryption is done using parameter decrypt_key or dec_key from config file. <br />

<br/>

* `cla trans-md5`: Encrypt following MD5 algoritm. The input string can be defined: <br />

      &nbsp; &nbsp;• *–s <\string>*: String to encrypt. <br />

      &nbsp; &nbsp;• Typed from the keyboard when command asks for it. <br />

<br/>

* `cla trans-encrypt`: Encrypt following Blowfish algorithm. Encryption is done using: <br />


      &nbsp; &nbsp;• *--key <\key_name>*: Key to encrypt. <br />

      &nbsp; &nbsp;• parameter *decrypt_key* or *dec_key* from config file. <br />

<br/>

* The input string can be defined: <br />


      &nbsp; &nbsp;• *–s <\string>*: String to encrypt. <br />

      &nbsp; &nbsp;• Typed from the keyboard when command asks for it.

