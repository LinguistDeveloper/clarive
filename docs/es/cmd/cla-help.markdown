---
title: cla help - Ayuda de los comandos
index: 5000
icon: console
---

`cla help`: Clarive dispone de una serie de comandos que pueden ser ejecutados para poder administrar correctamente la aplicación.

Estos comandos son llamados a través del comando `cla`: `cla <comando><argumentos>`

El comando `cla` tiene dos opciones:

- `version` - Muestra la versión de Clarive.
- `help` - Muestra los comandos disponibles para su uso. La ayuda también se puede consultar a través de la opción `-h`: `cla -h`

El comando `Cla` está a cargo de la recopilación de todos los datos de configuración de los archivos de configuración, el medio ambiente y los argumentos que se pasan a través de la línea de comandos antes de ejecutar la propia convocatoria de comandos.

Con el fin de describir todos los comandos, se muestra la salida de cla de ayuda:

        > cla help

        USO: cla [-h] [-v] [--config file] comando <comando-args>

        Comandos disponibles:
        <service.*>       ejecuta los servicios del Baseliner
        config            Muestra toda la configuración y opciones
        db                diff de la base de datos y herramienta para el despliegue
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


Una opción común a todos estos comandos cla es la opción `-v` (detallado) para activar el modo detallado y mostrar todos los argumentos relacionados con el entorno de usuario.