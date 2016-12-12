---
title: cla plugin - ayuda para plugins
index: 5000
icon: console
---

Este comando ofrece opciones para ayudar con el sistema de plugins de 
Clarive

Todos los comandos de plugins, como Clarive en general,
se utiliza mediante la opción `--plugins-home`.

Esta opción puede ser cambiada en el entorno de configuración,
por lo que es recomendable comprobar que plugins están disponibles para la instalación de Clarive ejecutando el comando `plugin-list`.

### cla plugin-new --plugin [plugin-id]

Comando para un nuevo plugin, creando la estructura de carpetas necesarias para el desarrollo.

No es necesario ejecutar este comando para desarrollar plugins, tan solo es una buena manera para evitar crear las carpetas y los ficheros desde cero manualmente.

    cla plugin-new --plugin miplugin

Generalmente se crean los plugins siguiendo la siguiente estructura:

    CLARIVE_BASE/plugins/miplugin/...

### cla plugin-test [nombre-parcial-del-directorio]

Se pueden ejecutar las pruebas de plugins mediante la ejecución de los casos de prueba
contenida en la carpeta `t` y sus subdirectorios,
en concreto en `DECLARATIVE_BASE/plugins/[plugin-id]/t`.

La salida de los test es compatible con *TAP (Test Anything Protocol*, el cual es compatible con diferentes frameworks de testing.

Para más información: [https://testanything.org/ <img class='ext-link' src='static/images/icons/new_window_link.svg' />](https://testanything.org/)

#### --verbose-tests

Con el modo detallado, los resultados y los mensaje del sistema se pueden visualizar en el log.

    $ cla plugin-test --verbose-tests

    /opt/clarive/plugins/cloudfoundry/t/cf-test.js ..
    ok 1
    1..1
    ok

### cla plugin-list

Lista todos los plugins instalados y activos

Este comando es útil para comprobar que plugins son visibles.

### cla plugin-search-path

Enumerar los directorios de los plugins actuales su orden de búsqueda.

    $ cla plugin-search-path
    /opt/clarive/plugins
    /opt/clarive/clarive/plugins


