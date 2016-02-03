---
title: Conceptos de regla
icon: rule
---
* Una vez que las diferentes necesidades se registran y se gestionan a tavés de los distintos estados que componen su ciclo de vida, estos deben de ser desplegados y entregados como operación final del ciclo. 
* La gestión de reglas permite automatizar el despligue entre sistemas.
* La automatización se realiza a través de ejecuciones de reglas; estas son creadas utilizando la definición de los procesos de Clarive, la cual además, suministra todas las herramientas necesarias para su gestión. 


  
<br /> 
### Tipos de reglas
* Existen seis tipos de reglas: <br />

&nbsp; &nbsp;• **Eventos** - Lanzadores desencadenantes basados en acciones realizadas por el sistema. Hay tres tipos de reglas de evento: <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp; • *Pre online* - Carga la regla antes de la ejecución del evento. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp; • *Post online* - La regla se carga de manera síncrona con el evento. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp; • *Post offline* - La regla se ejecuta tras producirse el evento. <br />


&nbsp; &nbsp;• **Cadena de pase**: Referentes a las cadenas de pase, para desplegar o realizar [rollback](Conceptos/rollback). Tres posibles pasos finales: <br />
    
&nbsp; &nbsp;&nbsp; &nbsp; • *Promote* - Despliega a otro entorno, conceptualmente otro superior, por ejemplo de pre-producción a producción. <br />
    
&nbsp; &nbsp;&nbsp; &nbsp; • *Static* - Despliega al mismo entorno.
    
&nbsp; &nbsp;&nbsp; &nbsp; • *Demote* - Degrada a un entorno inferior, por ejemplo, de producción a pre-producción.

<br />
#### Pasos de un job
* Cuando se crea una regla de tipo cadena de pase, se muestran cinco pasos: <br />

&nbsp; &nbsp;• **CHECK** - Comprueba antes de crear el job, el objeto del job no está disponible todavía. <br />

&nbsp; &nbsp;• **INIT** - Comprueba después de la creación, pero el job no se ejecuta aún. <br />

&nbsp; &nbsp;• **PRE** - Inmediatamente despues de la implmentación antes de la hora programada <br />

&nbsp; &nbsp;• **RUN** - Se ejecuta a la hora programada. <br />

&nbsp; &nbsp;• **POST** - Fase que siempre se ejecuta cuando el trabajo ha terminado independientemente de su resultado.

<br />
### Tipos de tareas
* La regla se puede dividir en tres tipos de tareas: <br />


&nbsp; &nbsp;• **Control** - Proporciona a la regla flujos de control, como son condicionales IF o iteraciones FOR asi como tareas *ad-hoc*. <br />

&nbsp; &nbsp;• **Servicios** - Para definir el pase, puede ser: <br />
      
&nbsp; &nbsp;&nbsp;&nbsp; &nbsp; • *Servicios del job* - Tareas asociadas al job. <br />
      
&nbsp; &nbsp;&nbsp;&nbsp;&nbsp; • *Servicios generales* - De tipo general. <br />

&nbsp; &nbsp;• **Reglas** - Permite incluir reglas dentro de otras reglas para simplicar el flujo. Estas reglas tiene que ser de tipo independiente.

&nbsp; &nbsp;• **Dashlets** - Componentes que sirven para construir los [dashboards](Conceptos/dashboards) 

&nbsp; &nbsp;• **Fieldlets** - Elementos que dan forma a los formularios de los [tópicos](Conceptos/topic) 


### Otras reglas


&nbsp; &nbsp;• **Report** - Crea un informe con código PERL<br />

&nbsp; &nbsp;• **Servicio web** - Permite integrar servicios web en reglas. <br />

&nbsp; &nbsp;• **Independent** - Pequeñas reglas que pueden ser utilizadas en otras reglas más complejas simplificando el sistema. <br />

&nbsp; &nbsp;• **Dashboard** - Regla que permite al usuario crear dashboards personalizados con componentes dashlets. <br />

&nbsp; &nbsp;• **Form** - Regla compuesta por fieldlets para crear los formularios que se usarán en los tópicos. <br />


<br />
### Stash
*  El [stash](Conceptos/stash) de las reglas en el sistema de CLarive mantienen el estao de los pases entre ejecuciones. Las variables stash son utilizadas para comunicar diferentes tareas.