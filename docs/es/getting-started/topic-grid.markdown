---
title: Tabla de tópicos
index: 5000
icon: topic
---
La tabla de tópicos es la lista de tópicos que el usuario puede visualizar.
El concepto está basado como si fuera una bandeja de entrada de e-mail.

La tabla puede ser vista desde cuatro modos diferentes:

- **Todos los tópicos** - Se abre seleccionando `Todos` dentro del menú de tópicos en la parte superior de la página.
- **Por categoría** - Acceso a través de selecionar una categoría dentro
del menú de tópicos.
- **Por estado** - Acceso a través de selecionar un estado dentro
del menú de tópicos.
- **Por proyecto** - Por último también se puede acceder a través del explorador de proyectos
<img src="/static/images/icons/project.svg" /> situado en el panel de la izquierda.

### Ordenación

Por defecto, la lista aparece ordenada por fecha de modificación, del más reciente al
elemento más antiguo.

Se puede cambiar la ordenación pinchando en la columna por la que se quiere ordenar la lista.
Con cada click, se cambiará el tipo de ordenación (ascendiente/descendiente).

#### Búsquedas

En el grid de tópicos tambien se puede buscar resultados utilizando el
[buscador](getting-started/search-syntax).

## Filtros

Para filtrar los resultados, existe unos filtros definidos en la parte derecha de la lista.

#### Estados

Cada uno de los filtros existen 3 estados diferentes.

- **Seleccionado** - Muestra los tópicos que estén en ese estado.
- **No seleccionado** - Oculta los tópicos que estén en ese estado.
- **Sin seleccionar** - Esconde los tópicos que estén en ese estado si hay ningún
otro estado seleccionado. En caso de no haberlo, muestra los tópicos con su estado.

Como regla general, si no hay ningún estado seleccionado o no seleccionado,
se muestran todos los tópicos.

#### Categorías

Filtra por la categoría que el usuario quiera ver. Si no hay ninguna seleccionado,
muestra todas las categorías siempre que el usuario tenga los permisos necesarios.

#### Resetear las columnas del grid

Permite restaurar el grid de tópicos mostrando las columnas que aparecen por defecto y ocultando aquellas añadidas por el usuario.

#### Exportar

Permite exportar el grid de tópicos a distintos formatos, HTML, CSV y YAML.

#### Abrir Kanban

Muestra los tópicos del grid actual en [vista Kanban](getting-started/kanban)

#### Colapsar Filas

Colapsando las filas es posible ver más tópicos por página pero con algo menos información
