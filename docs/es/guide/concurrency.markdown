---
title: Releases y despliegues concurrentes
index: 240
---

Estos son algunos de los casos de uso que soportamos las releases concurrentes
utilizando alguna combinación de las anteriores características:

### Planificación de la Release

Una Release puede ser planeada y programada para un entorno determinado;
Clarive puede informar las releases planificadas para un entorno dado.

#### Planificador

Primero hay que configurar un [fieldlet de planificador de
release](rules/palette/fieldlets/environment-planner) de manera que los
responsables de la release puedan añadir las fechas planeadas a la que debe
estar planificado.


#### Visualizaciones

Puede utilizar el [dashlet calendario de
releases](rules/palette/dashlets/calendar) para que los responsables de las
releases puedan visualizar como los entornos han sido planificados y qué se
instalará en cada entorno y en qué momento.

Utilice el [dashlet flujo de proyecto](rules/palette/dashlets/pipeline-project) para
habilitar a los usuarios ver como los proyectos, releases y cambios son
desplegados en cada entorno.

### Calendarios

Los despliegues de Releases tienen que pasar por la ventana de pases con el fin
de encontrar una ventana que permita hacer la operación.

Los semáforos y las prioridades pueden evitar conflictos mientras se está
desplegando los cambios de la aplicación y la infraestructura al entorno.

Los gestores de Releases pueden priorizar y controlar la ejecución de la
entrega de Releases a través del Monitor de pases.

### Reglas de eventos

Cree reglas de eventos para implementar una lógica personalizada que limite
cuando y a donde un tópico puede ser desplegado.

Las reglas de eventos para la concurrencia de Releases puede ser lanzado en
diferentes momentos del ciclo de vida de una Release:

- Cuando se modifican los campos de planificación de la release
  (`event.topic.modify_field`)
- Después de que una release haya sido desplegada y haya transitado a un nuevo
  estado. (`event.topic.change_status`)

### Control concurrente de reglas de tipo workflow


Las reglas de flujo de trabajo pueden ser aún más elegantes que las reglas de
eventos para gestionar la concurrencia.

Este tipo de reglas producen una lista de *estados siguientes* disponibles a
una release o a un cambio (o, de hecho, a cualquier tópico).

- Añade operaciones de verificación de concurrencia en la lógica.
- Posteriormente utilice las reglas de workflow para limitar la lista de
  transiciones disponibles en el tópico.
- Las releases y los cambios no pueden ser desplegados a un entorno a menos que
  la transición a dicho entorno exista.

IF NOT environment_is_busy('QA') STATUS 'QA'

**NOTA**: Uno de los inconvenientes de utilizar reglas de tipo workflow para
permitir o denegar una transición, es que el usuario no sabrá por que no puede
realizar una transición al siguiente estado (o desplegar el tópico). Sobre
esto, es mejor utilizar reglas de eventos, por que un error al intentar la
transición mostrará un error en la interfaz de la herramienta.

### Otros tipos de control de concurrencias en Relase

Las releases pueden dar marcha atrás totalmente o parcialmente, hay más
información sobre este proceso aquí [rollback](guide/rollback). Los rollbacks
(o marcha atrás) son útiles para mantener la integridad de la release.

