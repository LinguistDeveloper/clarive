---
title: Monitor
index: 5000
icon: television
---

El monitor muestra la lista de [pases](concepts/job) que han sido creados y que el usuario puede ver en función de sus permisos.
Se puede modificar la forma en la que se crean los nombres de los pases modificando la variable congif.job.mask [Config Job Mask](how-to/config-job-mask).

Los siguientes botones se encuentran disponibles arriba de la lista de pases:

<img src="/static/images/icons/html.svg" /> **HTML** - Muestra el log de el pase seleccionado en formato html.

<img src="/static/images/icons/project.svg" /> **Proyecto** - Filtra los pases por proyecto.

<img src="/static/images/icons/baseline.svg" /> **Entorno** - Filtra los pases por entorno.

<img src="/static/images/icons/nature.svg" /> **Naturaleza** - Filtra los pases por naturaleza.

<img src="/static/images/icons/state.svg" /> **Estado** - Filtra los pases por estado.

**Tipo** - Filtra los pases por tipo.

<img src="/static/images/icons/job.svg" /> **Nuevo** - Crea un nuevo pase.

<img src="/static/images/icons/moredata.svg" /> **Log Completo** - Muestra el log de el pase seleccionado.

<img src="/static/images/icons/delete.svg" /> **Borrar** - Borra el pase seleccionado.

<img src="/static/images/icons/left.svg" /> **Rollback** - Ejecuta el [rollback del job](concepts/rollback).

<img src="/static/images/icons/restart.svg" /> **Reiniciar** - Comienza el pase de nuevo desde el paso que el usuario desee.

<img src="/static/images/icons/datefield.svg"  /> **Replanificar** - Modifica la planificación del pase. Esta acción sólo esta disponible cuando el estado del
job está en "Listo" o "Esperando Aprobación"
