---
title: Load files/items
icon: file
---


* Asigna a una variable alijo configurado por el usuario toda encontraron archivos / elementos de acuerdo a las opciones introducidas por el
usuario de la ventana del formulario de configuración.
* Asigna a una variable [stash](Conceptos/stash) configurada por el usuario, todos los ficheros y elementos encontrados de acuerdo a las opciones que el usuario introduzca en la configuración de este elemento.
* El elemento se configura mediante los siguientes campos:


<br />
### Variable
* Variable que se añadirña el stash con todas los elementos y archivo encontrados.

<br />
### Ruta
* Ruta base donde encontrar los ficheros o elementos de acuerdo al criterio que ponga el usuario.

<br />
### Modo de ruta
* Modo en el que se buscarán los ficheros y/o elementos. Por defecto está establecido a 'Ficheros, no recursivo'. Las opciones son: <br />
      
&nbsp; &nbsp;&nbsp; &nbsp; • *Ficheros, no recursivo* - Solo se busca en el directorio actual. <br />

&nbsp; &nbsp;&nbsp; &nbsp; • *Ficheros recursivos* - Se busca a través de los directorios de manera recursiva.  <br />

&nbsp; &nbsp;&nbsp; &nbsp; • *Elementos de Naturaleza* -Se busca en la ruta natural de acuerdo a las opciones del usuario.


<br />
### Modo directorio
* Opción que establece donde el usuario busca archivos o elementos. Por defecto está configurado en 'Sólo ficheros'. Las opciones son: <br />

&nbsp; &nbsp;&nbsp; &nbsp; • *Sólo fichero*: Solo busca en ficheros, no en directorios. <br />

&nbsp; &nbsp;&nbsp; &nbsp; • *Sólo directorios*: Solo busca en los directorios. <br />

&nbsp; &nbsp;&nbsp; &nbsp; • *Ficheros y directorios*: Busca a través de los ficheros y de los directorios. <br />




<br />
### Filtros
* Permite añadir filtros para incluir o excluir determinadas rutas de la búsqueda.  <br />
      
&nbsp; &nbsp;&nbsp; &nbsp; • *Incluir rutas*: Patrones de ruta (ya sean directorios o ficheros) para buscar los archivos o elementos que coinciden con los criterios del usuario. <br />
     
&nbsp; &nbsp;&nbsp; &nbsp; • *Excluir rutas*: Excluye las rutas o ficheros de la búsqueda.

