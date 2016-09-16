---
title: cla docs - Generador de la ayuda y documentación
index: 5000
icon: console
---

`cla docs-export`: Exporta los documentos de la ayuda en un sitio estático Mkdocs.

**Nota**: Para que este comando funcione es necesario instalar Mkdocs el cual requiere Python.

Opciones:

#### --doc-lang en|es

El idioma de la ayuda a exportar.

#### --mkdocs-path dir

La ruta de la carpeta donde se almacenarán los ficheros Mkdocs temporales.

**Nota**: Cada vez que se ejecute el comando, la carpeta especificada se borra antes de escribir de nuevo en ella.

#### --site-dir dir

El destino final de los documentos generados.

Si no se especifica el directorio, la documentación se crea bajo `/static/mkdocs` en el servidor de Clarive.
