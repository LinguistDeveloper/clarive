---
title: Run a Remote Script
icon: cog_java
---
* Ejecuta un script remoto y realiza el [rollback](concepts/rollback) si es necesario.
* Los elementos configurables son los siguientes.

### Servidor
* Especifica desde que servidor se quiere recuperar el script.

### Usuario
* Usuario permitido para conectarse al servidor configurado en la opción anterior.

### Ruta remota
* Indica la ruta donde está el script que se quiere ejecutar.

### Argumentos
* Lista de los diferentes parámetros que el script espera recibir.

### Errores
* Sirve para gestionar los errores que se pueden generar al ejecutar el script. Las opciones son:

*Fail* - Busca el patrón del error en la salida del script. Si lo encuentra, se muestra un mensaje de error en el monitor.

*Warn* - Busca el patrón de las advertencias en la salida del script. Si lo encuentra, se muestra un mensaje de advertencia en el monitor.

*Custom*: Permite personalizar los rangos de valores de los códigos de retorno:

*OK* - Establece los valores para los que el script ha sido ejecutado con éxito. Ningún mensaje aparecerá en el Monitor.

*Warn* -  Establece los valores para los que el script ha generado *warnings*. Se muestra un mensaje de advertencia en el Monitor.

*Error* - Establece los valores para los que el script ha fallado. Se muestra un mensaje de error en el Monitor.