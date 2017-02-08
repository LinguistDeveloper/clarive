---
title: Gestión de Calendarios - ¿Cuando puedo ejecutar un pase?
index: 550
---

La entrega continua que gestiona Clarive permite a diferentes equipos de
trabajo desplegar sus cambios cuando consideran que están listos, asi como
dejar que la organización planifique y ejecute un proceso de entrega
cuidadosamente organizado.

El sistema de calendarios de Clarive se sitúa en el medio de estos 2 enfoques o
velocidades, trabajando como árbitro entre los requerimientos organizacionales
y la agilidad de los equipos que trabajan contrarreloj.

No todos los pases pueden ser ejecutados siempre que estén programados. Existen
restricciones externas que deben tenerse en cuenta, lo cual es clave para
*evitar interrupciones* de las aplicaciones y servicios que son entregados.

Los pases de Clarive pueden incluir despliegues automáticos y manuales asi como
tareas de aprovisionamiento. Por lo tanto, es fundamental planificar bien las
ventanas de pase para prevenir que se solapen despliegues con tareas de
aprovisionamiento al mismo tiempo:

- Calendarios basados en entornos.
- Calendarios por Naturaleza.
- Calendarios por proyecto.
- Calendarios por otros CIs definidos

### Plan semanal

Los calendarios de Clarive siguen un diseño de 7 dias que se repite
semanalmente.

Además, se pueden crear ventanas especificas para días concretos, como días
festivos o vacaciones.

### Tipos de ventana

En Clarive existen 4 tipos de ventana:

- `Vacio` - no se ha definido ventana por lo que los jobs no se ejecutan.
- `Normal` - ventana normal para despliegues.
- `Urgent` - solo para despliegues urgentes.
- `No pase` - no se pueden desplegar pases durante esta ventana.

La diferencia entre `Vacío`y `No pase` es la manera con la que actúan en la
fusión de dos calendarios. Más adelante se describe mas detalladamente este
comportamiento.


### Calendario Global

El calendario global es el calendario que se utilizará por defecto en caso de
no haber coincidencias con otros calendarios.

### Ventanas de entorno

Estos son los calendarios más simples de configurar.

Cree un calendario por cada entorno del sistema. No es algo obligatorio, pero
es lo más óptimo para empezar, tener un calendario por cada entorno. Además,
será de ayuda en el futuro, en caso de que el cliente necesite planear tener
diferentes calendarios para el mismo entorno.

Si no se ha establecido ningún entorno, el calendario global será el que
aplique a todos los pases.

### Fusión de los Calendarios

Supongamos que Release 2.0 va a desplegar 2 proyectos diferentes, A y B, al
entorno de Producción.

El proyecto A, solo permite despliegues al entorno PRO pasadas las 22h.

El proyecto B, tiene los mismos parámetros pero solo permite despliegues a PROD
a partir de las 23h.

Si se intenta planificar el pase de Release 2.0 para Producción, la primera
hora disponible será a 23h. Esto es porque Clarive **intersecciona** las
ventanas de manera restrictiva para determinar cual es la próxima ventana
disponible.

Directrices para la configuración de los calendarios:

Establecer prioridades de combinación para cada calendario que cree
- establece la prioridad en la fusión de los calendarios.
- solo utilice `No pase` si quiere bloquear la ventana a otra ventana que tenga
  una mayor precedencia.

#### Precedencia

La precedencia en el calendario determina el orden a la hora de que el sistema
realiza el merge (fusión) entre dos o más calendarios. A mayor precedencia,
mayor prioridad se le da.

Si dos calendarios tienen la misma precedencia, la precedencia se define por el
orden alfabético de nombre de los calendarios..

#### Ventanas 'comodín'

La ventana `Vacío` es una ventana comodín, e incluso una ventana con
precedencia más alta, la ventana puede ser sobrescrita por calendarios con
menor precedencia.

Use `Vacío` para indicar que el despliegue puede suceder en un momento
determinado si es necesario por cualquier calendario. Use `No pase`para denegar
despliegues para jobs con mayor precedencia.


### Limitaciones de calendario mediante reglas

Lo usuarios pueden prevenir que un job se ejecute añadiendo un control en la
regla de pase en el paso `CHECK`.

Por ejemplo, puede comprobar la existencia de un fichero en un directorio del
servidor de Clarive para prevenir que un job sea creado. Solo es necesario
añadir una operacio `FAIL` en el paso `CHECK` para prevenir que se cree el
pase.


#### Integraciones de calendarios exteriores

La regla puede ser llamada desde otras herramientas para comprobar las
limitaciones durante el paso `CHECK` de la regla.
