---
title: Grid Personalizado para CIs
index: 1
icon: class
---

Los CIs están formados al menos por un fichero perl en el que se define la funcionalidad y un fichero javascript que tiene todas las configuraciones visuales. Si se quiere personalizar  las columnas que se muestran en el grid para el listado de clases es necesario añadir un nuevo metodo llamado custom_grid en el fichero de perl que devuelve la ruta del grid customizado, como ejemplo :

	sub custom_grid {'comp/customized_grid.js'}

El fichero javascript encargado de cargar el grid debe ser programado correctamente para que funcione en Clarive y es responsabilidad de quien lo programa.
