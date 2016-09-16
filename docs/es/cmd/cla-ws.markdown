---
title: cla ws - Invocar servicios web
index: 5000
icon: console
---

`cla ws`: Herramientas REST Clarive REST. Encuentra todos los métodos públicos disponibles en un [CI](concepts/ci) dado.

Se pueden pasar los siguientes parámetros:

`--classname <nombre-clase>`: Nombre de la clase CI para buscar los métodos disponibles. Por defecto el valor es '\*'.

`--mid <mid>`: Mid al que pertenece el CI definido.

La salida muestra métodos comunes a todas las clases de CI, y los métodos disponibles para la clase CI dada.

Los subcomandos que soporta este `cla ws` pueden ser consultados a través de la ayuda:

    > cla help ws

    USO: cla [-h] [-v] [--config file] comando <comando-args>

    Subcomandos disponibles para ws:

        ws-list

    cla help <comando> para obtener todos los subcomandos.
    cla <comando> -h para los opciones del comando.

`cla ws-list`: Mismo comportamiento que `cla ws`.

