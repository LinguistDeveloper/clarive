---
title: Menu de reglas
index: 200
icon: rule
---
* La ruta para acceder a las reglas es a través del menú de administración.
* Seleccionando  **Admin → Reglas** se abre una nueva pestaña con tres áreas de trabajo diferentes.

## Área con el listado de reglas
* Área con dos columnas que muestra el id de la regla, el nombre y el tipo. Además, en la columna contigua se muestra la fecha de la última modificación.


#### Acciones
* Las acciones que se pueden realizar son:

<img src="/static/images/icons/search-small.svg" />**Cuadro de búsqueda**: Para buscar reglas por nombre o, en caso de buscar, por ejemplo un componente de la paleta, muestra en que reglas ese componente está siendo utilizado.

<img src="/static/images/icons/refresh.svg" /> **Refresca** - Refresca la lista de reglas.

<img src="/static/images/icons/add.svg" /> **Crear** - Crear una nueva regla.

<img src="/static/images/icons/edit.svg" /> **Editar** - Edita la configuración general de la regla seleccionada.

<img src="/static/images/icons/delete.svg" /> **Borrar** - Elimina la regla seleccionada.

<img src="/static/images/icons/workflow.svg" /> **Workflow** - Organiza las reglas basadas en su tipología.

<img src="/static/images/icons/restart_new.svg" /> **Activar/Desactivar** - Activa o desactiva la regla seleccionada.

<img src="/static/images/icons/wrench.svg" /> **Herramientas** - <img src="/static/images/icons/import.svg" /> Importa or <img src="/
static/images/icons/export.svg" /> Exporta la regla seleccionada en formato YAML para ser utilizado en otros sistemas Clarive.

### Árbol de regla
* Se trata del área donde se muestra la estructra de la regla como un árbol. En la barra de herramientas existen varias opciones:

<img src="/static/images/icons/search-small.svg" /> **Cuadro de búsqueda** - Busca los campos que coinciden con la búsqueda.

<img src="/static/images/icons/refresh.svg" /> **Refresca** - Refresca la regla.

<img src="/static/images/icons/action_save.svg" /> **Guardar** - Guarda la regla.

<img src="/static/images/icons/edit.svg" /> **DSL** - Se abre una nueva ventana con el código DSL de la regla seleccionada. Este código puede ser ejecutado. El funcionamiento de esta opción está descrito en la [Paleta de reglas](rules/rule-menu).

<img src="/static/images/icons/wrench.svg" /> **Herramientas** - Mas opciones acerca de la regla:

<img src="/static/images/icons/search-small.svg" /> *Búsqueda* - Encuentra y resalta el texto buscado dentro de la regl

<img src="/static/images/icons/wipe_cache.svg" /> *Limpiar* - Limpia los resultados de la búsqueda.

*Expresión regular* - Permite buscar por expresión regular.

*Ignorar mayúsculas* - Permite realizar una búsqueda ignorando las mayúsculas.

*Historial* -  Busca la cadena deseada en todas las versiones de las reglas.

<img src="/static/images/icons/expandall.svg" /> **Expandir todo** - Expande todos los componentes de la regla.

<img src="/static/images/icons/collapseall.svg" /> **Collapsa todo** - Collapsa todos los componentes de la regla.

<img src="/static/images/icons/slot.svg" /> **Version** - Expande toda el historial de versiones de la regla. Muestra las fechas, la hora y el usuario que guardó la regla.

<img src="/static/images/icons/html.svg" /> **HTML** - Muestra la regla en una página HTML


### Paleta
* Contiene todas las operaciones que pueden ser utilizadas para componer una regla.
* Si el parámetro show_in_palette está inicializado a 1, la operación estará disponibles en la paleta.
* En esta sección se dispone de dos opciones:

<img src="/static/images/icons/search-small.svg" /> **Búsqueda** - Permite buscar entre los componentes de la paleta.

<img src="/static/images/icons/refresh.svg" /> **Refrescar** - Refresca la paleta.
