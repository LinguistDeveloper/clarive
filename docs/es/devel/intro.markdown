---
title: Introducción
index: 100
icon: page
---

JavaScript es el lenguaje escogido para escribir el código de las reglas automatizadas en Clarive.

JavaScript, abreviado como JS en muchos sitios, es el lenguaje perfecto para dicha tarea debido a su sintaxis simple, comprensible y universalmente conocida.
Cada día se implementan nuevas librerías, tanto en el lado del cliente como del servidor, que permiten la extensión y diversificación del lenguaje.

JavaScript posee las siguientes interesantes características:

- Simples pero poderosas estructuras de datos.
- Intérprete rápido.
- Ampliamente adoptada, lo que se traduce en muchas herramientas y recursos disponibles en Internet para permitir el desarrollo.

Además, la implementación de JavaScript en Clarive añade lo siguiente:

- Un modelo de hilos, para escribir tareas concurrentes
- Los literales en plantilla, para las strings multilínea con plantillas flexibles y de gran alcance
- También para las cadenas multilínea pero sin interpolación para las variables `$ {...}`
- Un sistema de módulo de carga incorporado (`require`) que permite aprovechar la potencia de las 
extensiones de código abierto y comerciales.

### ¿Por qué necesito para escribir JavaScript en las reglas?

A veces, el uso de las operaciones definidas en la paleta de las reglas no es suficiente.

Para complejas operaciones de manipulación de datos y otros procesamientos puede ser necesarias operaciones complejas para la automatización del flujo de trabajo. Por ejemplo:

- Extraer una subcadena de texto introducido en un campo de un tópico
- Escribir en un fichero del sistema de archivos
- Analizar las diferentes relaciones entre los tópicos en una release
- etc.

Aquí es donde JavaScript se hace necesario. Utilizando el elemento de la paleta *Server code* permite a los administradores de Clarive desarrollar nuevas funcionalidades que amplían la facilidad de uso de la automatización al siguiente nivel.


### API JavaScript en Clarive

La API JavaScript de Clarive está construida como una extensión del lenguaje
a través del objeto único `Cla`.

La API es robusta y permite a los desarrolladores utilizar librerías de las siguientes áreas:

- Sistema de ficheros.
- Acceso a la base de datos MongoDB.
- Ítems de configuración (CIs), con acceso a los datos, relaciones y métodos de las clases..
- Seguridad de Clarive (usuarios, roles, etc).
- Eventos, semáforos y otras utilidades para el control del sistema útiles para los sistemas de automatización.
- Utilidades genéricas para la manipulación de datos, incluido un potente motor para las expresiones regulares.
- Soporte Unicode.
- ¡Y mucho más!

### Versión de JavaScript implementada en Clarive

El intérprete JavaScript actualmente implementado en Clarive se basa en [Duktape <img class='ext-link' src='static/images/icons/new_window_link.svg' />](http://duktape.org), un motor intérprete embebido [Ecmascript v5/v5.1 compliant <img class='ext-link' src='static/images/icons/new_window_link.svg' />](http://www.ecma-international.org/ecma-262/5.1/), aunque algunas de las características Ecmascript v6 también están disponibles.

La lista de características de Ecmascript v6 soportadas por Duktape está disponible [aquí <img class='ext-link' src='static/images/icons/new_window_link.svg' />](http://duktape.org/guide.html#es6features)


