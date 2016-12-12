---
title: Lista de tópicos
index: 400
icon: report
---

Muestra una lista de tópicos.

La lista se puede configurar a través modificando los siguientes parámetros:

### Altura en canvas

Define la altura en numero de filas que se le da al dashlet.

El valor de la altura oscilará entre 1 y 4. Donde con 4 ocupará el 100% de la página.


### Anchura en canvas

Establece el ancho que ocupará el elemento en el dashboard.

El valor máximo permitido es de 12 (100% de anchura).

### Frecuencia de autorefresco

Establece el intervalo de tiempo el cual el elemento se autorrefrescará.


###  Lista de campos a visualizar en el grid

Permite personalizar las columnas que se muestras en la tabla. Por defecto, el dashlet contiene las columnas; ID, titulo, estado, usuario que ha creado el tópico y la fecha de creación.

Estas columnas se pueden personalizar, para ello, las columnas se separan utilizando el **;**.


Así, una tabla de ejemplo seria:

`<id_fieldlet>,<nombre_columna>,<tipo>,<ancho>;`

Donde:

- `<ID_fieldlet>` - Viene dado en la regla del formulario.
- `<nombre_columna>` - Nombre que se le quiera asignar al ID.
- `<tipo>` - Tipo de campo que queramos mostrar. Puede ser: *text*, *number*, *checkbox
o *ci*.
- `<ancho>` - Asigna el ancho de la columna.


Adicionalmente, en el caso de utilizar un fieldlet de tipo *number*, es posible indicar el número de decimales que se quiere mostrar en la lista, basta con añadir, al final del tipo el número de decimales entre paréntesis.


#### Tipos

##### Texto

Especifica que el valor es un texto.

##### Número

Podemos usar las siguientes propiedades para números como `total`:

- `total` - Puede tener los siguientes valores:
- `sum` - Muestra la suma de todos los valores.
- `max` - Muestra el máximo valor.
- `min` - Muestra el mínimo valor.
- `count` - Muestra la cantidad de filas.
- `currency` - Indicamos que nos muestre la separación por comas o por puntos dependiendo del país que le hayamos asignado en `Preferencias`
- `símbolo` - Símbolo de la moneda que queramos mostrar.

Ejemplo de uso: `title,Título;created_by, Creado por;incoming,Entrante,number(2),,sum,currency,€`

En este ejemplo, los usuarios podrán ver una tabla con las siguientes columnas:

             Título | Creado por  | Entrante
            --------------------------------
            Título1 | 2016-02-02  | 23,25 €



##### Casilla de verificación

Si tenemos un fieldlet de tipo checkbox en el formulario del tópico, es posible mostrar ese valor en la lista con un icono en vez de visualizar un '1' o un '0' para indicar si ha sido marcado o no.

Para visualizar en la columna el icono checkbox, hay que indicar en el tipo de columna que se trata de una casilla de verificación.

Ejemplo: `title,Título;created_by,Creado por;<check_box_ID>, <nombre-columna>, checkbox`


##### CI

Podemos utilizar este tipo de columna para mostrar nombres de Cis, por ejemplo, el usuario que ha creado un tópico. Por defecto, Clarive muestra el ID del usuario:

        Title  | Created by  | Owner
        --------------------------------
        Title1 | 2016-02-02  | 1108

Si se quiere mostrar el nombre, hay que indicar que el tipo de columna es CI:

Ejemplo: title,Título;created_by,Creado por;owner,Propietario,ci

        Title  | Created by  | Propietario
        --------------------------------
        Title1 | 2016-02-02  | admin-1


### Número máximo de tópicos a listar

Establece el número máximo de tópicos que se van a mostrar en la tabla. Por defecto es 100.

Para que muestre todos los tópicos sin límite, establecer el limite a 0.

### Ordenar por

Establece el parámetro (ID del fieldlet) por el que vamos a ordenar los tópicos (Por defecto ordena por el ID del tópico).


### Orden de ordenación

Indica el tipo de ordenación, ascendente o descendente.

### Mostrar el total de filas

Muestra una última fila en la tabla mostrando, por ejemplo, la suma total de las columnas de sean de tipo *number*.


### Seleccionar tópicos en categorías

Selecciona las categorías que se quieren mostrar en la tabla.


### Seleccionar tópicos en estados

Selecciona los estados de los tópicos que se quieren mostrar en la tabla.

### Excluir las clases seleccionadas

Excluye las clases seleccionadas en el punto anterior y muestra el resto que 
están seleccionadas.


### Usuario asignado a los tópicos

Permite añadir el filtro el cual solo muestra tópicos asignados a un usuario existente en la herramienta.


### Condición avanzada JSON/MongoDB

Permite añadir un filtro para las filtrar los tópicos y/o categorías a mostrar.

        {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25}


Donde *id* es la clave una de la categoría. Dicho id se puede consultar a través del REPL.
