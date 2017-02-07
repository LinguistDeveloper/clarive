---
title: Administración de usuarios
index: 5000
icon: user
---

Los usuarios de Clarive se almacenan directamente en la base de datos. Aunque el sistema de autenticación sea de tipo externo,los usuarios deben crearse en la base de datos de Clarive para que puedas ser usados.

El administrador de usuarios puede acceder a la configuración de los mismos a través de Administración - <img src="/static/images/icons/user.svg" /> Usuarios.

En la tabla de usuarios, se muestran las siguientes columnas:

- `Avatar` - El avatar del usuario.
- `Usuario` - El id del usuario, usado para acceder al sistema.
- `Nombre` - Nombre completo del usuario.
- `Alias` - Sobrenombre del usuario.
- `Idioma` - Idioma elegido para el usuario.
- `Modificado` - Fecha de la última modificación realizada al usuario.
- `Correo electrónico` - Dirección del correo electrónico del usuario.
- `Teléfono` - Número de teléfono del usuario.

### <img src="/static/images/icons/add.svg" /> Crear

Pulsando en crear, se abre una nueva ventana con las opciones necesarias para configurarlo:

- `Usuario` - El nombre del usuario con el que se dará el alta en la herramienta. Usado para acceder a Clarive y con el que se identifica la actividad del usuario dentro de la aplicación.
- `Tipo de cuenta` - Establece el tipo de cuenta del usuario. Actualmente existen dos tipos:
       - Regular - La que se usa de manera general para los usuarios. Permite acceder a todas las funcionalidades de Clarive en función del rol de cada uno.
       - Sistema - Usuarios que no pueden acceder a Clarive pero si interactuar con la herramienta a través, por ejemplo, de reglas. Este tipo de usuarios no cuenta para el limite de usuarios por licencia de Clarive.
- `Contraseña` - La contraseña con la que el usuario, accederá a la herramienta.
- `Confirmar contraseña` - Repetir la contraseña elegida en el campo anterior. Usado como medida de seguridad. Para continuar, tiene que ser obligatoriamente igual que la puesta en el campo anterior
- `Alias` - Un sobrenombre para el usuario.
- `Nombre` - Nombre completo del usuario.
- `Teléfono` - Número de teléfono del usuario.
- `Correo electrónico` - Correo electrónico del usuario.

Una vez completado el formulario es **necesario** guardar antes de asignar los roles y los proyectos.

Bajo estos campos, se muestran los roles definidos en la base de datos en el cuadro de la izquierda mientras que los [ámbitos](concepts/scope) disponibles se muestran en la tabla de la derecha.

**NOTA IMPORTANTE**: La asignación de roles a usuarios sólo está disponible para usuarios guardados.
Guárdelo antes de añadir roles.

**NOTA IMPORTANTE 2**: Si un usuario pertenece a algún grupo, su seguridad no se puede gestionar individualmente sino
que será el resultado de combinar las seguridades de todos los grupos a los que pertenece.

Para añadir uno o varios roles a un usuario, se marcan los roles deseados en la parte izquierda de la ventana y los proyectos en la parte derecha. A continuación pulsar en `Asignar roles/proyectos`. El rol se mostrará en la tabla inferior de la ventana.

Para desasignar un rol o un proyecto a un usuario, se puede realizar de varias maneras, por ejemplo:

- Para desasignar un rol de todos los proyectos de Clarive a un usuario, hay que marcar la fila y pulsar <img src="/static/images/icons/delete-grid-row.svg" />.
- Para desasignar un rol de un proyecto en concreto, hay que marcar el rol en la lista de Roles y marcar el proyecto en la lista de proyectos. A continuación pulsar <img src="/static/images/icons/key-delete.svg" />.
- Para desasignar todos los roles de un proyecto en concreto, hay que marcar el proyecto en la lista de proyectos y pulsar <img src="/static/images/icons/key-delete.svg" />.
- Para desasignar todos los roles de un usuario, hay que pulsar <img src="/static/images/icons/delete-grid-all-rows.svg" />.

#### <img src="/static/images/icons/edit.svg" /> Editar un usuario

Permite editar el usuarios seleccionado. Al seleccionar un usuario, el botón `Editar` se habilitará. Una vez pulsado, se abrirá la ventana de creación de usuario con los datos del formulario completados.


#### <img src="/static/images/icons/delete.svg" /> Borrar un usuario

Permite eliminar al usuario seleccionado. El sistema notificará con un mensaje de confirmación antes de proceder al borrado.


#### <img src="/static/images/icons/copy.svg" /> Duplicar un usuario

Permite duplicar el usuario seleccionado. Se creará un nuevo usuario con los mismos valores que el original así como los mismos roles. El nombre de usuario es el mismo pero con la cadena 'Duplicado de' al principio del nombre.


#### <img src="/static/images/icons/prefs.svg" /> Preferencias

Permite al administrador cambiar las preferencias del usuario tales como el idioma, 
el avatar. o consultar la API Key.

El menú de acceso es el que el usuario tiene a su disposición. Para saber más sobre este menú, puede consultar [la ayuda](getting-started/prefs).

#### <img src="/static/images/icons/surrogate.svg" /> Impersonar

Permite al administrador 'tomar' el perfil del usuario seleccionado. Se trata de una funcionalidad muy útil para comprobar los permisos que tiene un usuario.

#### <img src="/static/images/icons/envelope.svg" /> Buzón

Permite acceder al buzón de notificaciones del usuario.

### <img src = "/static/images/icons/about.svg" alt='Licensing' /> Licencia

La licencia de Clarive se basa, generalmente en número de usuarios, excepto las licencias ELA (*Enterprise Level Agreements*).

La creación de nuevos usuarios regulares suelen consumir una de dichas licencias, excepto en el caso de que el usuario esté **inactivo**.

Compruebe el archivo de licencia para más detalles sobre sus límites de usuarios.
