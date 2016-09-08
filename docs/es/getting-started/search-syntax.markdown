---
title: Busquedas avanzadas
index: 500
icon: search-small
---

La mayoría de las listas y reportes en Clarive tienen cajas de búsqueda. Las
cadenas introducidas en dichas cajas ignoran mayúsculas y minúsculas y de
tipo OR.

Por ejemplo la siguiente búsqueda:

    gui security

Encontrará coincidencias con todos los documentos que tengan la cadena gui O
la cadena security en uno de los campos del documento, en un [CI](concepts/ci)
o en [Topic](concepts/topic)

Por otro lado, la siguiente búsqueda:

    +gui +security

Encontrará coincidencias con todos los documentos que tengan AMBAS cadenas, gui
o security en cualquiera de los campos del documento. Un campo, por ejemplo, "titulo"
puede contener la palabra "gui", y el otro, por ejemplo, "departamento" puede
contener la palabra "security"

### Mayusculas y Minúsculas

Todas las búsquedas no tienen en cuenta mayúsculas y minúsculas. Para que sean
distinguidas, utiliza comillas dobles alrededor de la cadena:

    "GUI"

Sólo buscará para documentos con la palabra "GUI" completamente en mayúsculas.

En resumen, los siguientes tipos de sintaxis de búsqueda:

    term
    "term"  - no distingue mayusculas y minúsculas
    Term  - distingue mayúsculas y minúsculas
    T?rm  - busca 1 caracter en ?
    T*rm  - busca 0 de muchos caracteres en *
    +term1 +term2  - tiene que tener ambas term1 y term2
    +term1 -term2  - tiene term1 pero no term2
    /term regex.*/  - expresión regular

### Busqueda de campos

Clarive soporta también y conjunto limitado de búsquedas en campos. Las búsquedas
por campo, sólo buscan en esos campos:

    status:"QA Done"

Busca sólo el estado "QA Done".

La herramienta también permite usar la almohadilla para acceder directamente a un
tópico específico

    #123456

Va directamente al tópico especificado.
