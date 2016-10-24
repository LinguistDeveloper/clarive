---
title: Historial de commits por rama
icon: branch_obj
---

El grid con el historial de commits por rama muestra el listado de commits que se han realizado en cada rama.
Para abrirlo, ir al explorador Clarive y hacer click en el nodo de la rama  <img src="/static/images/icons/branch_obj.svg" /> a consultar.

Cada fila del grid corresponde a un commit. Para abrir la información detalle, seleccionar la fila a consultar y hacer click en el enlace *DIFF*, en la columna del mismo nombre.

Con el campo de búsqueda de la barra superior del grid podemos realizar búsquedas de commits específicos. Por defecto la búsqueda se realizará por ID. Para aplicar filtros, tenemos en cuenta los siguientes formatos Git aplicables:


#### Formato Fecha

* Indicando la fecha de inicio del rango:

        --since="YYYY-MM-DD".

    Un ejemplo:

        --since:"2016-05-01".

* O la fecha de finalización:

        --until="YYYY-MM-DD".

    Siempre el mismo patrón:

        --until "2016-05-31".

#### Autor

* Filtrar por autor nos muestra los commits en función del usuario que los ha realizado. Podemos ver los nombres de los usuarios en la columna "Autor" del Grid. Un ejemplo:

        --author="anthony"

#### Comentario

* Otro filtro es el relativo a la columna "Comentario". En el siguiente ejemplo, filtrando por la palabra "help", obtendremos todos aquellos commits que incluyan esta palabra como parte del contenido de la columna del mismo nombre:

        --comment="help"
