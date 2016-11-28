---
title: Gráfico circular de tópicos
index: 5000
icon: chart-pie
---

Muestra un gráfico circular que permite visualizar los tópicos agrupados por categoría.

Este gráfico admite las siguientes personalizaciones:

### Altura en canvas

Define la altura en numero de filas que se le da al dashlet.

El valor de la altura oscilará entre 1 y 4. Donde con 4 ocupará el 100% de la página.

### Anchura en canvas

Establece el ancho que ocupará el elemento en el dashboard.

El valor máximo permitido es de 12 (100% de anchura).

### Frecuencia de autorefresco

Establece el intervalo de tiempo el cual el elemento se autorrefrescará.

### Selecciona o teclea el campo de agrupación

Selecciona el campo por el que se agruparán los datos

### El gráfico se mostrará como...

Permite cambiar el tipo de gráfico para mostrar en el dashboard.

- Circular
- Donut
- Barras

### Campo numérico agrupador

Permite agrupar los tópicos en base a un fiedlet numérico.

### Minimo % para mostrar serie en el grupo 'Otro'

Establece el valor mínimo para que una categoría que no llegue a un porcentaje significativo se muestre en el grupo 'Otro' del gráfico. Pueden usarse decimales para definir este valor

### Tipo de valor numérico

Indica el tipo de valor que es el campo numérico establecido en la opción anterior.

### Símbolo monetario a mostrar

Permite incluir un símbolo al final de cada cantidad.

### Agrupador agregado

Permite mostrar operaciones como la media o el total en el gráfico.

### Caracteres máximos en la leyenda

Permite establecer un máximo de caracteres en la leyenda en caso de que los nombres de las categorías sea muy largo.

### Ordenar por leyenda

Ordena el gráfico por leyenda.


### Seleccionar tópicos en estados

Selecciona los estados que se quieren mostrar en el gráfico.

### Excluir estados seleccionados

Excluye los estados seleccionados en el punto anterior y muestra el resto que **no*
están seleccionados.


### Condición avanzada JSON/MongoDB

Permite añadir un filtro para las filtrar los tópicos y/o categorías a mostrar

        {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25}

Donde *id* es la clave una de la categoría. Dicho id se puede consultar a través del REPL.

### Profundidad

Selecciona el rango de profundidad (1-5) en la búsqueda de tópicos.

Este campo se utilizará únicamente en los dashboards dentro de los tópicos.
