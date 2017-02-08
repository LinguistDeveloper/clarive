---
title: Automatización del pipeline de Releases
index: 800
---

La ejecución de las reglas que realizan la ejecución de pipelines de Releases puede soportarse en 3 fases clave en el
proceso de entrega: PRE, RUN y POST. Durante la fase PRE, la PREparación de los pasos de la entrega son documentados
y automatizados. Durante esta fase, por lo general, se modelan las siguientes acciones:

- Provisión y construcción de Entornos.
- Construcción de Binarios: compilación desde revisiones asociadas a través de las diferentes plataformas.

Una vez completado el paso de construcción, se ejecuta el paso RUN, donde el sistema comienza a operar en función a las
ventanas de pase disponibles para cada entorno. Durante esta fase, dependiendo de las distintas naturalezas/tipos de
binario, los ejecutables y los datos se colocan en los entornos de destino adecuado. Esto se realiza a través de SSH,
Clarive push o agentes Pull, dependiendo de la topología del usuario y de las restricciones en la arquitectura.

Durante la fase POST, Clarive puede orquestar las actividades post-despliegue, como cleaups, actualizaciones CMDB etc..

Una regla de Clarive hace uso de variables de entorno. Estas variables tienen contenido específico para cada entorno
y permiten utilizar la MISMA regla de despliegue para todos los entornos y plataformas.

Esta capacidad le permite utilizar Clarive para validar y testear la lógica de despliegue (solo código) en todos los
entornos. Clarive permite a las organizaciones probar la lógica de compilación, implementación, provisión y testing en
todos los entornos desde una SOLA y ÚNICA regla. Además, cada regla se rige por el control de versiones y el seguimiento
de cambios, lo que proporciona un valor adicional para la agilidad y el control.

Durante la definición de reglas, Clarive permite al diseñador de reglas definir y documentar la estrategia de rollback
por linea al mismo tiempo.


## Recreación de pipelines

La recreación de un pipeline es la habilidad para re-ejecutar un despliegue utilizando una versión anterior de los
modelos de entorno y la lógica general de la regla.

### Etiquetando las versiones de la regla

Para saber qué versiones de configuración son las mejores, basta con etiquetar las versiones de reglas en la interfaz
`Creador de reglas`, bajo el botón de versión de la regla

### Almacenamiento de versiones de pipelines

Las versiones se almacenan en el sistema de acuerdo con el tamaño de la colección `rule_version`. Simplemente modifique
el tamaño de la colección para que contenga más o menos versiones de configuración, de acuerdo con sus políticas de
organización y disponibilidad de almacenamiento.

### Snapshot de la versión del Pase

Clarive almacena automáticamente instantáneas del contenido del pase que se utilizó para implementar una release en
entornos de producción, simplemente establezca la casilla de verificación `Snapshot Environment` en el Entorno CI de su
entorno de producción.
