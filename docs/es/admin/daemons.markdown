---
title: Administracion de demonios
icon: daemon
---
* Un demonio es un programa informático que se ejecuta como un proceso en segundo plano, en lugar de estar bajo el control directo de un usuario interactivo.
* En Clarive, los demonios son especiales, los procesos independientes los inicia el [Dispatcher](admin/dispatcher).
* Realizan operaciones criticas para el correcto funcionamiento de la herramienta. Entre las funciones que poseen destacan:
    Ejecución de pases.
    Procesamiento de eventos.
    [Notificaciones](admin/notifications).
    Ejecuciones [planificadas](admin/scheduler).
    Control de semáforos.

* Para poder ver y administrar los demonios es necesario tener permisos de Administración.
* A la lista de demonios se accede a través del menú de Administración → <img src="/static/images/icons/daemon.svg" /> Demonios
* En este panel, el usuario puede ver que demonios se están ejecutando y cuales están parados.
* A continuación se describen los procesos estandar, demonios que deberian estar arrancandos tras realizar una instalación de Clarive.
    `service.daemon.email` - Demonio responsable del envío de notificaciones.
    `service.event.daemon` - Responsable de la gestión de eventos que se producen en la herramienta.
    `service.job.daemon` - Necesario para la ejecución de pases.
    `service.purge.daemon` - Responsable de que la purga se realiza de manera satisfactoria.
    `service.schedule daemon` - Demonio necesario para la correcta ejecución del planificador.
    `service.sem.daemon` - Responsable de la gestión y control de los semáforos.

### Opciones

Las acciones disponibles dentro de la ventana de Demonios son las siguientes:

<img src="/static/images/icons/add.svg" /> **Crear**: Crear un nuevo demonio asociado al [dispatcher](admin/dispatcher).

<img src="/static/images/icons/edit.svg" /> **Editar**: Permite modificar la configuración el demonio seleccionado.

<img src="/static/images/icons/delete.svg" /> **Eliminar**: Elimina un demonio seleccionado en la lista.

<img src="/static/images/icons/start.svg" /> **Activar**: Inicia un demonio que está desactivado.

<img src="/static/images/icons/stop.svg" /> **Desctivar**: Desactiva un demonio que se está ejecutando.
