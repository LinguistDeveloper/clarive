---
title: Menú de reglas
icon: rule
---

La ruta para acceder a las reglas es a través del menú de administración.

Seleccionando  **Admin - <img src="/static/images/icons/rule.svg" /> Reglas** se abre una nueva pestaña con tres áreas de trabajo diferentes.

### Área con el listado de reglas

- **Regla** - Muestra el id de la regla, el nombre y el tipo de regla.
- **Cuándo** - Muestra la fecha de la última modificación.


### Acciones

Las acciones que se pueden realizar son:

- <img src="/static/images/icons/add.svg" /> **Crear** - Crear una nueva regla.
- <img src="/static/images/icons/edit.svg" /> **Editar** - Edita la configuración general de la regla seleccionada.
- <img src="/static/images/icons/delete.svg" /> **Borrar** - Elimina la regla seleccionada.
- <img src="/static/images/icons/catalog-folder.svg" /> **Vista árbol** - Organiza las reglas basadas en su tipología.
- <img src="/static/images/icons/restart_new.svg" /> **Activar/Desactivar** - Activa o desactiva la regla seleccionada.
- <img src="/static/images/icons/wrench.svg" /> **Herramientas** - <img src="/static/images/icons/import.svg" /> Importa or <img src="/
static/images/icons/export.svg" /> Exporta la regla seleccionada en formato YAML para ser utilizado en otros sistemas Clarive.


### Árbol de regla

Se trata del área donde se muestra la estructura de la regla como un árbol. En la barra de herramientas existen varias opciones:

- <img src="/static/images/icons/refresh.svg" /> **Refresca** - Actualiza la regla.
- <img src="/static/images/icons/save.svg" /> **Guardar** - Guarda la regla.
- <img src="/static/images/icons/edit.svg" /> **DSL** - Se abre una nueva ventana con el código DSL de la regla seleccionada. Este código puede ser ejecutado. El funcionamiento de esta opción está descrito en la [Paleta de reglas](rules/rule-menu).
- <img src="/static/images/icons/wrench.svg" /> **Herramientas** - Mas opciones acerca de la regla:
   - *Expresión regular* - Permite buscar por expresión regular.
   - *Ignorar mayúsculas* - Permite realizar una búsqueda ignorando las mayúsculas.
   - *Historial* -  Busca la cadena deseada en todas las versiones de las reglas.
- **Blame by time** - Marca los cambios en los elementos en un periodo específico de tiempo.
- <img src="/static/images/icons/expandall.svg" /> **Expandir todo** - Expande todos los componentes de la regla.
- <img src="/static/images/icons/collapseall.svg" /> **Colapsa todo** - Colapsa todos los componentes de la regla.
- <img src="/static/images/icons/slot.svg" /> **Versión** - Expande toda el historial de versiones de la regla. Muestra las fechas, la hora y el usuario que guardó la regla.
- <img src="/static/images/icons/html.svg" /> **HTML** - Muestra la regla en una página HTML
- <img src="/static/images/icons/workflow.svg" /> **Diagrama de flujo** - Muestra el árbol de la regla.


### Paleta

Contiene todas las operaciones que pueden ser utilizadas para componer una regla.

Si el parámetro *show_in_palette* está inicializado a 1 en el fichero de configuración
del elemento, la operación estará disponible en la paleta.