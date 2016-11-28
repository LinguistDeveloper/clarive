---
title: Administración de roles
index: 5000
icon: role
---

La seguridad de Clarive se gestiona a través del [sistema de roles](concepts/roles).

Todos los accesos y funciones que puede desempeñar un usuario o administrador se definen a través de roles. Los usuarios pueden tener uno o mas roles definidos. Esto hace que el acceso a Clarive por parte de un usuario esté limitado y controlado.

**Ejemplo**

Un rol de administrador puede estar definido con todos los privilegios que puede tener un administrador estándar, [administrador de categorías](admin/categories), [administración de notificaciones](admin/notifications), [acceso al planificador](admin/scheduler), [gestión de usuarios](admin/user), etc...
Un gestor de incidencias puede estar definido por ejemplo con acceso completo a la categoría Incidencia pero sin accesos a otros tópicos como 'Factura' que podrá ser administrador por otro rol tipo "Jefe de RRHH".

Un usuario puede tener mas de un rol de tal manera que pueda acceder a más temas donde trabajar.

La administración de roles se realiza a través de la ruta Administración - <img src="/static/images/icons/role.svg" /> Roles.
Esto mostrará un listado con todos los roles creados y una barra de acciones.

La lista contiene las siguientes columnas:

- `Rol` - El nombre del rol.
- `Descripción` - La descripción del rol.
- `Buzón` - Buzón al que pertenece el rol. Útil para las [notificaciones](admin/notifications).
- `Opciones` - Resumen de las acciones del rol.


## Opciones de la lista de roles


### <img src="/static/images/icons/add.svg" /> Crear

 Pulsando en crear, se abre una nueva ventana con las opciones necesarias para configurarlo:

 - **Nombre del rol** - El nombre que define el rol, por ejemplo, *desarrollador*, *Release manager*, etc...
- **Descripción** - Una breve descripción del papel que desempeña el rol.
- **Dashboard** - Clarive dispone de un sistema de [dashboards](concepts/dashboards). Aquí se pueden asociar los dashboards con roles de tal manera que en las [preferencias de usuario](getting-started/prefs) solo aparecerán los dashboards que estén asociados sus roles. El primer dashboard que se añada, será el dashboard por defecto. Cada usuario podrá cambiar su dashboard por defecto en las preferencias del usuario.


### Acciones disponibles

Todas las acciones disponibles se muestran en el panel izquierdo, las acciones al rol
se muestran en el panel izquierdo. Un grupo de acciones o una acción específica se pueden añadir seleccionándola y arrastrando desde el panel izquierdo al panel derecho.

- **Descartar selección** <img src="/static/images/icons/delete-red.svg" /> - Elimina las acciones seleccionadas.
- **Descartar todas** <img src="/static/images/icons/del-all-red.svg" /> - Elimina todas las acciones asociadas al rol.

## Usuarios que tienen un rol

Permite ver los usuarios que tienen el rol actual (en caso de estar en modo edición de rol) y en que [ámbito](concepts/scope) está asignado.

## Ámbitos que tiene usuarios con un rol asignado

Es una vista pivotal de la pestaña anterior. Permite ver los usuarios que tienen el rol.

## Acciones

Las acciones están agrupadas para una mejor localización de las mismas. Los grupos de acciones son los siguientes:

- `admin` - Todas las acciones relacionadas con la administración de la herramienta; administración de categorías, administración de usuarios, etc...
- `calendar` - Agrupan todas las acciones relacionadas con el planificador de despliegues.
- `catalog` - Acciones relacionadas con el catálogo.
- `ci` - Todas las acciones relacionadas con los elementos de configuración. Se pueden dar permisos para administrar o ver. El permiso administrar también da permisos para ver los CIs por lo que no es necesario añadir los dos. Para especificar los CIs, hay que arrastrar la acción. En la ventana nueva, seleccionar los roles y las colecciones que el usuario puede ver/administrar. Es posible añadir también filtros negativos. Por ejemplo, en caso de que el usuario pueda ver todos los CIs menos la colección Proyecto, se puede añadir Todos los roles y luego un filtro negativo para dicha colección.
- `dashboards` - Acciones relacionadas con los dashboards como por ejemplo, dar permiso al usuario a cambiar el dashboard por defecto.
- `development` - Acciones relacionadas con el menú de Desarrollo.
- `git` - Acciones relacionadas con el repositorio Git.
- `help` - Acciones relacionadas con el menú de ayuda.
- `home` -  Acciones relacionadas con la herramienta como poder tener acceso al panel de ciclo de vida o al menú superior.
- `jobs` - Todo lo relacionado con despliegues, posibilidad de crear un nuevo trabajo, reiniciar un despligue, cancelarlo, etc... Una vez añadido, es posible filtrar los jobs por entorno, añadiendo o denegando las acciones en la ventana de configuración de la acción.
- `labels` - Permite al usuario realizar acciones tales como añadir una etiqueta o eliminarla de un tópico.
- `notify` -  Acciones relacionadas con el sistema de notificaciones.
- `project` - Acciones relacionadas con el ciclo de vida de un proyecto.
- `report` - Acciones que permiten ver informes o ver los campos dinámicos de un informe.
- `search` - Acciones que permiten al rol buscar jobs, CIs o tópicos.
- `topics` - Permite al usuario ver tópicos, eliminar tópicos, crear un tópico, añadir comentarios en los tópicos, etc... Una vez que la acción es arrastrada, es posible filtrar para que el usuario solo pueda realizar dicha acción para determinadas categorías.
- `topicsfield` - Permite configurar las acciones para ver y/o editar los campos de los tópicos. Es posible configurarlos en función de la categoría y el estado del tópico. Tan solo hace falta añadir la categoría, el estado y el campo para que el usuario pueda interactuar con el mismo. También es posible realizar filtros en negativo, por ejemplo, dotar a un usuario de permisos para ver todos los campos de una categoría menos el campo 'Estimación'. Para ello, se le asigna permisos para ver todos los campos de esa categoría y se le asigna un filtro negativo para el campo 'Estimación'.

Para cada campo en cada tópico en cualquier estado, esta acción debe de ser añadida para poderse habilitar el campo.

### <img src="/static/images/icons/edit.svg" /> Editar

Permite editar el rol seleccionado. Una vez realizados los cambios, seleccionar `Aceptar`.

Si no desea guardar tras editar un rol, seleccione `Cerrar`.

### <img src="/static/images/icons/copy.svg" /> Duplicar

Permite duplicar el rol seleccionado.

Se creará un nuevo rol con los mismos valores que el original. Es decir, mismas acciones y dashboards así como la descripción. El nombre es el mismo pero con un número entero concatenado al final del nombre.

### <img src="/static/images/icons/delete.svg" /> Eliminar

Elimina uno o varios roles seleccionados. El sistema pedirá confirmación de ello antes de eliminarlo.

Si se borrar un rol que está asignado a un usuario, el rol también se eliminará del usuario.