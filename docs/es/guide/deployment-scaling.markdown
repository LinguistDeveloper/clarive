---
title: Escalamiento de la implementación
index: 230
---

La implementación a veces no puede ser una gran entrega de cambios ni llenarse
con pasos manuales. Necesita un proceso gradual.

Clarive soporta diferentes maneras de escalar despliegues.

- Despliegues parciales.
- Enrollables y en fase.
- Canary, en caliente, azul-verde, modos oscuros de lanzamiento

### Despliegue Azul-Verde

La estrategia de escala de despliegue azul-verde es un tipo de despliegue a
destino activo-pasivo en el que se está desplegando un nodo (pasivo) mientras
que el otro nodo activo, está vivo.

Para implementar despliegues azul-verde, use cualquiera de los métodos
siguientes:

- Despliegue en pausa (preferido)
- Entornos azul-verde

Combinado con un conjunto de operaciones de reglas que cambian las funciones de
nodo activo y pasivo (por ejemplo, deteniendo e iniciando procesos en cada
servidor o clúster).

#### Despliegue en pausa

El uso de una operación `Pausa` en la regla detendrá la implementación después
de que el nodo pasivo se haya sido implementado. Después de verificar el nodo,
la operación de regla cambiará los nodos pasivos-activos y continuará
desplegando.

#### Entornos Azul-Verde

Un entorno es azul y otro verde, como los entornos PROD-VERDE y PROD-AZUL.

Los entornos se pueden heredar desde un entorno padre, por lo que la única
diferencia entre ellos debe ser los servidores de destino en los que se
despliega.

Este método permite una release en fases más larga para ejecutarse en 2 pases
diferentes.


### Dark launching y feature toggle

*Dark launching y feature toggle* es una estrategia escalonada de despliegue
que consiste en configurar un switch *específico de la aplicación* que puede
activar una función solo para un grupo determinado de usuarios, geografías,
etc.

Aunque Clarive no es realmente parte de un mecanismo de conmutación, ya que
debería ser una aplicación interna, hay varias características de Clarive que
soportan *externamente* la implementación de lanzamiento oscuro en una
aplicación:

- Parseo de variables en los ficheros de configuración.
- Construcción condicional y despliegue condicional

Una estrategia externa de lanzamiento oscuro significa que Clarive se encarga
de activar/desactivar el conmutador de función de su aplicación para un
determinado entorno o variable condicional en el proceso de creación o
despliegue.

#### Parse de variables para lanzamientos *Dark Launching*

Configure un archivo de configuración con valores opcionales y utilice una
lógica de regla de despliegue que active la función:

    FOREACH deployment_node DEPLOY artifact IF node = activated_feature THEN
SET feature_toggle = ON PARSE config file DEPLOY config to node ELSE DEPLOY
config to node

Aquí está el contenido del archivo de configuración, antes de que Clarive
parsee las variables:

    show_feature = ${feature_toggle}


#### Construcción condicional y despliegue

Los *Dark launches* también pueden ser controlados por opciones condicionales
en la construcción de las reglas de pase. De esta forma, las reglas crearán o
desplegarán la función de acuerdo con el destino.

    IF node = active_feature THEN DEPLOY artifact_v1 ELSE DEPLOY artifact_v2

### Canary

Los despliegues *Canary* son una estrategia escalonada y *probada* de
despliegue.

La forma recomendada es configurar un entorno *Canary* y los estados a
implementar:

- Crear entornos `PROD-CANARY` y` PROD`, luego desplegar primero en
  `PROD-CANARY`.
- Después del despliegue, lanzar los tests.
- Mover la release a un entorno fallido

### Despliegue en caliente


Clarive admite el despliegue en caliente en los servidores. El despliegue en
caliente significa que la aplicación no tendrá interrupciones antes, durante o
después de implementar una nueva versión.

Por lo general, depende de la tecnología a la que se dirige el despliegue.

Por ejemplo, los servidores de aplicaciones JBoss, WebSphere® y Weblogic® son
compatibles con un modo de implementación en caliente.
