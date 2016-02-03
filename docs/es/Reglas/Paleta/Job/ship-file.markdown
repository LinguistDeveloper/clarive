---
title: Ship File Remotely
icon: file.gif
---
* Obtiene uno o varios ficheros de un servidor remoto. 
* Los elementos configurables son los siguientes.

<br />
### Servidor
* Especifica desde que servidor se quiere recuperar el script.

<br />
### Usuario
* Usuario permitido para conectarse al servidor configurado en la opción anterior.

<br />
### Recursivo
* Obtiene los archivos de forma recursiva a través de los directorios que hay bajo la ruta base

<br />
### Modo Local
* Especifica que ficheros son parte de la lista para obtenerlos del servidor remoto. Pueden ser: <br />

&nbsp; &nbsp;&nbsp; &nbsp;• **Local files**: Todos los ficheros que se encuentran. <br />

&nbsp; &nbsp;&nbsp; &nbsp;• **Elementos de Naturaleza**: Ficheros involucrados en la naturaleza actual. <br />


<br />
### Ruta Relativa
* Ruta relativa para colocar los archivos en el servidor local. Las opciones son: <br />
    
&nbsp; &nbsp;&nbsp; &nbsp;• Sólo ficheros, no rutas: Solo coge los nombres de archivo. <br />

&nbsp; &nbsp;&nbsp; &nbsp;• Mantenenga la ruta relativa desde el directorio de trabajo <br />

&nbsp; &nbsp;&nbsp; &nbsp;• Especificar la ruta de anclaje:  Establece la ruta de anclaje de los ficheros, por defecto: `${job_dir}/${project}` <br />

<br />
### Ruta remota
* Indica la ruta donde está el script que se quiere ejecutar.

<br />
### Modo existe

<br />
### Modo copia de seguridad

<br />
### Modo Marcha atrás

<br />
### Chown
* Establece el propietario del fichero.

<br />
### Chmod
* Establece los permisos de escritura, lectura y ejecución del fichero.

<br />
### Filtros
* De acerdo a los parametros 
* Permite añadir filtros para incluir o excluir determinadas rutas de la búsqueda.  <br />
      
&nbsp; &nbsp;&nbsp; &nbsp; • *Incluir rutas*: Patrones de ruta (ya sean directorios o ficheros) para buscar los archivos o elementos que coinciden con los criterios del usuario. <br />
     
&nbsp; &nbsp;&nbsp; &nbsp; • *Excluir rutas*: Excluye las rutas o ficheros de la búsqueda.

