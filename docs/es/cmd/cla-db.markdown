---
title: cla db - Utilidades de la base de datos
index: 5000
icon: console
---

`cla db`: Comando gestionar el esquema de la base de datos.

Este comando se encarga de la implementación de esquema Clarive a una base de datos. El comportamiento es el mismo que el comando `db-deploy`.

La opción `-h` muestra la ayuda del comando con una breve descripción de cada opción:

        > cla db -h

        NAME
        Clarive DB Schema Deploy

        DESCRIPCIÓN
        Despliega el esquema Clarive a la base de datos.

        USO
        cla db-deploy [opciones]

        Opciones:
        -h     : Esta ayuda
        -deploy    : Ejecuta sentencias en la base de datos
                    cla db-deploy --deploy
        -run   : Ejecuta sentencias DB de manera interactiva.
        -quote   :Muestra el nombre de las tablas.
        -drop    :Añade sentencias drop.
        -grep    : grep un string o re en un sql generado.
        -env   : Establece CLARIVE_ENV (local, test, prod, t, etc...)
        -schema    : Esquemas para desplegar (no funciona en migraciones)
                    cla db-deploy --schema BaliUser --schema BaliProject
        -dump    : Se realiza un dump de las colecciones omitiendo logs y los datos de los ficheros del sistema

        Opciones de control de versiones:
        --diff    : Diffs este esquema de la base de datos.
        --installversion  : Instala tablas de versiones si es necesario.
        --upgrade   :Actualiza la versión de la base de datos.
        --from <version>  :Desde la versión (reemplaza la actual versión de la BBDD).
        --to <version>  :A la versión (reemplaza la versión actual del esquema).
        --grep <re>     :Filtra las declaraciones diff con una expresión regular.

        Ejemplos:
        cla db-deploy --env t
        cla db-deploy --env t --diff
        cla db-deploy --env t --diff --deploy
        cla db-deploy --env t --installversion
        cla db-deploy --env t --upgrade         # imprime solo los scripts de migración, no se aplica ningún cambio.
        cla db-deploy --env t --upgrade –deploy   # imprime solo los scripts de migración, no se aplica ningún cambio.
        cla db-deploy --env t --upgrade --show --to 2 # Lo mismo pero con el esquema versión 2.
        cla db-deploy --env t --upgrade --show --from 1   # Lo mismo pero con la BBDD versión 2.

