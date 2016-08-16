---
title: Administracion de roles
icon: role.svg
---
* La seguridad de Clarive se gestiona a través del [sistema de roles](Conceptos/roles).
* Todos los accesos y funciones que puede desempeñar un usuario o administrador se definen a través de roles.
* Los usuarios pueden tener uno o mas roles definidos. Esto hace que el acceso a Clarive por parte de un usuario esté limitado y controlado. 

&nbsp; &nbsp;• **Ejemplo**: Un rol de administrador puede estar definido con todos los privilegios que puede tener un administrador estandar, [administrador de tópicos](Administracion/topics), [administración de notificaciones](Administracion/notifications), [acceso al planificador](Administracion/scheduler), [gestión de usuarios](Administracion/user), etc...Un gestor de incidencias puede estar definido por ejemplo con acceso completo a la categoría Incidencia pero sin accesos a otros tópicos como 'Factura' que podrá ser administrador por otro rol tipo "Jefe de RRHH".

* Un usuario puede tener mas de un rol de tal manera que pueda acceder a más temas donde trabajar.
* La administración de roles se realiza a través de la ruta Administración → <img src="/static/images/icons/role.svg" /> Roles. Esto mostrará un listado con todos los roles creados y una barra de acciones. 

<br />
## Columnas
* Las columnas, al igual que el resto de tablas de Clarive, permiten cambiar el orden ascendente/descendente haciendo click en la columna que se quiera ordenar así como mostrar u ocultar las columnas deseadas.<br />

&nbsp; &nbsp;• `Rol`: El nombre del rol. <br />

&nbsp; &nbsp;• `Descripción`: La descripción del rol. <br />

&nbsp; &nbsp;• `Buzón`: Buzón al que pertenece el rol. Útil para las [notificaciones](Administracion/notifications). <br />

&nbsp; &nbsp;• `Opciones`: Resumen de las acciones del rol.


<br />
## Opciones

<br />
#### Búsqueda
* Como todas las tablas de Clarive, el cuadro de búsqueda interno permite realizar búsquedas y/o filtros de manera personalizada. Estas búsquedas están descritas en [Búsqueda avanzada](Primeros_pasos/search-syntax)

<br />
#### <img src="/static/images/icons/add.svg" /> Crear
* Pulsando en crear, se abre una nueva ventana con las opciones necesarias para configurarlo:<br />

&nbsp; &nbsp;• **Nombre del rol**: El nombre que define el rol, por ejemplo, *desarrollador*, *Release manager*, etc...<br />

&nbsp; &nbsp;• **Descripción**: Una breve descripción del papel que desempeña el rol. <br />

&nbsp; &nbsp;• **Dashboard**: Clarive dispone de un sistema de [dashboards](Conceptos/dashboards). Aquí se pueden asociar los dashboards con roles de tal manera que en las [preferencias de usuario](Primeros_pasos/prefs) solo aparecerán los dashboards que estén asociados sus roles. El primer dashboard que se añada, será el dashboard por defecto. Cada usuario podrá cambiar su dashboard por defecto en las preferencias del usuario.


<br />
#### Acciones
* **Panel izquierdo** - Compuesto de tres pestañas:

&nbsp; &nbsp;• *Acciones disponibles* - Muestra todas las acciones que ofrece Clarive. Éstas están agrupadas de manera que sea más fácil e intuitivo localizar una acción en concreto:<br />

&nbsp; &nbsp;&nbsp; &nbsp;• `Admin`: Todas las acciones relacionadas con la administración de la herramienta; administración de tópicos, administración de usuarios, etc...<br />

&nbsp; &nbsp;&nbsp; &nbsp;• `Artefactos`: Todas las acciones relacioadas con los artefactos. <br />

&nbsp; &nbsp;&nbsp; &nbsp;• `Calendario`: Agrupan todas las acciones relacionadas con el planificador de despliegues. <br />

&nbsp; &nbsp;&nbsp; &nbsp;• `CI`: Todas las acciones relacionadas con los elementos de configuración. Estas acciones están divididas en dos grupos:<br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp;• `admin` - Se muestran todos las acciones relacionadas con la administración de CIs. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp;• `Vistas` - Acciones relacionadas con las visualizaciones de los CIs. <br />

