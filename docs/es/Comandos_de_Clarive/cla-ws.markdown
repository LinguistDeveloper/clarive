---
title: cla ws - Invocar servicios web
icon: console
---

* `cla ws`: Herramientas REST Clarive REST. Encuentra todos los métodos públicos disponibles a un [CI](Conceptos/ci) dado.

* Se pueden pasar los siguientes parámetros: <br />
 
      &nbsp;&nbsp; • `--classname <class_name>`: Nombre de la clase CI para buscar los métodos disponibles. Por defecto el valor es '*' <br />


      &nbsp;&nbsp; • `--mid <mid>`: Mid al que pertenece el CI definido. <br />

<br />
    
* La salida muestra métodos comunes a todas las clases de CI, y los métodos disponibles para la clase CI dada.

* Los subcomandos que soporta este `cla ws` pueden ser consultados a través de la ayuda:

<br />

    >cla help ws

    Clarive - Copyright(C) 2010-2015 Clarive Software, Inc.

    usage: cla [-h] [-v] [--config file] command <command-args>

    Subcommands available for ws (webservices toolchain):

        ws-list

    cla help <command> to get all subcommands.
    cla <command> -h for command options.

<br />

* `cla ws-list`: Mismo comportamiento que `cla ws`.

