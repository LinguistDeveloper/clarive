---
title: cla help - Ayuda de los comandos
index: 10
icon: console.svg
---
* `cla help`: Clarive dispone de una serie de comandos que pueden ser ejecutados para poder administrar correctamente la aplicación.
* Estos comandos son llamados a través del comando `cla`: `cla <comando><argumentos>`
* El comando `cla` tiene dos opciones: <br />

&nbsp; &nbsp;• `version`: Muestra la versión de Clarive. <br />

&nbsp; &nbsp;• `help`: Muestra los comandos disponibles para su uso. La ayuda también se puede consultar a través de la opción `-h`: `cla -h`

* El comando `Cla` está a cargo de la recopilación de todos los datos de configuración de los archivos de configuración, el medio ambiente y los argumentos que se pasan a través de la línea de comandos antes de ejecutar la propia convocatoria de comandos.
* El comando `Cla` recopila todos los datos de configuración, archivos, entornos y argumentos que se pasan por medio de argumentos a través de la linea de comandos antes de ejecutar la llamada.
* Con el fin de describir todos los comandos, se muestra la salida de cla de ayuda:
            
        > cla help

        Clarive - Copyright(C) 2010-2015 Clarive Software, Inc.


        usage: cla [-h] [-v] [--config file] command <command-args>

        Commands available:
        <service.*>       run Baseliner services
        config            show all inherited config & options
        db                database diff and deploy tool
        disp              Start/Stop dispatcher
        help              This help
        install           config file generator
        lic               license verification
        poll              monitoring tool
        prove             run system tests and check
        ps                list server processes
        queue             queue management tools
        start             start all server tasks
        stop              stop all server tasks
        trans             conversion tool, password encryption
        version           report our version
        web               Start/Stop web server
        ws                webservices toolchain

        cla help <command> to get all subcommands.
        cla <command> -h for command options.

* Una opción común a todos estos comandos cla es la opción `-v` (detallado) para activar el modo detallado y mostrar todos los argumentos relacionados con el entorno de usuario.