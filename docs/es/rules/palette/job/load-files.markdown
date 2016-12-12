---
title: Cargar ficheros/elementos al stash
index: 5000
icon: file
---

Asigna a una variable [stash](concepts/stash) configurada por el usuario, todos los ficheros y elementos encontrados de acuerdo a las opciones que el usuario introduzca en la configuración de este elemento.

El elemento se configura mediante los siguientes campos:

- **Variable** - Variable que se añadirá al stash con todas los elementos y archivo encontrados.
- **Ruta** - Ruta base donde encontrar los ficheros o elementos de acuerdo al criterio que ponga el usuario.
- **Modo de ruta** - Modo en el que se buscarán los ficheros y/o elementos. Por defecto está establecido a 'Ficheros, no recursivo'. Las opciones son:
    - Ficheros, no recursivo - Solo se busca en el directorio actual.
    - Ficheros recursivos - Se busca a través de los directorios de manera recursiva.
    - Elementos de Naturaleza - Se busca en la ruta natural de acuerdo a las opciones del usuario.
- **Modo directorio** - Opción que establece donde el usuario busca archivos o elementos. Por defecto está configurado en 'Sólo ficheros'. Las opciones son:
    - Sólo fichero -  Solo busca en ficheros, no en directorios.
	- Sólo directorios -  Solo busca en los directorios.
	- Ficheros y directorios - Busca a través de los ficheros y de los directorios.
- **Filtros** - Permite añadir filtros para incluir o excluir determinadas rutas de la búsqueda.
    - Incluir rutas - Patrones de ruta (ya sean directorios o ficheros) para buscar los archivos o elementos que coinciden con los criterios del usuario.
    - Excluir rutas - Excluye las rutas o ficheros de la búsqueda.