&nbsp; &nbsp;&nbsp; &nbsp;• `Dashboards`: Acciones relacionadas con los dashboards como por ejemplo, dar permiso al usuario a cambiar el dashboard por defecto. <br />

&nbsp; &nbsp;&nbsp; &nbsp;• `Desarrollo`: Acciones relacionadas con el menú de Desarrollo. <br />

&nbsp; &nbsp;&nbsp; &nbsp;• `Git`: Acciones relacionadas con el repositorio Git.<br />

&nbsp; &nbsp;&nbsp; &nbsp;• `Ayuda`: Acciones relacionadas con el menú de ayuda <br />

&nbsp; &nbsp;&nbsp; &nbsp;• `Home`:  Acciones relacionadas con la herramienta como poder tener acceso al panel de ciclo de vida o al menú superior.<br />

&nbsp; &nbsp;&nbsp; &nbsp;• `Job`: Todo lo relacionado con despliegues, posibilidad de crear un nuevo trabajo, reiniciar un despligue, cancelarlo, etc... <br />

&nbsp; &nbsp;&nbsp; &nbsp;• `Etiquetas`: Permite al rol administrar etiquetas.<br />

&nbsp; &nbsp;&nbsp; &nbsp;• `Notificaciones`:  Acciones relacionadas con el sistema de notificaciones. <br />

&nbsp; &nbsp;&nbsp; &nbsp;• `Proyectos`:  Acciones relacionadas con el ciclo de vida de un proyecto. <br />

&nbsp; &nbsp;&nbsp; &nbsp;• `Informes`: Acciones que permiten ver informes, ver los campos dinámicos de un informe, etc...<br />

&nbsp; &nbsp;&nbsp; &nbsp;• `Búsqueda`: Acciones que permiten al rol buscar despliegues, CI's o tópicos.<br />

&nbsp; &nbsp;&nbsp; &nbsp;• `SQA`:  Acciones relacionadas con el portal de calidad. <br />

&nbsp; &nbsp;&nbsp; &nbsp;• `Tópicos`:  Acciones relacionadas con los tópicos. Por cada tópico existen las acciones de ver, crear, eliminar, editar y añadir o ver los comentarios. <br />

&nbsp; &nbsp;&nbsp; &nbsp;• `Campos de un tópico`: Por cada campo de un tópico en un estado específico, la acción puede ser permitir al rol editar un tópico que esté en un determinado estado pero solo visualizarlo cuando está en otro estado. <br />


&nbsp; &nbsp;• *Usuarios* - Permite ver los usuarios que tienen el rol actual (en caso de estar en modo edición de rol) y en que [ámbito](Conceptos/scope) está asignado. <br />

&nbsp; &nbsp;• *Ámbitos* - Es una vista pivotal de la pestaña anterior. Permite ver los usuarios que tienen el rol.<br />

* **Panel derecho** - Indica las acciones que el rol tiene asignadas. Se puede borrar con los dos botones que hay  en la parte derecha del panel: <br />
 
 &nbsp; &nbsp;• <img src="/static/images/icons/delete_red.png" /> *Descartar selección* - Elimina las acciones seleccionadas. </br>
 
 &nbsp; &nbsp;• <img src="/static/images/icons/del_all.png" />  *Descartar todas* - Elimina todas las acciones asociadas al rol.


<br />

<br />
#### <img src="/static/images/icons/edit.svg" /> Editar
* Permite editar el rol selecionado. Una vez realizados los cambios, seleccionar `Aceptar`.
* Si no desea guardar tras editar un rol, seleccione `Cerrar`.

<br />
#### <img src="/static/images/icons/copy.gif" /> Duplicar
* Permite duplicar el rol seleccionado. 
* Se creará un nuevo rol con los mismos valores que el original. Es decir, mismas acciones y dashboards asi como la descripción. El nombre es el mismo pero con un número entero concatenado al final del nombre. 
* Tras duplicar un rol es **recomendable** cambiar el nombre y la descripción del mismo.

<br />
#### <img src="/static/images/icons/delete_.png" /> Eliminar
* Elimina uno o varios roles seleccionados. El sistema pedirá confirmación de ello antes de eliminarlo. 
* Si se borrar un rol que está asignado a un usuario, el rol también se eliminará del usuario.