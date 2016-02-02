---
title: Run a Local Script
icon: cog_java
---

* Ejecuta un script local y realiza el [rollback](es/Conceptos/rollback) si es necesario.

* Los elementos configurables son los siguientes.

<br />
### Ruta 

* Ruta donde se aloja el script a ejecutar.

<br />
### Opciones

* Permite configurar y gestionar el script: <br />

&nbsp; &nbsp;&nbsp; &nbsp; • *Argumentos* - Lista de los diferentes parámetros que el script espera recibir. <br /> 

&nbsp; &nbsp;&nbsp; &nbsp; • *Entorno* - Variables de entorno que se necesitan para que se ejecute el script. <br />

&nbsp; &nbsp;&nbsp; &nbsp; • *Ficheros de salida* - Establece donde almacena el fichero que el script genera. Estos ficheros también son publicados en el Monitor.  <br />


<br />
### Directorio Home

* Directorio desde el que se lanza el script local

<br />
### Stdin

* Entrada del string

<br />
### Salida

* Tabla para gestionar la salida del script. Las opciones son: <br />

Búsqueda de patrón de error configurado en salida del script. Si lo encuentra, se muestra un mensaje de error en la pantalla que muestra el partido.

&nbsp; &nbsp;&nbsp; &nbsp; • *Error* - Busca el patrón del error en la salida del script. Si lo encuentra, se muestra un mensaje de error en el monitor. <br />


&nbsp; &nbsp;&nbsp; &nbsp; • *Advertir* - Busca el patrón de las advertencias en la salida del script. Si lo encuentra, se muestra un mensaje de advertencia en el monitor. <br />

&nbsp; &nbsp;&nbsp; &nbsp; • *OK* - Busca el patrón para el OK configurado en la salida del script. Si lo encuentra, se muestra un mensaje de error en el monitor. Los posibles errorres se ingnoran. <br />


&nbsp; &nbsp;&nbsp; &nbsp; • *Captura* - Busca el patrón definido en la salida del script. si lo encuentra, la expresión se añade al stash mostrandro un mensaje.