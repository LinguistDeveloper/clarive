---
title: Reemplazar cadenas de texto
index: 5000
icon: service-sed
---

Convierte los ficheros específicos desde una ruta dada. Los ficheros parseados pueden ser procesados de diferentes maneras de acuerdo con los criterios de usuario desde la ventana de configuración.

Los elementos configurables son los siguientes:

- **Ruta** - Ruta donde buscar los ficheros que se desean procesar.
- **Poner fichero en memoria** - Habilitando esta opción, todo el contenido del fichero se almacena en memoria.
- **Modo de elementos** - Opción para seleccionar los archivos que se parsearán. Los valores admitidos son:
    - Todos los ficheros - Todos los ficheros de la ruta se procesarán.
    - Elementos del pase - Solo los ficheros que sean elementos de pase serán procesados.
- **Directorio de la salida** - Ruta donde se guardarán los ficheros ya parseados.
- **Sufijo** - Los ficheros procesados se renombrarán añadiendo un sufijo en el nombre del archivo.
- **Patrones** - Los datos del archivo serán procesados con patrones asignados de este campo.
- **Incluye** - Los ficheros de la lista que van a ser procesados deben coincidir con los patrones dados en este campo.
- **Exluye** - Serán excluidos los ficheros de la lista que coincidan con los patrones dados en este campo.