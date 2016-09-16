---
title: Proyecto
index: 5000
icon: project
---

Un proyecto es el [grupo de seguridad](concepts/scope) más común de Clarive.

En Clarive, un proyecto es una colección de [tópicos](concepts/topic), y se define en base a los requerimientos
de cada organización. Por ejemplo, un proyecto de Clarive puede ser:

- Un proyecto de desarrollo de software.
- Un sistema.
- Un grupo de componentes de software.
- O algo más genérico como una aplicación.

Los tópicos pueden pertenecer a uno o más proyectos (incluso a ninguno) pero no es un requisito.
Por ejemplo los tópicos de una categoría de tipo Cambio, deben de pertenecer a un único proyecto.

Los tópicos de una categoría de tipo Release pueden pertenecer a uno o varios proyectos o no tener proyecto.

## Variables del proyecto

Cada proyecto puede tener un conjunto de variables diferentes especificadas por cada proyecto. Incluso, por
cada [Entorno](concepts/environment), se pueden especificar diferentes valores.

### Copia de variables entre entornos

Definir variables puede ser un arduo proceso, y es muy común que para diferentes entornos quieras
tener las mismas variables pero con valores diferentes. Es por lo que Copiar variables a otro entorno
puede ser de ayuda. Si las variables están marcadas con el flag Copiar (ver [Variable](concepts/variable)
para más información), se copia el valor actual.
