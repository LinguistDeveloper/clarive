---
title: Administración de Calendarios
index: 500
icon: calendar
---

La ventana para la administración de calendarios permite a los administradores
configurar cuando los pases pueden ser programados en función del ámbito del pase y de 
su contenido.

Un `Calendario` es un conjunto de ranuras semanales (7 días) que van 
desde las 00:00 hasta las 23:59 (12am a 11:59pm).

Un *`slot`* es un bloque formado por una hora de inicio, una hora de fin, un tipo de *slot*
y un valor dado, ya sea el día de la semana o una fecha especifica.

### Lista de Calendarios

Contiene la lista de los calendarios que han sido creados y configurados.

Para crear un nuevo calendario, seleccione `Crear`.

- `Nombre del calendario` - Nombre del nuevo calendario.
- `Descripción` - Una breve descripción del calendario (opcional).
- `Precedencia` - Establece una precedencia al calendario en caso de que haya convergencia
con otros calendarios. A más precedencia, más prioridad se le da respecto al resto.
- `Modo de creación` - Permite crear un calendario con todos las ranuras vacías 
(`Crear como nuevo`) o crear una copia de un calendario existente (`Crear como copia`).
- `Entorno` - Entorno al que aplica el calendario.
- `Ámbito` - Define el ámbito del calendario, ya sea para un 
proyecto específico o para cualquier ámbito del sistema.

### Editar un calendario

En el modo edición, puede configurar las ventanas del calendario y las principales
propiedades del mismo, como la precedencia o el ámbito.

#### Añadir una ventana semanal

Para añadir una ventana semanal, por ejemplo, una que se repita diariamente, seleccione
un bloque de `00:00` a `23:59` pinchando encima.

La configuración de la ventana, `Editar ventana de pase`, se abrirá:

- `Día` - El día de la semana.
- `Tipo` - El tipo de ventana, `Normal`, `Urgente` o `No pase`
- `Hora inicio` - La hora de inicio de la ventana de pase.
- `Hora fin` - La hora de fin de la ventana de pase.

Si se crean ventanas del mismo tipo junto a otra que ya existe, se fusionarán de manera 
automática.

**NOTA**: Las ventanas son guardadas de manera automática, no hay botón de 
cancelación disponible.

#### Ventana Normal

La ventana normal significa que los pases pueden ser programados por cualquier usuario 
que tenga un rol con la acción `Crear jobs`.

#### Ventana Urgente

La ventana urgente significa que los usuarios con la acción `Crear job` puede
 programar un pase pero el job se marcará como `Urgente`.

El efecto de establecer una ventana de tipo `Urgente`, tiene que estar definido en 
la regla de pase. Generalmente, la regla tiene una lógica como esta:

    IF job IS URGENT
        Request Approval

Al final del paso `PRE` del job.

#### Ventana vacía

Una ventana `Vacía` significa que puede ser sobrescrita por cualquier otra ventana que
exista en otro calendario independientemente de su precedencia.

#### No pase

La ventana `No pase` previene de las ventanas de calendarios con menor precedencia que 
puedan tener ventanas de tipo `Normal`o `Urgente` en la misma franja horaria.

Por lo tanto, usar la ventana `No pase` en vez de la `Vacía`, en una calendario de mayor
precedencia evita la creación de jobs en horarios específicos.


#### Ventana Activa / Inactiva

Las ventanas pueden ser creadas o modificadas a un estado "Inactivo". 
El efecto de una ventana inactiva es que se comporta como si no existiera.
 Este comportamiento continuará así hasta que se vuelve a activar la ventana de nuevo.

Esta opción resulta útil en situaciones donde, por ejemplo, se tiene una ventana ya 
definida pero por un evento puntual (por ejemplo, por trabajos de mantenimiento) se decide 
inhabilitarla. Para ello es mejor marcaba como inactiva pues de esta manera 
no se elimina ninguna información previamente definida.

### Ventanas en días específicos

Este tipo de ventanas solo aplican a un día del calendario en concreto. Al resto de días 
se le aplicará el calendario semanal.

Para crear una ventana en un día específico, seleccione el enlace `Nueva ventana mm/dd/yyyy` 
situada debajo del calendario semanal. Use el calendario de la parte derecha para moverse 
por las semanas.
