---
title: Tópico
index: 5000
icon: topic
---

El tópico representa la entidad central del ciclo de vida en Clarive.

Una **categoría de tópico** es una instancia que define la organización
que tiene asociado un [flujo de trabajo](concepts/workflow).

Un **tópico** es una instancia de una categoría de tópico, que lleva asignado
un [mid](concepts/mid).

Una categoría de tópico llega asociado las siguientes propiedades:

- Un grupo de estados por los que el tópico podrá transitar.
- Un flujo de trabajo.
- Una [regla](concepts/rule) de tipo formulario donde se define el formulario que
se utilizará para rellenar la información del tópico.
- Seguridad a nivel de flujos - Establece que usuarios/roles puede transitar un tópico
de un estado a otro pudiendo establecerse flujos distintos en función del rol y del proyecto
- Un color para representar la categoría de manera visual.
- Un sobrenombre, para identificar de manera sencilla a la categoría.

Algunas de las categorías de ejemplo que se pueden crear son:

- Release
- Cambio
- Bug
- Caso de prueba
- Estimación
- Requerimiento
- Sprint
- Historia de usuario

### ¿Por qué usar tópicos?

En Clarive creemos que con cada instalación se debe de tener el completo control sobre
los procesos definidos. Así que para tener una buena trazabilidad de todo lo que ocurre
en un sistema, se ha creado una herramienta para controlar todo el ciclo de vida de la
entrega de un producto.

Los tópicos son excelentes tanto para desarrollos de tipo *brownfield* como implementaciones *greenfield*
ya que no solo pueden ajustarse y adaptarse a los procesos existentes sino que además ayuda a definir
nuevos procesos sin restricciones que pueden representar mejor lo que una empresa necesita.