---
title: Grid Personalizado para CIs
index: 5000
icon: class
---

Los CIs están formados al menos por un fichero *Perl* en el que se define la funcionalidad y un fichero *Javascript* que tiene todas las configuraciones visuales.

Si se quiere personalizar las columnas que se muestran en el grid para el listado de clases es necesario añadir un nuevo metodo llamado custom_grid en el fichero de *Perl* que devuelve la ruta del grid personalizado, como ejemplo :

	sub custom_grid {'comp/customized_grid.js'}

El fichero *Javascript* encargado de cargar el grid debe ser programado correctamente para que funcione en Clarive y es responsabilidad de quien lo programa.