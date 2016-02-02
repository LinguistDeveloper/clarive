---
title: cla trans - Herramienta de conversion
icon: console
---

* `cla trans`: Herramienta de conversion para encriptar contraseñas.

* Los subcomandos disponibles se pueden visualizar con la ayuda:

<br/>

    >cla help trans
    Clarive - Copyright(C) 2010-2015 Clarive Software, Inc.


    usage: cla [-h] [-v] [--config file] command <command-args>

    Subcommands available for trans (conversion tool, password encryption):

        trans-encrypt
        trans-password
        trans-md5

    cla help <command> to get all subcommands.
    cla <command> -h for command options.
  
 
<br/>

* `cla trans-password`: <br />

Nombre de usuario para ser encriptada contraseña es un parámetro requerido, puede ser definido como un parámetro de entrada:

&nbsp; &nbsp;• *-u <\nombre_usuario>*: Nombre de usuario al que se le encriptará la contraseña. Se trata de un parámetro obligatorio y puede ser definido por: <br />

&nbsp; &nbsp;&nbsp; &nbsp;• *-p <\contraseña>*: La contraseña del usuario. <br />

&nbsp; &nbsp;&nbsp; &nbsp;• Escrita desde el teclado cuando el comando lo pida. <br />

<br />

* El cifrado se realiza mediante el parámetro decrypt_key o dec_key del archivo de configuración. <br />

<br/>

* `cla trans-md5`: Encripta la contraseña utilizando el algoritmo MD5. Se puede generar de dos maneras: <br />

      &nbsp; &nbsp;• *–s <\string>*: Cadena de caracteres a encriptar. <br />

      &nbsp; &nbsp;• Escribir la contraseña desde el teclado cuando el comando lo pida. <br />

<br/>

* `cla trans-encrypt`: Encripta la contraseña utilizando el algoritmo Blowfish. El cifrado se realiza utilizando: <br />

      &nbsp; &nbsp;• *--key <\key_name>*: Clave para encriptar. <br />

      &nbsp; &nbsp;• Parámetro *decrypt_key* o *dec_key* del fichero de configuración. <br />