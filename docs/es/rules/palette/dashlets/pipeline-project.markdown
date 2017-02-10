---
title: Cadena de Proyecto
index: 5000
icon: roadmap
---

La cadena de proyecto muestra como las releases, los cambios y las revisiones
están distribuidos en los diferentes entornos.

#### Modo

- `Releases` - Grupo de releases contenidos en los diferentes proyectos.
- `Cambios` - Grupo de cambios contenidos en los diferentes proyectos.
- `Revisiones` - Grupo de revisiones contenidos en los diferentes proyectos.

#### Entorno

Selecciona los entornos a mostrar o ocultar.

- `Excluir entornos seleccionados` - Niega los entornos seleccionados por tanto
  estarán ocultos.

#### Seleccionar tópicos por categorías

Selecciona las categorías que se desean mostrar.

Se trata de un modo para seleccionar un subconjunto de changeset y releases que
serán mostrados en cada caso.

#### Campo Revisión

Especifíca el nombre del campo revisión.

#### Condición avanzada JSON/MongoDB

Permite añadir un filtro para las filtrar los topicos y/o categorías a mostrar.

#### Máscara de etiqueta de tópicos

Es el texto a mostrar en cada una de las releases, changesets o revisiones.

Las variables disponibles son:

- `${category.name}`
- `${category.acronym}`
- `${category.color}`
- `${topic.mid}`
- `${topic.title}`
- `${topic.[nombre del field]}`
