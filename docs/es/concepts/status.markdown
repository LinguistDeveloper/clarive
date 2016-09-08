---
title: Estados y transiciones
icon: status
---

Un estado es un [CI](concepts/ci) que representa el estado de un elemento (tópico, trabajo, etc...) en un punto especifico del [Flujo de trabajo](concepts/workflow). Un elemento puede estar en un único estado a la vez.

Cuando se definen los estados, también se configurar las propiedades de éstos. Este trabajo se realiza a través de la sección de [Administración de estados](admin/status).

### Transiciones

Una transición es un relación entre dos estados que permiten al elemento a pasar de un estado a otro. Para que un elemento pueda moverse entre el estado origen y el estado destino, debe estar definida la transición.

Una transición es un flujo de un único sentido, por lo que si el elemento necesita moverse hacia atrás deben de crearse las transiciones necesarias para ello.

### Tipos de Estados

Hay 5 tipos de estados

- **Nuevo**: Indica que un [tópico](concepts/topic) justo se ha creado y no ha sido "cogido" por el equipo.
- **Cancelado**: Indica un estado de abortar.
- **Cerrado**: Indica que el estado es problablemente el último del flujo. Al marcar un estado como Cerrado, los tópicos con ese estado no serán mostrados en muchas vistas por defecto como el los listados o Kanbans. 
- **Desplegable**: Significa que, como parte de la transición en ese estado (promición), los tópicos "Cambios" necesitan ser desplegables a al menos uno de los entornos asocados. Como parte de la transición hacia atrás (devolver), Los tópicos de tipo Cambio necesitan volver desde alguno de esos entornos.. 
- **Genérico**: Cualquier otros estados que existen en esa categoría.

### Promoción

Las transiciones de tipo promoción en Clarive representan las transiciones a estados desplegables.

### Devolver

Las transiciones de tipo Devoler, por otro lado, generan las transición devueltas, con un [pases](concepts/job) marcha atrás.
