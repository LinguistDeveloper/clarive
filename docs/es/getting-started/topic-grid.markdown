---
title: Tabla de topicos
index: 5000
icon: topic.svg
---
* La tabla de tópicos es la lista de tópicos que el usuario puede visualizar. El concepto está basado como si fuera una bandeja de entrada de e-mail.
* La tabla puede ser vista desde tres modos diferentes: <br />

&nbsp; &nbsp;• **Todos los tópicos** - Se abre seleccionando `Todos` dentro del menú de tópicos en la parte superior de la página.  <br />

&nbsp; &nbsp;• **Por categoría** - Acceso a través de selecionar una categoría dentro del menú de tópicos. <br />

&nbsp; &nbsp;• **Por proyecto** - Por último también se puede acceder a través del explorador de proyectos <img src="/static/images/icons/project.svg" /> situado en el panel de la izquierda.

<br />
### Ordenación 
* Por defecto, la lista aparece ordenada por fecha de modificación, del más reciente al elemento más antiguo.
* Se puede cambiar la ordenación pinchando en la columna por la que se quiere ordenar la lista. Con cada click, se cambiará el tipo de ordenación (ascendiente/descendiente).

<br />
<br />
## Filtros
* Para filtrar los resultados, existe unos filtros definidos en la parte derecha de la lista.

<br />
#### Uso
* Cada uno de los filtros existen 3 estados diferentes. <br />


&nbsp; &nbsp;• **Seleccionado** - Muestra los tópicos que estén en ese estado. <br />

&nbsp; &nbsp;• **No seleccionado** - Oculta los tópicos que estén en ese estado. <br />

&nbsp; &nbsp;• **Sin seleccionar** - Esconde los tópicos que estén en ese estado si hay ningún otro estado seleccionado. En caso de no haberlo, muestra los tópicos con su estado.

* Como regla general, si no hay ningún estado seleccionado o no seleccionado, se muestran todos los tópicos.

<br />
#### Filtros
* Se trata de un filtro que permite al usuario filtrar los resultados en función de diferentes situaciones.

<br />
#### Categorías
* Filtra por la categoría que el usuario quiera ver. Si no hay ninguna seleccionado, muestra todas las categorías siempre que el usuario tenga los permisos necesarios.

<br />
#### Estados
* Por defecto están seleccionados todos aquellos que no son estados finales.


<br />
<br />
## Opciones
* A continuación se detallan las distintas opciones que ofrece el menu superior de la lista de tópicos. Estas opciones variarán en función de los permisos que disponga el usuario:

<br />
#### Búsquedas
* En el grid de tópicos tambien se puede buscar resultados utilizando el [buscador](Primeros_pasos/search-syntax).

<br /> 
#### <img src = "/static/images/icons/add.svg" alt='Nuevo tópico' /> Crear
* Permite crear un nuevo tópico.
* En el caso en que se estén visualizado más de una categoria, la herramienta te permite escoger la categoría del nuevo tópico antes de acceder al formulario.

<br />
#### <img src = "/static/images/icons/edit.svg" alt='Editar tópico' /> Editar
* Permite editar un tópico.
* El botón se habilitará de manera automática una vez seleccionado el tópico que se quiere modificar.

<br />
#### <img src = "/static/images/icons/delete_.png" alt='Borrar tópico' /> Borrar
* Borra un tópico.
* El botón se habilita al seleccionar un tópico. La herramienta solicita al usuario confirmación para realizar esta acción.
* Está permitido borrar más de un tópico a la vez.

<br />
#### <img src = "/static/images/icons/state.svg" alt='Cambiar estado' /> Cambiar estado
* Permite transitar el tópico entre estados sin necesidad de acceder al detalle del mismo.
* Es posible modificar el estado de varios tópicos siempre y cuando tengan estados futuros comunes, independientemente de la categoría de los mismos. En caso contrario, el botón aparacerá deshabilitado indicando que no hay estados comunes.

<br />
#### <img src = "/static/images/icons/reset-grey.png" alt='Resetear columnas' /> Resetear columnas del grid
* Vuelve la lista al estado inicial en caso de haber realizado una ordenación por una columna en concreto.

<br />
#### <img src = "/static/images/icons/exports.png" alt='Exportar' /> Exportar
* Permite exportar la lista y su estado (en caso de que haya ordenación y/o filtros) en HTML, CSV o YAML 

<br />
#### <img src = "/static/images/icons/kanban.svg" alt='Kanban' /> Kanban
* Permite ver el estado de los tópicos en la [tabla Kanban](Primeros_pasos/kanban)


<br />
####  <img src = "/static/images/icons/updown_.gif" alt='Colapsar filas' /> Colapsar filas
* Colapsando las filas permite visualizar más tópicos por página pero con menos detalle de cada uno de ellos.