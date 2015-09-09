---
title: cla trans - conversion tool
---

`cla trans`: conversion tool, password encryption. Subcommands supported can be displayed with the help option:

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

* `cla trans-password`:       
    
      &nbsp; &nbsp; • `-u <username>`: User name to be encrypted password is a required parameter, it can be defined as an input parameter:      
      &nbsp; &nbsp; • `-p <password>`: User password.     
      &nbsp; &nbsp; • Typed from the keyboard when command asked for it.     
Encryption is done using parameter decrypt_key or dec_key from config file.     
<br/>
* `cla trans-md5`:  Encrypt following MD5 algoritm. The input string can be defined:    

      &nbsp; &nbsp; • `–s <string>`: String to encrypt.     
      &nbsp; &nbsp; • Typed from the keyboard when command asks for it.    

* `cla trans-encrypt`: Encrypt following Blowfish algorithm. Encryption is done using:

      &nbsp; &nbsp; • `--key <key_name>`: Key to encrypt.    
      &nbsp; &nbsp; • parameter decrypt_key or dec_key from config file.
<br/>
* The input string can be defined:    

      &nbsp; &nbsp; • `–s <string>`: String to encrypt.     
      &nbsp; &nbsp; • Typed from the keyboard when command asks for it.

