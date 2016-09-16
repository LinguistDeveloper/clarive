---
title: Extendiendo cla con comandos
index: 2000
icon: page
---

Existe la posibilidad de escribir programas que
extiendan el comando `cla` con nuevas funcionalidades 
que aprovechen la plataforma para acceder a los agentes de Clarive, elementos de configuración, y otras funcionalidades.

    cla micomando --mis-opciones

## Empezando

Mediante la ejecución del comando `cla`, se muestran la lista de comandos disponibles:

    > cla help

    USO: cla [-h] [-v] [--config file] comando <comando-args>

    Comandos disponibles:
    <service.*>       Ejecuta los servicios del Baseliner
    config            Muestra toda la configuración y opciones
    db                Diff de la base de datos y herramienta para el despliegue
    disp              Inicia/Detiene el dispatcher
    help              Esta ayuda
    install           Generador del fichero de configuración
    lic               Verificación de la licencia
    poll              Herramienta de monitorización
    prove             Ejecuta los test del sistema
    ps                Lista los procesos del servidor
    queue             Herramienta de gestión de colas
    start             Inicia todas las tareas del servidor
    stop              Detiene todas las tareas del servidor
    trans             Herramienta de conversión, encriptación de la contraseña
    version           Devuelve la versión de Clarive
    web               Inicia/Detiene el servidor web
    ws                Cadena de herramientas de los webservices

    cla help <comando> para obtener todos los subcomandos.
    cla <comando> -h para los opciones del comando.


Añadir nuevos comandos se realiza desde dentro de un plugin.

Para crear un nuevo plugin, en caso de que no tener uno ya,
ejecutar el comando `plugin-bootstrap`:

    cla plugin-new --plugin myplugin

Ahora hay que crear un archivo con los comandos, supongamos que queremos crear
el comando `cmd`, este sería el archivo correspondiente:

    CLARIVE_BASE/plugins/myplugin/cmd/mycmd.js

Un programa de comandos es sólo un programa en JavaScript:

```javascript
print("Hola mundo");
```

### Configuración de comandos completa

Aunque las opciones de línea de comandos están disponibles,
la forma correcta de acceder a la configuración de comandos
es llamando a `process.options(clave)`, que recupera
el valor correcto de configuración que incluye:

- El archivo de configuración YAML global.
- El archivo YAML de configuración del entorno (establecido con `--env`)
- La sección del comando en el archivo de configuración
- Por último, los *flags* de los argumentos de línea de comandos

La precedencia va de abajo hacia arriba.


La función `process.options (clave)` accede al merge de las opciones de pila.

    print( process.options('mongo.db_name') );

### Argumentos del comando

Los argumentos de línea de comandos se envían al programa de
a través de la variable `process`:

    cla.dump( process.argv() );


También se puede acceder a las opciones individuales como una
objeto, más fácil de manipular que pasar por el array `args`.

```javascript
var myoption = process.args('myoption');
print( "El usuario ha introducido --myoption=" + myoption );
```

