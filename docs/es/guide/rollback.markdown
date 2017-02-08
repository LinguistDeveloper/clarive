---
title: Rollback y gestión de errores
index: 260
---

Clarive mantiene trazabilidad sobre lo que se ha desplegado hasta ahora y puede realizar el rollback inteligentemente
a un estado previo tan solo desinstalando las tecnologías y deshaciendo los cambios actuales.

Clarive puede realizar el rollback para cada versión de cada aplicación y para cualquier release, tanto para negocio
como para la lógica de configuración/implementación.

Existen 3 tipos de rollback en Clarive:

- Anular la implementación.
- A prueba de fallos.
- Degradar (retroceso).


#### Anular la implementación

Realizar el rollback del pase, de manera que "desinstala" los artefactos y los cambios aplicados en el pase.


#### Rollback a prueba de fallos

El rollback es lo que ocurre cuando falla un pase a mitad de despliegue y el flag de rollback está establecido.

Es un mecanismo a prueba de fallos que deshace todo lo que se instaló cuando se detecta un error durante la fase de
despliegue.

#### Degradar (retroceso)

Una degradación es una transición de un tópico fuera de un entorno.

La degradación de los tópicos desde un estado vinculado a un entorno desencadena un pase de retroceso que ejecutará un
*re-despliegue de las versiones anteriores* de los artefactos pertinentes.

Una copia de seguridad de los tópicos, permite revertir sólo los componentes funcionales seleccionados y los cambios no
deseados de un entorno.

Este tipo de rollback se realiza en una base por release o por cambio de configuración, que es una forma muy poderosa de
degradar entidades lógicas individual.

Por ejemplo, un único conjunto de cambios puede ser eliminado de QA, lo que provocará un rollback pero sólo del
contenido de ese conjunto de cambios dado (suponiendo que no hay dependencias). Clarive reconstruirá el entorno de QA
para que coincida con la nueva situación del contenido de la release. Esto se usa típicamente durante las fases de QA,
Preproducción y UAT para descartar *cambios funcionales no deseados* sin tener que reconstruir y re-desplegar toda la
aplicación.

## Rollback inteligente a prueba de fallos

Clarive realiza un seguimiento de lo que se ha cambiado en los entornos de destino de manera que, si ocurre un fallo, se
genera automáticamente un rollback a prueba de fallos.

Esto se controla mediante un indicador de despliegue llamado `¿Necesita Rollback?`.

### Triggers de rollback de envío de archivos

Este seguimiento de cambios se realiza automáticamente cada vez que Clarive ejecuta una operación de envío desde dentro
de una regla de pase.

Y cada vez que un archivo se envía correctamente, se establece el indicador de rollback y se despliega el rollback del despliegue.

### Campo ¿Necesita rollback?

El flag de rollback puede ser establecido manualmente en la regla seleccionando `Propiedades` para la operación deseada,
posteriormente seleccione en el campo `¿Necesita rollback?`la opción que mejor describa el comportamiento del rollback
para el nodo.

Se pueden realizar rollbacks de despliegue de un pase automatizado seleccionando el pase, siempre y cuando no haya pases
posteriores para el mismo componente o artefacto en ese mismo entorno.

### Writing Reversible Rules

Las reglas de cadena de pase pueden ser ejecutadas hacia delante o hacia atrás.
Esto significa que la misma regla puede ser usada para desplegar a nuevas o anteriores versiones de un artefacto.

#### Sólo en Marcha Adelante

Este flag dentro de las `Propiedades` de la operación le indica al motor de reglas de Clarive que ejecute esta operación
cuando se realiza un despliegue de tipo promoción (*promote*). Si no se selecciona, no se ejecutará en el modo de
implementación.

#### Sólo en Marcha Atrás

Este flag dentro de las `Propiedades` de la operación le indica al motor de reglas de Clarive que ejecute esta operación
cuando se realiza un rollback. Si no se selecciona, no se ejecutará en el modo de implementación.

Se trata de una operación útil para saltarse operaciones de regla cuando se realiza un rollback. Los nodos de operación
en el árbol de reglas se marcan con `NO ROLLBACK` cuando esta opción está desactivada.

### IF ROLLBACK

La operación de control `IF ROLLBACK` existe para que las reglas pueden derivarse en un comportamiento distinto en
función de si se está desplegando hacia delante o hacia atrás.

Esta operación de control es muy útil cuando, por ejemplo, el rollback es realmente muy particular para esa tecnología
y no puede ser "adivinado" por la lógica de copia de seguridad de archivos Clarive.

### Capturando errores

Dentro de las `Propiedades` de la operación, utilice la opción `Captura del error` para interceptar errores y evitar que
se produzca un rollback por un fallo de la operación.

#### No captura

Los errores no quedan capturados, y se activa el rollback si hay un error y el indicador de rollback está activado para
el pase.

#### Capturar errores

Pausa el pase si hay un error en el despliegue. El estado del pase cambia a `Capturado` y se hace necesaria la
intervención manual para desbloquear la situación.

Si se ha definido el tiempo de espera para las capturas en las propiedades de la operación, el motor de reglas fallará
el trabajo y tomará la acción apropiada (rollback o terminar el pase con un error).

#### Ignorar errores

Los errores serán ignorados (pero sí reportados en el log) para está operación. Esto significa que no se lanzará el
rollback una vez la operación haya fallado.

#### Agrupación de operaciones y capturas de errores

Las operaciones pueden ser agrupadas utilizando la operación de control `GROUP` o con cualquier operación que permita
anidar otras operaciones.

Si el parámetro `Captura de errores` está definido a nivel grupal y el usuario responde **Reintentar**, el grupo será
re-ejecutado desde el inicio.

Si el parámetro `Captura de errores` está definido a nivel grupal y el usuario responde **Saltar**, el grupo entero será
omitido.
