---
title: Menu de reglas
icon: rule
---
La ruta para acceder a las reglas es a través del menú de administración. Seleccionando
**Admin → Reglas** se abre una nueva pestaña con tres áreas de trabajo diferentes.

## Área con el listado de reglas

Área con dos columnas y una pestaña de acciones:

- **Regla**: Id de la regla, el nombre y el tipo.
- **Time**: Fecha de la última modificación.

#### Acciones

Las acciones que se pueden realizar son:

<img src="/static/images/icons/search-small.svg" />**Cuadro de búsqueda**:
Buscar reglas de acuerdo a la entrada del cuadro de búsqueda. Lista hasta 30 reglas.

<img src="/static/images/icons/refresh.svg" /> **Refresca**: Refresca la lista de reglas.

<img src="/static/images/icons/add.svg" /> **Crear**: Crear una nueva regla.

<img src="/static/images/icons/edit.svg" /> **Editar**: Edita la configuración general de la
regla seleccionada.

<img src="/static/images/icons/delete.svg" /> **Borrar**: Elimina la regla seleccionada.

<img src="/static/images/icons/catalog-folder.svg" /> **Workflow**: Organiza las reglas
basadas en su tipología.

<img src="/static/images/icons/restart_new.svg" /> **Activar**: Activa la regla seleccionada.

<img src="/static/images/icons/wrench.svg" /> **Herramientas**: <img src="/static/images/icons/import.svg" />
Importa o <img src="/static/images/icons/export.svg" /> Exporta la regla seleccionada en formato YAML
para ser utilizado en otros sistemas Clarive.

### Árbol de regla

Se trata del área donde se muestra la estructra de la regla como un árbol.
En la barra de herramientas existen varias opciones:

<img src="/static/images/icons/search-small.svg" /> **Cuadro de búsqueda**: Busca los campos
que coinciden con la búsqueda.

<img src="/static/images/icons/refresh.svg" /> **Refresca**: Refresca la regla.

<img src="/static/images/icons/save.svg" /> **Guardar**: Guarda la regla.

<img src="/static/images/icons/edit.svg" /> **DSL** - Se abre una nueva ventana con el código
DSL de la regla seleccionada. Este código puede ser ejecutado. El funcionamiento de esta opción
está descrito en la [Paleta de reglas](rules/rule-menu).

<img src="/static/images/icons/wrench.svg" /> **Herramientas**:

- <img src="/static/images/icons/import.svg" /> **Importar YAML**: Importar una regla
desde YAML.
- <img src="/static/images/icons/import.svg" /> **Importar desde Fichero**: Importar
una regla desde un fichero
- <img src="/static/images/icons/downloads_favicon.svg" /> **Exportar YAML**: Exportar
una regla en formatp YAML.
- <img src="/static/images/icons/downloads_favicon.svg" /> **Exportar a Fichero**: Exportar
una regla a un fichero.

### Algunas opciones adicionales

**Expresión regular**: Permite buscar por expresión regular.

**Ignorar mayúsculas**: Permite realizar una búsqueda ignorando las mayúsculas.

**Atribuir por tiempo**: Marcar los cambios en los elementos durante un periodo de
tiempo especificado.

<img src="/static/images/icons/expandall.svg" /> **Expandir todo**: Expande todos los
componentes de la regla.

<img src="/static/images/icons/collapseall.svg" /> **Collapsa todo**: Collapsa todos
los componentes de la regla.

<img src="/static/images/icons/history.svg" /> **Version**: Expande toda el historial de
versiones de la regla. Muestra las fechas, la hora y el usuario que guardó la regla.

<img src="/static/images/icons/views.svg" /> **Vistas**:

- <img src="/static/images/icons/html.svg" /> **HTML**: Muestra en otra pestaña de navegación,
valores de propiedades y configucación por cada operación incluida en la regla seleccionada
- <img src="/static/images/icons/workflow.svg" /> **Flujo de Trabajo**: Muestra el árbol de
la regla.

Cada operación está indentada como son contruidas las reglas.


### Paleta

Contiene todas las operaciones que pueden ser utilizadas para componer una regla.

En esta sección se dispone de dos opciones:

<img src="/static/images/icons/search-small.svg" /> **Búsqueda**: Permite buscar entre
los componentes de la paleta.

<img src="/static/images/icons/refresh.svg" /> **Refrescar**: Refresca la paleta.
