---
title: Crear Informe
index: 5000
icon: report
---

Permite a los usuarios crear grids de tópicos personalizados. El usuario selecciona las columnas a mostrar, categorías y filtros. Este grid, puede configurarse de la siguiente manera:

### Crear Informe

Existen dos formas:

La primera, consiste en ir a **Administración** - <img src="/static/images/icons/rule.svg"/> **Reglas** y pulsar el botón <img src="/static/images/icons/add.svg" /> Crear.

Nos aparecerá una ventana con las siguientes opciones:

- **Nombre** - Asigna un nombre al informe. Este campo es obligatorio.
- **Tipo** - Define el tipo de regla. Para nuestro caso, seleccionamos informe.
- **Modo de compilación**

Para crear el informe, hacemos click en el botón **Finalizado**.

Por defecto, nos aparecerán tres elementos:

- **Seguridad** - Definimos los usuarios que tienen acceso al informe.
- **Meta** - Definimos los campos que se van a mostrar.
- **Datos** - Tratamos los datos a mostrar.


La segunda forma para crear un informe es la siguiente:

Hacemos click en <img src="/static/images/icons/report.svg" /> dentro del panel principal. Click derecho en  <img
src="/static/images/icons/magnifier.svg" /> **Nueva Búsqueda**.

#### Opciones

- **Nombre** - Nombre del reporte.
- **Filas** - Define el numero de filas por página en el grid.
- **Recursive level** - Ajusta la profundidad de la relaciones entre tópicos.
- **Permisos** - Podemos seleccionar la privacidad de nuestro informe.
    - *Privado* - Únicamente el propietario del informe puede verlo.
    - *Público* - Muestra un combo **Usuarios y roles** donde podemos seleccionar quién puede ver el informe.


### Query

En esta pestaña, podemos definir la configuración de nuestro informe. En la izquierda aparecen todas las categorías
y sus fieldlets

A la derecha, aparece el árbol con los datos añadidos en nuestro informe:

 - **Categorías** - Arrastrar y soltar la categoría que queremos ver en el informe.
 - **Campos** - Arrastrar los fieldlets que queremos ver en el informe. Haciendo click en cada campo podemos ver las siguientes opciones:
     - *Cabecera* - Título de la columna.
     - *Ancho* - Ancho de la columna.
 - **Filtros** - Además, podemos añadir filtros arrastrando los fieldlets aquí. Haciendo click en cada fieldlet, podemos ver las siguientes opciones:
    - *String* - Podemos filtrar por texto.
    - *CI* - Podemos filtrar por alguna condición.
    - *Fecha* - Podemos filtrar por fecha
 - **Ordenar** - Podemos definir el orden. Arrastrar un fieldlet aquí y hacer click en él. Aparecerá un menú en el que definiremos el orden ascendente o descendente.

Para terminar hacer click en <img src="/static/images/icons/save.svg"/> Guardar.

