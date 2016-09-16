---
title: cla prove - Ejecuta los tests internos
index: 5000
icon: console
---

`cla prove`: Ejecuta los tests internos y comprueba el resultado de los mismos.

Este comando ejecuta fichero de test localizados en el directorio y muestra los resultados en pantalla.

Cada caso de prueba comienza con:

`[start] <nombre_caso_prueba>`

Y finaliza con:

`[end] <nombre_caso_prueba> [<duracion_del_test>]`

En caso de error, se mostrará un mensaje de error en rojo.

El comando acepta las siguientes opciones:

- `-- type <directorio>` - Ejecuta solo los test que estén definidos en la ruta de `<directorio>`.
- `-- case <nombre_caso>` - Ejecuta solo el test `<nombre_caso>`.

Este comando tiene un subcomando que puede ser consultado a través de la opción de ayuda:

        > cla help prove

        USO: cla [-h] [-v] [--fichero de configuración] comando <comando-args>

        Subcomandos disponibles para prove (ejecuta tests del sistema)
        prove-startu

        cla help <comando> para obtener todos los subcomandos.
        cla <comando> -h para las opciones de un comando especifico.


`cla prove-startup`: Realiza un test a todos los sistemas que están involucrados en el arranque de Clarive. La salida del comando muestra la release de Clarive, la versión, los parches instalados, el tiempo de inicio y un mensaje indicando si el sistema está preparado o existe algún error.
