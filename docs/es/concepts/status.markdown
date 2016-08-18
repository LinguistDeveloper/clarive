---
title: Estados y transiciones
icon: status
---
* Un estado es un [CI](concepts/ci) que representa el estado de un elemento (tópico, trabajo, etc...) en un punto especifico del [Flujo de trabajo](concepts/workflow). Un elemento puede estar en un único estado a la vez.
* Cuando se definen los estados, también se configurar las propiedades de éstos. Este trabajo se realiza a través de la sección de [Administración de estados](admin/status).

### Transiciones
* Una transición es un relación entre dos estados que permiten al elemento a pasar de un estado a otro. Para que un elemento pueda moverse entre el estado origen y el estado destino, debe estar definida la transición.
* Una transición es un flujo de un único sentido, por lo que si el elemento necesita moverse hacia atrás deben de crearse las transiciones necesarias para ello.