---
title: Tabla de Configuración
---

La tabla de configuración global contiene parámetros de configuración __dinámica__ 
que se almacenan en la base de datos de Clarive.

Los parámetros de _configuración dinámica_ pueden ser cambiados en cualquier
momento por el administrador y automáticamente se reflejarán en Clarive.

Eso es precisamente lo que hace que esos valores de configuración sean diferentes
de los parámetros de configuración __estáticos__ que se establecen en los
(ficheros de configuración)[setup/config-file].

Los valores estáticos requieren el reinicio del servidor o del
 (dispatcher)[admin/dispatcher]

Por ejemplo, las siguientes variables de configuración globales son dinámicas y
pueden ser establecidas en la tabla de configuración;

    config.daemon.purge.frequency: 86400
    config.git.path: /opt/repository

