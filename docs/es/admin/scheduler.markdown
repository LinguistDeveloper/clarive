---
title: Planificador
index: 5000
icon: calendar
---

El planificador es una utilidad que permite al administrador a planificar de manera sencilla la ejecución de las reglas en intervalos establecidos.

Permite planificar, habilitar, deshabilitar o ejecutar reglas independientes en segundo plano, por frecuencia de tiempo o ejecutar a una hora de un día determinado.

El planificador se compone de la siguiente información:

- **Nombre** - El nombre del plan con el log asociado.
- **Estado** - Describe el estado actual en el que se encuentra la tarea.
- **Siguiente ejecución** - Indica el momento de la próxima ejecución
- **Última ejecución** - Indica la última vez que la tarea ha sido ejecutada.
- **PID** - El PID asignado durante la última ejecución.
- **Descripción** - Breve descripción de la tarea.
- **Frecuencia** - Indica la frecuencia con la que la tarea se ejecuta.
- **Día** - Indica si la tarea se ejecuta solo los días de diario (indicado con un 1) o todos los días (indicado con un 0).
- **Qué** - Muestra el nombre de la regla y el id que es ejecutado en la tarea.

### Tareas programadas

Para programar una nueva tarea, pulse en el botón `Nuevo`.

Aparecen las siguientes opciones a completar:

- **Nombre** - Nombre de la tarea.
- **Regla** - Menú de selección para seleccionar la regla independiente que se ejecutará según la planificación.
- **Fecha** - Selección de la fecha para llevar a cabo la ejecución, en caso de no ser puntual, indicar la primera fecha para la ejecución de la tarea.
- **Hora** - Especifica la hora para la ejecución de la tarea.
- **Frecuencia** - Formato (1H - 1 hora, 1D - Un día, etc...)
- **Sólo días de diario** - Si se quiere que la ejecución se lleve a cabo solo entre semana (de Lunes a Viernes) hay que activar esta opción.

### <img src="/static/images/icons/start-green.svg" /> Ejecutar ahora

La tarea se ejecutará en ese mismo momento, sin esperar a la próxima fecha estimada. Esta opción está disponible independientemente del estado de la tarea.