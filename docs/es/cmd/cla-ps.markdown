---
title: cla ps - Monitor de procesos
index: 5000
icon: console
---

`cla ps`: Lista los procesos que está directamente relacionados con servicios de Clarive, clasificándolos en función del tipo de proceso. Estos pueden ser:

- Jobs
- Dispatcher
- Server

La salida muestra las siguientes columnas: PID del proceso, PPID, CPU, MEM, STAT, START, COMMAND.

Este comando dispone de subcomandos que pueden ser consultados a través de la ayuda:

        > cla help ps

        uso: cla [-h] [-v] [--fichero de configuración] comando <comando-args>

        Subcomandos disponibles para ps (lista de procesos):
        ps-filter

        cla help <comando> para obtener todos los subcomandos.
        cla <comando> -h para los opciones del comando.

`cla ps-filter`: Lista todos los procesos relacionados con el servidor y el dispatcher.
