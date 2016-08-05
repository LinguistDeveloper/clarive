---
title: Borrar Ficheros Adjuntos
icon: topic.svg
---

Servicio que borra ficheros adjuntos a un tópico. El formulario de configuración tiene los siguientes campos:

* **Eliminar por**: Selecciona el modo de eliminar los ficheros adjuntos por el mid de los ficheros o por el campo.

	* **Mids Ficheros**: Campo de texto para introducir mid de ficheros, puede tener múltiples valores separados por comas
		o por una variable de tipo Array o String.

	* **Campos**: Campo de texto para introducir los campos que se encuentran los ficheros que se desean borrar,
		puede tener múltiples valores separados por comas o por una variable de tipo Array o String. 
		Este campo de texto borrará todos los adjuntos del tópico asociados al campo seleccionado.

* **Topic Mid**: Campo de texto para introducir el mid del tópico, sólo acepta un valor.

* **User**: Usuario que borra el fichero adjunto o Clarive si no se proporciona ninguno.