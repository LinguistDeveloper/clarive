---
title: Ejecutar un script local
index: 5000
icon: service-scripting-local
---

Ejecuta un script local y realiza el [rollback](concepts/rollback) si es necesario.

Los elementos configurables son los siguientes:

- **Ruta** - Ruta donde se aloja el script a ejecutar.
- **Opciones** - Permite configurar y gestionar el script:
    - Argumentos - Lista de los diferentes parámetros que el script espera recibir.
    - Entorno - Variables de entorno que se necesitan para que se ejecute el script.
    - Ficheros de salida - Establece donde almacena el fichero que el script genera. Estos ficheros también son publicados en el Monitor.
- **Directorio Home** - Directorio desde el que se lanza el script local
- **Stdin** - Entrada del string.
- **Errores** - Selecciona el tipo de error en la salida:
- **Salida** - Búsqueda de patrón de error configurado en salida del script. Si lo encuentra, se muestra un mensaje de error en la pantalla que muestra el partido.. Las opciones son:
   - Error - Busca el patrón del error en la salida del script. Si lo encuentra, se muestra un mensaje de error en el monitor.
   - Advertir - Busca el patrón de las advertencias en la salida del script. Si lo encuentra, se muestra un mensaje de advertencia en el monitor.
   - OK - Busca el patrón para el OK configurado en la salida del script. Si lo encuentra, se muestra un mensaje de error en el monitor. Los posibles errorres se ignoran.
   - Captura - Busca el patrón definido en la salida del script. si lo encuentra, la expresión se añade al stash mostrando un mensaje.