---
title: Run a Remote Script
icon: cog_java
---

* Ejecuta un script remoto y realiza el [rollback](Conceptos/rollback) si es necesario.

* Los elementos configurables son los siguientes.

<br />
### Servidor

* Especifica desde que servidor se quiere recuperar el script.

<br />
### Usuario

* Usuario permitido para conectarse al servidor configurado en la opción anterior.

<br />
### Ruta remota

* Indica la ruta donde está el script que se quiere ejecutar.

<br />
### Argumentos 

* Lista de los diferentes parámetros que el script espera recibir. 

<br />
### Errores

* Sirve para gestionar los errores que se pueden generar al ejecutar el script. Las opciones son: <br />


&nbsp; &nbsp;&nbsp; &nbsp; • *Fail* - Busca el patrón del error en la salida del script. Si lo encuentra, se muestra un mensaje de error en el monitor. <br />

&nbsp; &nbsp;&nbsp; &nbsp; • *Warn* - Busca el patrón de las advertencias en la salida del script. Si lo encuentra, se muestra un mensaje de advertencia en el monitor. <br />

&nbsp; &nbsp;&nbsp; &nbsp; • *Custom*: Permite personalizar los rangos de valores de los códigos de retorno: <br />

&nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; • *OK* - Establece los valores para los que el script ha sido ejecutado con éxito. Ningún mensaje aparecerá en el Monitor. <br />

&nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; • *Warn* -  Establece los valores para los que el script ha generado *warnings*. Se muestra un mensaje de advertencia en el Monitor. <br />

&nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; • *Error* - Establece los valores para los que el script ha fallado. Se muestra un mensaje de error en el Monitor.