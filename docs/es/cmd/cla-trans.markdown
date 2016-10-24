---
title: cla trans - Herramienta de conversion
icon: console
---
* `cla trans`: Herramienta de conversion para encriptar contraseñas.
* Los subcomandos disponibles se pueden visualizar con la ayuda:

    >cla help trans
    Clarive - Copyright(C) 2010-2015 Clarive Software, Inc.


    usage: cla [-h] [-v] [--config file] command <command-args>

    Subcommands available for trans (conversion tool, password encryption):

        trans-encrypt
        trans-password
        trans-md5

    cla help <command> to get all subcommands.
    cla <command> -h for command options.
  
 

* `cla trans-password`:

Nombre de usuario para ser encriptada contraseña es un parámetro requerido, puede ser definido como un parámetro de entrada:
    *-u <\nombre_usuario>*: Nombre de usuario al que se le encriptará la contraseña. Se trata de un parámetro obligatorio y puede ser definido por:
    *-p <\contraseña>*: La contraseña del usuario.
    Escrita desde el teclado cuando el comando lo pida.


* El cifrado se realiza mediante el parámetro decrypt_key o dec_key del archivo de configuración.


* `cla trans-md5`: Encripta la contraseña utilizando el algoritmo MD5. Se puede generar de dos maneras:
    *–s <\string>*: Cadena de caracteres a encriptar.

Escribir la contraseña desde el teclado cuando el comando lo pida.


* `cla trans-encrypt`: Encripta la contraseña utilizando el algoritmo Blowfish. El cifrado se realiza utilizando:
    *--key <\key_name>*: Clave para encriptar.

Parámetro *decrypt_key* o *dec_key* del fichero de configuración.