---
title: Lanzando una release
index: 400
---

Lanzando una nueva versión de una aplicación, configuración o infraestructura en Clarive se realiza ejecutando el tópico
de release (o cambio) dado como un **pase de despliegue**.

Este **pase** ejecuta la combinación de todas las tareas manuales, ahora automáticas y orquesta todo lo necesario para
desplegar la release.

## Estrategias de lanzamiento de Releases

Los lanzamientos de release se pueden adaptar a algunas de las siguientes estrategias:

- Releases Big-bang.
- Releases graduales.
- Despliegue escalonado.

#### Releases Big-Bang

Despliega todos los cambios al mismo tiempo en un solo pase.

Esta es la mejor estrategia en entornos de producción, ya que realiza cambios "transaccionales". Esto significa que
Clarive garantiza que todo el pase puede ser revertido (rollback) en caso de fallo.

Para implementar releases Big-Bang:

- Añada "Agrupar releases" en el Estado CI donde desea evitar el despliegue de conjuntos de cambios graduales, por
  ejemplo, estado `Producción`.
- Desarrolle una regla de tipo pase que aproveche al máximo las estrategias de *rollback*.
- Si fuera necesario, añade operaciones de despliegue manuales a su pase: aprobaciones, pausas, etc.


#### Releases graduales

Las releases graduales significan implementar los cambios de manera individual en un entorno.

Esta estrategia suele ser más adecuada para entornos de preproducción. Las principales ventajas son que podemos hacer
*cherry pick* de releases que van a ser desplegadas en a entorno.

#### Despliegue escalonado

Esto significa que los pasos de la release gradual se implementan a través de pausas, capturas o aprobaciones durante el
trabajo de despliegue.

Recomendamos usar el despliegue escalonado si la ejecución de la release no va a durar más de 24 horas.

Tener un pase en funcionamiento durante más de 24 horas significa tener los procesos de trabajo ocupando recursos en el
servidor Clarive (y objetivos relacionados).

### Ventana de pases

Para planificar los despliegues de las releases, Clarive hace uso de su motor de calendarios para procesar qué y cuando
desplegar. Use la interfaz de administración `Ventanas de pase` para definir las ventanas disponibles para cualquier
ámbito o contenido de pase:

- Calendario global
- Ventanas basadas en entornos
- Excepciones para días específicos (por ejemplo, vacaciones)
- Ventanas de pase por Proyectos o CIs.

### Relación de Infraestructura de Releases

Los releases y los changesets tienen relación con los CIs en Clarive, estás relaciones se pueden ver a través del
gráfico de CI. Esto permite, por ejemplo, identificar qué releases pueden ser verse afectadas por alguna interrupción en
la infraestructura.

Para usar el dashlet Gráfico CI, añadalo al dashboard asociado al tópico de categoría Release:

1) cree una nueva regla de tipo Dashboard en el `Diseñador de reglas` y añada el dashlet `Gráfico de CI` desde la paleta.

2) abra el menú `Categorías` desde el panel de Administración.

3) Seleccione una categoría de tipo Release

4) Añada el dashboard creado en el paso 1 en el combo `Dashboard`.

Una vez que abra un tópico de una categoría de tipo release, el usuario puede profundizar a través del gráfico de CIs,
incluida la infraestructura, para un entorno o proyecto dado para esa release.

#### Infraestructura de despliegue

La infraestructura que se va a necesitar para implementar una release también está disponible cuando se crea un `Nuevo pase`.

### Redesplegando una release

Si una release falla, o en entorno se ha modificado desde el exterior, una release puede ser re-desplegada a ese mismo
entorno usando una de las dos opciones siguientes:

- Reiniciar un pase
- Crear una nueva transición de despliegue hacia el mismo entorno.

En cualquiera de los casos, la release será desplegada al entorno.

#### Reiniciar un pase

Reiniciando un pase a través del `Monitor`, las mismas variables y valores que se han utilizado en cada paso volverán
a ser reutilizadas. Esto significa que la misma versión de la configuración va a ser desplegada al entorno.

Un reinicio de un pase también permite al usuario controlar qué pasos del pase va a ser re-ejecutado. Esto permite a los
usuarios re-ejecutar solo el paso `RUN`del job.

#### Redespliegue estático

Si la release ya se encuentra en un entorno, y la transición desde y hacia el estado existe en el workflow de la release
con el **tipo de pase** `estático`, entonces Clarive puede re-desplegar una release a un entorno donde ya está
instalada.

Para configurar el re-despliegue estático, edite el workflow de la categoría de tópico:

Acceda al panel "Administración de categorías" para añadir una transición de flujo de trabajo con tipo de pase `static`
desde y hacia el mismo estado (por ejemplo, de QA a QA).

- Si es un simple workflow, accede al panel de administración de `Categorías` para añadir una transición de Pase de tipo
  `Estático` desde y hasta el mismo estado (por ejemplo, desde QA a QA).
- Si es un workflow de regla, modifique la regla y añada una transición desde un estado al mismo estado y establezca el
  tipo de Pase a `Estático`.

### Provision / Decommission Configuration

Usando repositorios de catálogo, los usuarios pueden añadir tareas de aprovisionamiento a changesets de releases.

El aprovisionamiento es ejecutado cuando se ejecuta la regla. Asegúrese que la regla tiene la operación `Ejecutar tareas
de provisión` configurada o sino ninguna tarea de provisión será ejecutada.

Una buena estrategia para configurar el aprovisionamiento durante el proceso de release es configurar el despliegue con
la operación en el paso `PRE` del pase para desplegar las tareas aprovisionadas **antes** de la hora programada (paso
`RUN`).

### Federación después de la implementación

Federe la información de configuración de las aplicaciones importantes con CMDBs externos si tiene uno.

Añada servicios web y llamadas de federación a su regla de despliegue para  moderar los cambios de configuración
implementados por su último pase de despliegue.
