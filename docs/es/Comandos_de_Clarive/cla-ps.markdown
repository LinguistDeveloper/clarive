---
title: cla ps - Monitor de procesos
icon: console
---
* `cla ps`: Lista los procesos que está directamente relacionados con servicios de Clarive, clasificándolos en función del tipo de proceso. Estos pueden ser: <br /> 

&nbsp; &nbsp;• Jobs <br />

&nbsp; &nbsp;• Dispatcher <br />

&nbsp; &nbsp;• Server <br />

* La salida muestra las siguientes columnas: PID del proceso, PPID, CPU, MEM, STAT, START, COMMAND.
* Este comando dispone de subcomandos que pueden ser consultados a través de la ayuda:
            
        >cla help ps
        Clarive - Copyright(C) 2010-2015 Clarive Software, Inc.


        usage: cla [-h] [-v] [--config file] command <command-args>

        Subcommands available for ps (list server processes):

        ps-filter
        cla help <command> to get all subcommands.
        cla <command> -h for command options.
    
<br/>

* `cla ps-filter`: Lista todos los procesos relacionados con el servidor y el dispatcher.
