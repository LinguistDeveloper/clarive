---
title: Administración de grupos de usuarios
index: 5000
icon: users
---

Los grupos de usuarios permiten la administración fácil de la seguridad de usuarios. En el momento que
un usuario pertenece a un grupo su definición de seguridad se gestionará a través de sus grupos. Si se cambia
la seguridad de un grupo, se modificará la seguridad de todos los usuarios miembros del grupo.

Si un usuario es miembro de varios grupos, su seguridad se calculará combinando la seguridad de todos los grupos de los
que es miembro.

La lista de grupos tiene las siguientes columnas:

- `Grupo` - Nombre del grupo
- `Usuarios`- Lista de usuarios miembros del grupo

### <img src="/static/images/icons/add.svg" /> Creación de grupos de usuarios

- `Grupo` - Nombre del grupo
- `Usuarios`- Lista de usuarios miembros del grupo

Bajo estos campos, se muestran los roles definidos en la base de datos en el cuadro de la izquierda mientras que los [ámbitos](concepts/scope)
disponibles se muestran en la tabla de la derecha.

**NOTA IMPORTANTE**: La asignación de roles sólo está disponible para grupos guardados.
Guárdelo antes de añadir roles.

Para añadir uno o varios roles a un grupo, se marcan los roles deseados en la parte izquierda de la ventana y los proyectos en la parte derecha. A continuación pulsar en `Asignar roles/proyectos`. El rol se mostrará en la tabla inferior de la ventana.

Para desasignar un rol o un proyecto a un grupo, se puede realizar de varias maneras, por ejemplo:

- Para desasignar un rol de todos los proyectos de Clarive a un grupo, hay que marcar la fila y pulsar <img src="/static/images/icons/delete_red.svg" />.
- Para desasignar un rol de un proyecto en concreto, hay que marcar el rol en la lista de Roles y marcar el proyecto en la lista de proyectos. A continuación pulsar <img src="/static/images/icons/key_delete.svg" />.
- Para desasignar todos los roles de un proyecto en concreto, hay que marcar el proyecto en la lista de proyectos y pulsar <img src="/static/images/icons/key_delete.svg" />.
- Para desasignar todos los roles de un grupo, hay que pulsar <img src="/static/images/icons/del_all.svg" />.

#### <img src="/static/images/icons/edit.svg" /> Editar un grupo

Permite editar el grupos seleccionado. Al seleccionar un grupo, el botón `Editar` se habilitará. Una vez pulsado, se abrirá la ventana de creación de grupo con los datos del formulario completados.


#### <img src="/static/images/icons/delete.svg" /> Borrar un grupo

Permite eliminar al grupo seleccionado. El sistema notificará con un mensaje de confirmación antes de proceder al borrado.


#### <img src="/static/images/icons/copy.svg" /> Duplicar un grupo

Permite duplicar el grupo seleccionado. Se creará un nuevo grupo con los mismos valores que el original así como los mismos roles. El nombre de grupo es el mismo pero con la cadena 'Duplicado de' al principio del nombre.
