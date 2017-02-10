---
title: Tópico
index: 5000
icon: topic
---

El tópico representa la entidad central del ciclo de vida en Clarive.

Clarive no solo es una herramienta que permite agrupar componentes técnicos en releases. 
Las empresas que utilizan Clarive, también la utilizan para la gestión lógica de
 "documentos" llamados *tópicos* que manejan los diferentes aspectos de 
sus procesos de entrega.

Esto puede incluir diferentes tipos de releases, sprints, etc. Dichos documentos, además, 
poseen *workflows* que pueden representar muchos cambios de estados LÓGICOS 
que son asignados a dichos tópicos. Ademas cada uno de ellos está compuesto de campos, 
con una seguridad basada en roles y acciones.

Una **categoría de tópico** es una instancia que define la organización
que tiene asociado un [flujo de trabajo](concepts/workflow). Piense en ello como una 
plantilla.

Un **tópico** es una instancia de una categoría de tópico, que lleva asignado
un [mid](concepts/mid).

### Categoría de tópico

Todas las categorías de tópicos en Clarive pueden tener cualquier número de campos, 
un flujo de trabajo con estados y reglas de transición (o restricciones) así como
dashboards con información filtrada y presentación de informes.

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

Los tópicos de una categoría de tipo Cambio pueden agruparse en tópicos de la categoría 
Release. Tener tópicos agrupados en Releases es la clave para tener un sistema completo de
orquestación del ciclo de vida de una entrega.

### ¿Por qué usar tópicos?

En Clarive creemos que con cada instalación se debe de tener el completo control sobre
los procesos definidos. Así que para tener una buena trazabilidad de todo lo que ocurre
en un sistema, se ha creado una herramienta para controlar todo el ciclo de vida de la
entrega de un producto.

Los tópicos son excelentes tanto para desarrollos de tipo *brownfield* como 
implementaciones *greenfield*
ya que no solo pueden ajustarse y adaptarse a los procesos existentes sino que además 
ayuda a definir
nuevos procesos sin restricciones que pueden representar mejor lo que una empresa necesita.