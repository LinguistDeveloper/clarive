---
title: Monitorizar los pases
index: 1000
---

El monitor de pases de Clarive mantiene la trazabilidad de todos los pases que
se están ejecutando en el sistema en una única e integrada interfaz.

Cada pase que se muestra en el monitor enlaza al dashboard del pase y a la
ventana de log para obtener los detalles completos de lo que el pase está
ejecutando o ha ejecutado.

## Campos y datos del Monitor

#### Estados del pase

Esta lista describe brevemente los posibles estados de un job:

- `Listo` - el pase está esperando a ser ejecutado por el demonio, esto puede
  suceder en cualquier momento excepto en el paso `RUN` que se ejecutará en la
fecha planificada.
- `Ejecutando` - el pase se está ejecutando.
- `Pendiente de aprobación` - el pase está esperando a la aprobación de un
  usuario para aprobar o rechazar el pase desde el monitor.
- `Rechazado` - El usuario ha rechazado el pase. El pase queda parado a menos
  que se tome otra medida.
- `Expirado` - la fecha y la hora es mayor que la fecha indicada en `Fecha de
  inicio Max`.  por lo que el pase en el paso `RUN` ha sido cancelado.
- `Abend` - El demonio de pases no puede encontrar el proceso en el servidor por
  lo que se marca como proceso abortado.
- `Rollback` - el pase está ejecutando una operación de rollback.
- `Finalizado` - el pase se ha terminado de ejecutar.
- `Error` - el pase ha finalizado con un error en alguno de los pasos
  ejecutados.
- `Cancelado` - el job ha sido cancelado por un usuario cuando se estaba
  ejecutando.
- `Capturado` - un error ha sido capturado y está esperando a la acción del
  usuario.
- `Capturado en pausa` - el usuario ha decido pausar el timeout de la captura.

Siempre es recomendable comprobar la columna `Paso` para saber donde está el
pase en un momento determinado.

#### Pasos de un pase

Los pasos de un pase indican en que fase se encuentra un job que va a ser
ejecutado (o se está ejecutando) por el demonio de jobs en un momento dado.

- `CHECK` - este paso es previo a la creación del job en la base de datos y no
  es visible en el monitor.
- `INIT` - el job acaba de ser creado pero el usuario aún está esperando a la
  confirmación.  Este paso ya es visible en el monitor.
- `PRE` - durante este paso, el pase ejecutará toda la preparación que no afecte
  a entornos destino, como la construcción de una aplicación o la ejecución de
tests.
- `RUN` - este paso contiene la lógica de la regla que se va a ejecutar en el
  tiempo planificado.

- `POST` - es el paso final de la cadena de un pase. Este paso se ejecuta
  independientemente del resultado producido en los pasos anteriores.

#### Progreso de un pase

El progreso se calcula contando el número total de operaciones contra los pases
con la misma regla que ya se han ejecutado. Esto no incluye los bucles que pueda
tener la regla por lo que el progreso puede no ser preciso al 100%, pero da una
idea de cuanto puede tardar un pase en ejecutarse.


#### Naturalezas del pase

Una vez que el contenido del pase se ha determinado, Clarive parsea todas las
revisiones y determina que naturalezas tienen que ser incluidas.

Por lo tanto, esta información no tiene por que estar disponible después de la
creación del job.

#### Fechas de un pase

- `Fecha de inicio` - la fecha real cuando el pase inicia el paso `PRE`.
- `Fecha de fin` - la fecha real cuando el job alcanza el paso `END`.e
- `Fecha planificada` - la fecha cuando está estimado que el paso `RUN`
  comience.
- `Max fecha de inicio` - si el job no comienza ese día, se marca como
  `Expirado` de manera automática por el demonio de pases.

## Acciones del Monitor

Desde el Monitor de jobs, puede controlar que ocurre con cada ejecución de los
pases, como iniciarlos manualmente, cancelarlos, eliminarlos, reiniciarlos,
etc...

Estas acciones requieren tener los permisos adecuados, los cuales se describen
en este mismo articulo más adelante.


### Reiniciar

Permite establecer el pase a `Listo` en el pase deseado para su reejecución.

Habitualmente, la reejecución de un pase suele comenzar en los pasos `PRE` o
`RUN` para repetir fases de construcción o despliegue.

Además, el paso `POST`puede ser reiniciado para rehacer cosas como reenviar
notificaciones o promociones

**NOTA**: Si reinicia un paso, todos los pasos siguientes también serán
reejecutados con el siguiente comportamiento:

- Si el paso `PRE`es reiniciado, el paso `RUN` seguirá preservando su estado y
  será ejecutado en la fecha programada.
- Si el paso `RUN` es reiniciado, la fecha de inicio planificada puede ser
  sobrescrita con la opción `Ejecutar ahora`.

### Replanificar

Los pases que están en `Listo`, `Expirado` o `Pendiente de aprobación` pueden
ser replanificados, lo que significa poder establecer una nueva fecha para que
el paso `RUN`se ejecute.

### Expiración de un pase

Un pase expira de manera automática cuando la `Fecha planificada` es mayor que
la `Max fecha de inicio`. El propósito de expirar pases es prevenir un
despliegue más allá que una interrupción del sistema o de un tiempo de
inactividad.

### Cancelar pases

Los pases en estado `En ejecución` pueden ser cancelados. Esto finalizará el job
de manera inmediata en el servidor de Clarive, pero **no evita** que los
procesos se ejecuten.

#### Gestión de pases expirados

Si un pase ha expirado, no se vuelve a ejecutar. Sin embargo, utilizando las
acciones del monitor, el operador tiene dos opciones disponibles para lanzar un
pase expirado:

- Reiniciar el job en el paso `PRE`o `RUN`.
- Replanificar el job para otra fecha.

### Permisos

- `action.job.view_monitor` - permite al rol ver los pases en el monitor para
  los entornos autorizados.
- `action.job.approve_all` - permite aprobar cualquier pase, aunque no esté en
  la lista de aprobación.
- `action.job.restart` - permite reiniciar un pase.
- `action.job.cancel` - permite cancelar un pase.
- `action.job.delete` - permite borrar un pase del monitor.
- `action.job.create` - permite crear un pase.

