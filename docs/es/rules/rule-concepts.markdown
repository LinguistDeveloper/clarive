---
title: Conceptos de regla
index: 200
icon: rule.svg
---
* Una vez que las diferentes necesidades se registran y se gestionan a tavés de los distintos estados que componen su ciclo de vida, estos deben de ser desplegados y entregados como operación final del ciclo.
* La gestión de reglas permite automatizar el despligue entre sistemas.
* La automatización se realiza a través de ejecuciones de reglas; estas son creadas utilizando la definición de los procesos de Clarive, la cual además, suministra todas las herramientas necesarias para su gestión.

### Tipos de reglas
Existen seis tipos de reglas:

**Eventos** - Lanzadores desencadenantes basados en acciones realizadas por el sistema. Hay tres tipos de reglas de evento:

 *Pre online* - Carga la regla antes de la ejecución del evento.

 *Post online* - La regla se carga de manera síncrona con el evento.

 *Post offline* - La regla se ejecuta tras producirse el evento.

**Cadena de pase**: Referentes a las cadenas de pase, para desplegar o realizar [rollback](concepts/rollback). Tres posibles pasos finales:

 *Promote* - Despliega a otro entorno, conceptualmente otro superior, por ejemplo de pre-producción a producción.

 *Static* - Despliega al mismo entorno.

 *Demote* - Degrada a un entorno inferior, por ejemplo, de producción a pre-producción.

#### Pasos de un job
* Cuando se crea una regla de tipo cadena de pase, se muestran cinco pasos:

**CHECK** - Comprueba antes de crear el job, el objeto del job no está disponible todavía.

**INIT** - Comprueba después de la creación, pero el job no se ejecuta aún.

**PRE** - Inmediatamente despues de la implmentación antes de la hora programada

**RUN** - Se ejecuta a la hora programada.

**POST** - Fase que siempre se ejecuta cuando el trabajo ha terminado independientemente de su resultado.

### Tipos de tareas
* La regla se puede dividir en tres tipos de tareas:

**Control** - Proporciona a la regla flujos de control, como son condicionales IF o iteraciones FOR asi como tareas *ad-hoc*.

**Servicios** - Para definir el pase, puede ser:

 *Servicios del job* - Tareas asociadas al job.

 *Servicios generales* - De tipo general.

**Reglas** - Permite incluir reglas dentro de otras reglas para simplicar el flujo. Estas reglas tiene que ser de tipo independiente.

**Dashlets** - Componentes que sirven para construir los [dashboards](concepts/dashboards)

**Fieldlets** - Elementos que dan forma a los formularios de los [tópicos](concepts/topic)

### Otras reglas

**Report** - Crea un informe con código PER

**Servicio web** - Permite integrar servicios web en reglas.

**Independent** - Pequeñas reglas que pueden ser utilizadas en otras reglas más complejas simplificando el sistema.

**Dashboard** - Regla que permite al usuario crear dashboards personalizados con componentes dashlets.

**Form** - Regla compuesta por fieldlets para crear los formularios que se usarán en los tópicos.


### Stash
*  El [stash](concepts/stash) de las reglas en el sistema de CLarive mantienen el estao de los pases entre ejecuciones. Las variables stash son utilizadas para comunicar diferentes tareas.