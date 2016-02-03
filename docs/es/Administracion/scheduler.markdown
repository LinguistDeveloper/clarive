---
title: Planificador
icon: calendar
---
* El planificador es una utilidad que permite al administrador a planificar de manera sencilla la ejecución de las reglas en intervalos establecidos.
* Permite planificar, habilitar, deshabilitar o ejecutar reglas independientes en segundo plano, por frecuencia de tiempo o ejecutar a una hora de un día determinado.
* El planificador se compone de una tabla con los planes existentes y un menu de acciones.

## Columnas
* Las columnas, al igual que el resto de tablas de Clarive, permiten cambiar el orden ascendente/descendente haciendo click en la columna que se quiera ordenar asi como mostrar u ocultar las columnas deseadas.<br />

&nbsp; &nbsp;• `Nombre` - El nombre del plan con el log asociado <img src="/static/images/icons/moredata.gif" />. <br />

&nbsp; &nbsp;• `Estado` - Describe el estado actual en el que se encuentra la tarea. Los estados posibles son: <br />

&nbsp; &nbsp;&nbsp; &nbsp;• *Inactivo* - El plan está desactivado. No se ejecuta. <br />

&nbsp; &nbsp;&nbsp; &nbsp;• *Idle* - El plan está activo, se ejecutará la próxima vez que esté programado. <br />

&nbsp; &nbsp;&nbsp; &nbsp;• *En ejecución* - El plan se está ejecutando. <br />

&nbsp; &nbsp;• `Siguiente ejecución` - Indica el momento de la próxima ejecución <br />

&nbsp; &nbsp;• `Última ejecución` - Indica la última vez que la tarea ha sido ejecutada. <br />

&nbsp; &nbsp;• `PID` - El PID asignado durante la última ejecución. <br />

&nbsp; &nbsp;• `Description` - Breve descripción de la tarea <br />

&nbsp; &nbsp;• `Frequency` - Indica la frecuencia con la que la tarea se ejecuta <br />

&nbsp; &nbsp;• `Día` - Indica si la tarea se ejecuta solo los días de diario (indicado con un 1) o todos los dias (indicado con un 0). <br />

&nbsp; &nbsp;• `What` - Muestra el nombre de la regla y el id que es ejecutado en la tarea.


<br />
## Opciones

<br />
#### Búsqueda
* Como todas las tablas de Clarive, el cuadro de búsqueda interno permite realizar búsquedas y/o filtros de manera personalizada. Estas búsquedas están descritas en [Búsqueda avanzada](Primeros_pasos/search-syntax)

<br />
#### <img src="/static/images/icons/add.gif" /> Crear
* Al pulsar en crear una nueva planificación, se abre una nueva ventana con los siguientes campos: <br />

&nbsp; &nbsp;• *Nombre*: Nombre de la tarea. <br />

&nbsp; &nbsp;• *Regla*: Menú de selección para seleccionar la regla independiente que se ejecutará según la planificación. <br />

&nbsp; &nbsp;• *Fecha*: Selección de la fecha para llevar a cabo la ejecución, en caso de no ser puntual, indicar la primera fecha para la ejecución de la tarea. <br />

&nbsp; &nbsp;• *Hora*: Especifica la hora para la ejecución de la tarea. <br />

&nbsp; &nbsp;• *Frecuencia*: En caso de que se quiera que la tarea se repita con una frecuencia determinada, se tiene que especificar en este campo. Los parámetros a utilizar en este campo son: <br />
&nbsp; &nbsp;&nbsp; &nbsp;• `H` - Indica la hora, por ejemplo, para una tarea que se quiera repetir cada dos horas: `2H`. <br />
&nbsp; &nbsp;&nbsp; &nbsp;• `m` - Indica  los minutos entre ejecuciones, por ejemplo, para una tarea que se quiera repetir cada 20 minutos: `20m`. <br />
&nbsp; &nbsp;&nbsp; &nbsp;• `d` - Indica el número de días entre ejecuciones. Para una tarea que se repita de manera diaria: `1D`. <br />

&nbsp; &nbsp;• *Sólo días de diario*: Si se quiere que la ejecución se lleve a cabo solo entresemana (de Lunes a Viernes) hay que activar esta opción

<br />
#### <img src="/static/images/icons/edit.gif" /> Editar
* Permite editar la tarea seleccionada. 
* La ventana de edición es la misma que la de creación de tarea.


#### <img src="/static/images/icons/delete_.png" /> Borrar
* Permite borrar la tarea seleccionada.


<br />
#### <img src="/static/images/icons/copy.gif" /> Duplicar
* Permite duplicar con los mismos datos la tarea seleccionada.

<br />
### <img src="/static/images/icons/start.png" />  Activar
* En caso de que la tarea esté inactiva, será posible activar la tarea a través de esta acción.
* De esta manera la tarea pasará a estar activa y se ejecutará la próxima vez en función a su planificación.


<br />
### <img src="/static/images/icons/stop.png" />  Desactivar
* Si la tarea está activa, es posible desactivarla para que no se vuelva a ejecutar de forma automática.


<br />
### <img src="/static/images/icons/start.png" />  Ejecutar ahora 
* La tarea se ejecutará en ese mismo momento, sin esperar a la próxima fecha estimada.
* Esta opción está disponible independientemente del estado de la tarea. 