---
title: Administracion de demonios
icon: daemon.gif
---

* Un demonio es un programa informático que se ejecuta como un proceso en segundo plano, en lugar de estar bajo el control directo de un usuario interactivo.

* En Clarive, los demonios son especiales, los procesos independientes los inicia el [Dispatcher](Administracion/dispatcher). 

* Realizan operaciones criticas para el correcto funcionamiento de la herramienta. Entre las funciones que poseen destacan: <br />

&nbsp; &nbsp;• Ejecución de pases. <br />

&nbsp; &nbsp;• Procesamiento de eventos. <br />

&nbsp; &nbsp;• [Notificaciones](Administracion/notifications). <br />

&nbsp; &nbsp;• Ejecuciones [planificadas](Administracion/scheduler). <br />

&nbsp; &nbsp;• Control de semáforos.

* Para poder ver y administrar los demonios es necesario tener permisos de Administración. 

* A la lista de demonios se accede a través del menú de Administración → <img src="/static/images/daemon.gif" /> Demonios

* En este panel, el usuario puede ver que demonios se están ejecutando y cuales están parados.



* A continuación se describen los procesos estandar, demonios que deberian estar arrancandos tras realizar una instalación de Clarive. <br />

&nbsp; &nbsp;• `service.daemon.email` - Demonio responsable del envío de notificaciones. <br />

&nbsp; &nbsp;• `service.event.daemon` - Responsable de la gestión de eventos que se producen en la herramienta. <br />

&nbsp; &nbsp;• `service.job.daemon` - Necesario para la ejecución de pases. <br />

&nbsp; &nbsp;• `service.purge.daemon` - Responsable de que la purga se realiza de manera satisfactoria. <br />

&nbsp; &nbsp;• `service.schedule daemon` - Demonio necesario para la correcta ejecución del planificador. <br />

&nbsp; &nbsp;• `service.sem.daemon` - Responsable de la gestión y control de los semáforos.


<br />
### Opciones

Las acciones disponibles dentro de la ventana de Demonios son las siguientes: <br />

<img src="/static/images/icons/add.gif" /> **Crear**: Crear un nuevo demonio asociado al [dispatcher](Administracion/dispatcher).<br />

<img src="/static/images/icons/edit.gif" /> **Editar**: Permite modificar la configuración el demonio seleccionado. <br />

<img src="/static/images/icons/delete.gif" /> **Eliminar**: Elimina un demonio seleccionado en la lista. <br />

<img src="/static/images/icons/start.png" /> **Activar**: Inicia un demonio que está desactivado. <br />

<img src="/static/images/icons/stop.png" /> **Desctivar**: Desactiva un demonio que se está ejecutando.
