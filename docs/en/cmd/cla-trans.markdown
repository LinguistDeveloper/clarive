---
title: cla trans - Conversion tool
icon: console
---

`cla trans`: Conversion tool, password encryption.

Subcommands supported can be displayed with the help option:

    >cla help trans

    usage: cla [-h] [-v] [--config file] command <command-args>

    Subcommands available for trans (conversion tool, password encryption):

        trans-encrypt
        trans-password
        trans-md5

    cla help <command> to get all subcommands.
    cla <command> -h for command options.

`cla trans-password`:

      - *-u <\username>*: User name to be encrypted password is a required parameter, it can be defined as an input parameter:

      - *-p <\password>*: User password.

      - Typed from the keyboard when command asked for it.

Encryption is done using parameter decrypt_key or dec_key from config file.

`cla trans-md5`: Encrypt following MD5 algoritm. The input string can be defined:

      - *–s <\string>*: String to encrypt.

      - Typed from the keyboard when command asks for it.

`cla trans-encrypt`: Encrypt following Blowfish algorithm. Encryption is done using:

      - *--key <\key_name>*: Key to encrypt.

      - parameter *decrypt_key or *dec_key from config file.

The input string can be defined:

      - *–s <\string>*: String to encrypt.

      - Typed from the keyboard when command asks for it.
