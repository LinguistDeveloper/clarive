---
title: Timeline de topicos
index: 400
icon: chart_curve
---

* Muestra el número de tópicos creados de una o varias categorias a lo largo de un determinado espacio de tiempo.
* El dashlet es configurable a través de las siguientes opciones:

<br />
### Altura en canvas
* Define la altura en numero de filas que se le da al dashlet.
* El valor de la altura oscilará entre 1 y 4. Donde con 4 ocupará el 100% de la página.

<br />
### Anchura en canvas
* Establece el ancho que ocupará el elemento en el dashboard.
* El valor máximo permitido es de 12 (100% de anchura).

<br/>
### Frecuencia de autorefresco
* Establece el intervalo de tiempo el cual el elemento se autorrefrescará.

<br />
### Seleccionar tópicos en categorias
* Selecciona las categorias que se quieren mostrar en la tabla.

<br />
### Seleccionar tópicos en estados
* Selecciona los estados que se quieren mostrar en el gráfico.

<br />
### Excluir estados seleccionados
* Excluye los estados seleccionados en el punto anterior y muestra el resto que **no** están seleccionados.

<br />
### Condición avanzada JSON/MongoDB
* Permite añadir un filtro para las filtrar los topicos y/o categorias a mostrar
            
        {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25} 


&nbsp;&nbsp;• Donde *id* es la clave una de la categoria. Dicho id se puede consultar a través del REPL.


<br />
### Desplazamiento en días desde hoy para inicio del periodo
* Permite establecer un margen de manera que el día actual no sea el primero que se visualizará. 

<br />
### Desplazamiento en días desde hoy para fin del periodo
* Permite establecer un margen de manera que el día actual no es el último que se visualizará. 

<br />
### Campo de fecha en tópicos para el eje X:* Establece la fecha inicial de manera que solo se mostrarán los tópicos creadas posterior a la fecha indicada

<br />
### El gráfico se mostrará como
Muestra los diferentes tipos de gráficos que pueden ser utilizados: <br />

&nbsp; &nbsp;• **Area** <br />

&nbsp; &nbsp;• **Area step** <br />

&nbsp; &nbsp;• **Lineal** <br />

&nbsp; &nbsp;• **Bar** <br />

&nbsp; &nbsp;• **Scatter**

<br />
### Los datos se agruparan por:
* Se pueden mostrar el número de tópicos agrupados por día, semana, mes, trimestre o año.