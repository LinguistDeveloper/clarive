---
title: Enviar un fichero remotamente
index: 5000
icon: file
---

Los elementos configurables son los siguientes.

- **Servidor** - Especifica desde que servidor se quiere recuperar el script.
- **Usuario** - Usuario permitido para conectarse al servidor configurado en la opción anterior.
- **Recursivo** - Obtiene los archivos de forma recursiva a través de los directorios que hay bajo la ruta base.
- **Modo Local** - Especifica que ficheros son parte de la lista para obtenerlos del servidor remoto. Pueden ser:
   - Local files - Todos los ficheros que se encuentran en la ruta especificada.
   - Elementos de Naturaleza - Ficheros involucrados en la naturaleza actual.
- **Ruta Relativa** - Ruta relativa para colocar los archivos en el servidor local. Las opciones son:
   - Sólo ficheros, no rutas - Solo coge los nombres de archivo.
   - Mantenga la ruta relativa desde el directorio de trabajo.
   - Especificar la ruta de anclaje -  Establece la ruta de anclaje de los ficheros, por defecto: `${job_dir}/${project}`
- **Existe en local** - Especifica qué hacer cuando el fichero ya existe.
- **Modo backup** - Selecciona si quiere realizar backup del fichero.
- **Modo Marcha atrás** - Indica el que acción realizar sobre el fichero transferido en caso de hacer un rollback del job.
- **Ruta remota** - Indica la ruta donde está el script que se quiere ejecutar.
- **Chown** - Establece el propietario del fichero.
- **Chmod** - Establece los permisos de escritura, lectura y ejecución del fichero.
- **Tamaño máximo de los fragmentos** - En caso de que se quiera enviar el fichero fragmentado, es necesario indicar el tamaño en KB de los fragmentos..
- **Copiar los atributos del fichero**
- **Filtros** - Permite añadir filtros para incluir o excluir determinadas rutas de la búsqueda.
     - Incluir rutas - Patrones de ruta (ya sean directorios o ficheros) para buscar los archivos o elementos que coinciden con los criterios del usuario.
     - Excluir rutas - Excluye las rutas o ficheros de la búsqueda.

