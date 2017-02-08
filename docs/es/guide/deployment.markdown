---
title: Despliegue
index: 200
---

Clarive implementa una gran cantidad de funciones útiles para los modos de
despliegue disponibles en la herramienta. Clarive despliega revisiones de los
proveedores de cambios. Estos proveedores generalmente son repositorios de
código o artefactos (como Git, Subversion (SVN), Nexus...) pero también puede
ser Salesforce o una base de datos.

Como parte de la implementación de los despliegues automáticos en su empresa,
se tiene que planificar lo siguiente

#### Aplicaciones

Seleccione un conjunto de aplicaciones destino para esta implementación.

#### Tecnologías ("Naturalezas")

Define las tecnologías que van a ser desplegadas (desde un conjunto de
aplicaciones destino o servicios).

En Clarive, éstas se denominan naturalezas.

#### Lógica de despliegues y rollbacks

Recopile toda la información sobre la lógica de automatización que se quiere
utilizar o los procesos manuales.

Con esta información a mano, está listo para escribir reglas de automatización.

#### Recursos (CIs)

Determine todos los recursos y entornos utilizados por las aplicaciones de
destino y las naturalezas para cada entorno de configuración.

Escriba los modelos de entornos para los patrones implementados en su
organización. Esto ayudará mas adelante a incorporar nuevas aplicaciones a
medida que se unan al flujo de entrega automatizado implementado en Clarive.

## Despliegue de tópicos

Clarive despliega tópicos. Los tópicos contienen las revisiones de la
configuración desplegada. Clarive puede desplegar dos tipos de tópicos:

- Cambios (Changesets).
- Releases

La manera de como se empaquetan las releases puede variar en función del tipo
de aplicación y de las metodologías que la organización utilice. Clarive
soporta la gestión de releases y agrupación *top-down* y *bottom-up*. Esta es
la manera con la que Clarive puede soportar tanto metodologías ágiles como
metodologías mas tradicionales.

### Desplegando Cambios

Clarive tiene múltiples maneras de "empaquetar" desarrollos y despliegues. El
primer tipo es un Cambio que contiene varias revisiones, las cuales pueden
proceder de CUALQUIER repositorio, pueden estar relacionadas/enlazadas entre
si.

Una vez que las revisiones están añadidas en el Cambio, cualquier usuario, los
permisos necesarios puede pulsar sobre la revisión y ver los detalles de la
mismas directamente desde Clarive, sin necesidad de salir de la herramienta.

Los cambios pueden ser compilados y desplegados en base a un cambio de estados,
la ejecución de un pase o por un evento tanto interno como externo. Basado en
las diferentes naturalezas asociadas la propia revisión, la regla de
compilación (y/o despliegue) ejecutará las acciones apropiadas para compilar,
construir, testear y/o desplegar al entorno correcto.

### Desplegando Releases

Clarive también otra manera de "empaquetar" desarrollos y despliegues: los
tópicos de tipo Release. Este tipo permite combinar Cambios o Releases en otro
nivel lógico de "paquetes". Cuando una "release" es compilada y desplegada,
Clarive ejecutar la operación para todas las revisiones que formar parte de la
release, a cualquier nivel inferior en la jerarquía construida.

De esta manera se puede formar y gestionar cualquier tipo de composición.

Los Cambios y las Release son sólo 2 ejemplos de posibles tópicos que forman
parte la entrega de una aplicación, pero se pueden definir tantos como se
necesiten para organizar correctamente el proceso de entrega.
