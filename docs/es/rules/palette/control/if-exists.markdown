---
title: IF EXISTS naturaleza THEN
index: 5000
icon: statement-if
---

Comprueba si existe la naturaleza indicada y de ser así, continua la regla por los procesos anidados a este componente.

Las siguientes variables se incluyen dentro del stash:

- **nature_items** - Lista de CIs afectados por la naturaleza definida.
- **nature_item_paths** - Rutas para cambiar los elementos que cumplen con la naturaleza definida y que no se han eliminado del repositorio.
- **nature_item_paths_del** - Rutas para cambiar los elementos que cumplen con la naturaleza definida y que se han eliminado del repositorio.
- **nature_items_comma** - Todas las rutas, separadas por comas, con elementos que han cambiado y que cumplen con la naturaleza definida.
- **nature_items_quote** - Todas las rutas, separadas por comas, con elementos que han cambiado y que cumplen con la naturaleza definida cada una de las señaladas.

Es necesario configurar los siguientes campos:

- **Naturaleza** - Cuadro desplegable donde aparecen solo las naturalezas existentes. Solo se puede seleccionar una.
- **Ruta cortada** - La ruta incluida en este campo será omitida de la ruta de elementos modificados.


