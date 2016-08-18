---
title: Flujo de trabajo
icon: workflow
---
* Un flujo de trabajo en Clarive se define como un conjunto de [estados](concepts/status) y transiciones por las que un [tópico](concepts/topic) puede transitar durante su ciclo de vida.
* Existen dos tipos de flujos:
   Basados en tópicos.
   Basados en reglas:  Más complejos que los anteriores y que permiten realizar flujos de trabajo reutilizables.

### Flujos de trabajo en tópicos
* Son flujos sencillos que se aplican en la [configuración de la categoría](admin/topics)
* Dependiendo del rol de usuario podrá transitar un tópico entre diferentes estados.

### Flujos de trabajo en reglas
* Por lo general, la mayoría de las categorías tendrán un flujo de trabajo en tópicos como el explicado en el apartado anterior.
* Los *workflows* de reglas deberias ser utilizados donde se requiera una sistema de transiciones complejo.
   Flujos específicos del proyecto.
Transiciones Campo-dependientes, es decir, si "urgencia" valor fieldset es "urgente" omita "promover al control de calidad".
   Transiciones que dependan de un campo, por ejemplo: Si el campo 'Urgencia' de un formulario tiene el valor "Urgente", entonces que se despliegue automaticamente al entorno de Preproducción.


Un flujo de trabajo que tenga dependencia de decisiones externas al estado del tópico como llamar a un servicio web externo para determinar donde o como desplegar ese tópico.

Cuando un campo del formulario se vuelve condiciona como la comprobacion de que un campo determinado ha sido completado antes de permitir que se despliegue el tópico


### Reusabilidad
* Además, el flujo de trabajo de regla pueden ser utilizados en diferentes categorias de tópicos.