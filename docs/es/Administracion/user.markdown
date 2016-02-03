---
title: Administracion de usuarios
icon: user.gif
---
* Los usuarios de Clarive se almacenan directamente en la base de datos. Aunque el sistema de autentificación sea de tipo externo,los usuarios deben crearse en la base de datos de Clarive para que puedas ser usados.
* El administrador de usuarios puede acceder a la configuración de los mismos a través de Administración → <img src="/static/images/icons/user.gif" /> Usuarios. Se abrirá una nueva pestaña con una tabla con todos los usuarios existentes en Clarive.


## Columnas
* Las columnas, al igual que el resto de tablas de Clarive, permiten cambiar el orden ascendente/descendente haciendo click en la columna que se quiera ordenar así como mostrar u ocultar las columnas deseadas.<br />
* En la tabla de usuarios, se muestran las siguientes columnas: <br />

&nbsp; &nbsp;• `Avatar`: El avatar del usuario. <br />

&nbsp; &nbsp;• `Usuario`: El id del usuario, usado para acceder al sistema. <br />

&nbsp; &nbsp;• `Nombre`: Nombre completo del usuario. <br />

&nbsp; &nbsp;• `Alias`: Sobrenombre del usuario. <br />

&nbsp; &nbsp;• `Idioma`: Idioma elegido para el usuario. <br />

&nbsp; &nbsp;• `Modificado`: Fecha de la última modificación realizada al usuario. <br /> 

&nbsp; &nbsp;• `Correo electrónico`: Dirección del correo electrónico del usuario. <br />

&nbsp; &nbsp;• `Teléfono`: Número de teléfono del usuario. <br />


<br />
## Opciones

<br />
#### Búsqueda
* Como todas las tablas de Clarive, el cuadro de búsqueda interno permite realizar búsquedas y/o filtros de manera personalizada. Estas búsquedas están descritas en [Búsqueda avanzada](Primeros_pasos/search-syntax)

<br />
#### <img src="/static/images/icons/add.gif" /> Crear
* Pulsando en crear, se abre una nueva ventana con las opciones necesarias para configurarlo: <br />

&nbsp; &nbsp;• `Usuario`: El nombre del usuario con el que se dará el alta en la herramienta. Usado para acceder a Clarive y con el que se identifica la actividad del usuario dentro de la aplicación. <br />

&nbsp; &nbsp;• `Contraseña`: La contraseña con la que el usuario, accederá a la herramienta. <br />

&nbsp; &nbsp;• `Confirmar contraseña`: Repetir la contraseña elegida en el campo anterior. Usado como medida de seguridad. Para continuar, tiene que ser obligatoriamente igual que la puesta en el campo anterior <br />

&nbsp; &nbsp;• `Alias`: Un sobrenombre para el usuario. <br />

&nbsp; &nbsp;• `Nombre`: Nombre completo del usuario. <br />

&nbsp; &nbsp;• `Teléfono`: Número de teléfono del usuario. <br />

&nbsp; &nbsp;• `Correo electrónico`: Correo electrónico del usuario. <br />

<br />
**NOTA**: Una vez completado el formulario es **necesario** guardar antes de asignar los roles y los proyectos. 

<br />

&nbsp; &nbsp;• `Roles disponibles`: Muestra la lista con todos los roles creados. <br />

&nbsp; &nbsp;• `Proyectos disponibles`: Muestra un listado con todos los proyectos disponibles. <br />


* Para añadir uno o varios roles a un usuario, se marcan los roles deseados en la parte izquierda de la ventana y los proyectos en la parte derecha.
* A continuación pulsar en `Asignar roles/proyectos`. El rol se mostrará en la tabla inferior de la ventana. 
* Para desasignar un rol o un proyecto a un usuario, se puede realizar de varias maneras:

&nbsp; &nbsp;• Para desasignar un rol de todos los proyectos de Clarive a un usuario, hay que marcar la fila y pulsar <img src="/static/images/icons/delete_red.png" />.

&nbsp; &nbsp;• Para desasignar un rol de un proyecto en concreto, hay que marcar el rol en la lista de Roles y marcar el proyecto en la lista de proyectos. A continuación pulsar <img src="/static/images/icons/key_delete.png" />.

&nbsp; &nbsp;• Para desasignar todos los roles de un proyecto en concreto, hay que marcar el proyecto en la lista de proyectos y pulsar <img src="/static/images/icons/key_delete.png" />. <br />


&nbsp; &nbsp;• Para desasignar todos los roles de un usuario, hay que pulsar <img src="/static/images/icons/del_all.png" />.  <br />


<br />
#### <img src="/static/images/icons/edit.gif" /> Editar

* Permite editar el usuarios seleccionado.
* Al seleccionar un usuario, el botón `Editar` se habilitará. Una vez pulsado, se abrirá la ventana de creación de usuario con los datos del formulario completados.


<br />
#### <img src="/static/images/icons/delete_.png" /> Borrar
* Permite eliminar al usuario seleccionado. 
* El sistema notificará con un mensaje de confirmación antes de proceder al borrado.


<br />
#### <img src="/static/images/icons/copy.gif" /> Duplicar

* Permite duplicar el usuario seleccionado. 
* Se creará un nuevo usuario con los mismos valores que el original así como los mismos roles. El nombre de usuario es el mismo pero con la cadena 'Duplicado de' al principio del nombre. 
* Tras duplicar un rol es **recomendable** cambiar el nombre y los valores del mismo.

<br />
#### <img src="/static/images/icons/prefs.png" /> Preferencias
* Permite al administrador cambiar las preferencias del usuario tales como el idioma o el avatar.
* El menu de acceso es el que el usuario tiene a su disposición. Para saber más sobre este menú, puede consultar [la ayuda](Primeros_pasos/prefs).
* El administrador puede cambiar preferencias del usuario tales como el lenguaje o el avatar, seleccionando al usuario y cliqueando en el botón Preferencias.



<br />
#### <img src="/static/images/icons/surrogate.png" /> Impersonar
* Permite al administrador 'tomar' el perfil del usuario seleccionado.
* Se trata de una funcionalidad muy útil para comprobar los permisos que tiene el usuario.

<br />
#### <img src="/static/images/icons/envelope.png" /> Buzón
* Permite acceder al buzón de notificaciones del usuario.