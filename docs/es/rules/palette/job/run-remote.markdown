---
title: Ejecutar un script remoto
index: 5000
icon: cog-java-orange
---
Ejecuta un script remoto y realiza el [rollback](concepts/rollback) si es necesario.

El agente de servidor asociado realizará la ejecución del script.


Los elementos configurables son los siguientes.

- **Servidor** - Servidor que contiene el script remoto.
- **Usuario** -  Usuario permitido para conectarse al servidor remoto.
- **Comando** - Comandos a ejecutar en el servidor remoto.
- **Argumentos** - Lista de los diferentes parámetros que el script espera recibir.
- **Entorno** - Lista de variables que pueden ser utilizadas en el campo Comando.
- **Errores y salida** - Sirve para gestionar los errores que se pueden generar al ejecutar el script. Las opciones son:
   - Error y error en la salida - Busca el patrón del error en la salida del script. Si lo encuentra, se muestra un mensaje de error en el monitor.
   - Advertencia y advertencia en la salida - Busca el patrón de las advertencias en la salida del script. Si lo encuentra, se muestra un mensaje de advertencia en el monitor.
   - Custom - Permite personalizar los rangos de valores de los códigos de retorno:
   - OK - Establece los valores para los que el script ha sido ejecutado con éxito. Ningún mensaje aparecerá en el Monitor.
   - Warn - Establece los valores para los que el script ha generado *warnings*. Se muestra un mensaje de advertencia en el Monitor.
   -Error - Establece los valores para los que el script ha fallado. Se muestra un mensaje de error en el Monitor.