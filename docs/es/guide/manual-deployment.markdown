---
title: Pasos manuales en despliegues
index: 220
---

Aunque idealmente un despliegue es un proceso desatendido, Clarive permite a un
pase tener una serie de pasos manuales o de operaciones donde se exija la
intervención manual donde desarrollador y operaciones puedan intervenir y
colaborar.

Aquí se exponen algunos de estos *breakpoints* manuales que pueden ser
implementados:

- Aprobaciones
- Pausas
- Capturas de errores
- Anotaciones
- ChatOps

Lea más acerca de los pasos manuales en una estrategia de lanzamiento visitando
las estrategias de ejecución de la release en la [guía de
releases](guide/releasing).


### Aprobaciones

Las aprobaciones es un mecanismo de control que permite a un pase transitar
hacia un estado de aprobación **después de que un paso haya terminado**.

Esto significa que las evaluaciones pueden ser solo ejecutadas después de los
pasos `CHECK`, `INIT`, `PRE` o `RUN` del pase. Una vez que el pase está en el
estado de aprobación, el pase solo podrá avanzar al siguiente paso si el
evaluador aprueba el pase.

Si un de los evaluadores no aprueba el pase, éste no realizará rollback.

Los pases que estén en el estado de aprobación esperando a ser evaluados **no
consumen** recursos. El pase se hiberna hasta que se apruebe o se rechace el
pase.


Recuerde que las aprobaciones también se pueden configurar como parte de una
transición de un tópico (release, changeset).

### Pausa

La operación pausa pone al pase en un estado de reposo, esperando a un usuario
con los permisos adecuados para reanudar el job.

La reanudación del pase es una operación dentro del `Monitor de pases`.

Para configurar una pausa, añada la operación de `Pausa` donde quiera dentro de
la regla de pase. Las pausas no pueden ser utilizadas durante el paso `CHECK`,
puesto que esta fase ocurre, a nivel del usuario, *antes* de que el pase haya
sido creado.

### Capturas

Las capturas está implementadas para parar un pase en caso de fallo. Esta
casuística está descrita en la [guía de rollback](guide/rollback). Pero las
capturas también pueden ser utilizadas para **corroborar**, lo que significa
que una regla puede corroborar si, por ejemplo, un contenedor que acaba de ser
desplegado se está ejecutando.

Las capturas pueden ser añadidas a operaciones de confirmación a través de las
`Propiedades` de las operaciones, accediendo a ellas pulsando botón derecho del
ratón sobre la operación deseada.

Por ejemplo, llamar a un comando remoto situado en un nodo de destino para
verificar que el contenedor está activa después de su despliegue, y configurar
el modo `Fallo en Error`. Después configure la captura del error en esta
operación para prevenir el rollback del pase en ese momento.


### Anotaciones

Las anotaciones es una manera en la que los equipos que siguen un pase pueden
intervenir e informar de los resultados a través de la interfaz del log en
Clarive.

Las anotaciones pueden contener:

- Comentarios de usuario.
- Ficheros adjuntos.
- Logs.
- Otros.

Las anotaciones pueden ser creadas en cualquier momento durante la vida del
pase, aunque normalmente se utilizan para gestionar un pase cuando se está
ejecutando, añadiendo más datos a los errores, fallos o cualquier otro suceso.

#### ChatOps

Se puede interactuar a través de la funcionalidad ChatOps para reportar
información antes del pase, durante y después de su ejecución.

Para abrir un nuevo canal de ChatOps para discutir las actividades manuales
durante la vida del pase, cree un nuevo canal en Slack con el siguiente
comando:

   @cla add #job-qa-1234

Donde `#job-qa-1234` es el job id que se muestra en el monitor.

Todos los comandos y comentarios ejecutados desde la ventana de chat de Slack
serán reportados al pase.

Para definir comandos autorizados que Clarive pueda ejecutar, por favor,
configure los elementos de configuración `Talkback`en Clarive, que asocia las
acciones que el bot de operaciones de Clarive `@cla` puede ejecutar.
