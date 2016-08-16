---
title: Grafico de un CI 
index: 400
icon: ci-grey.svg
---
* Muestra un gráfico de relación entre CIs
* Se debe seleccionar al menos un elemento.
* La lista de componentes configurables dentro del dashlet son los siguientes:

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
### Tipo de gráfico
* Selecciona el tipo de gráfico que se utilizará en el dashboard. Las opciones son: <br />

&nbsp; &nbsp;• **Space tree** <br />

&nbsp; &nbsp;• **Radial Graph** <br />

&nbsp; &nbsp;• **D3 Force-Directed graph** <br />


<br />
### Punto de comienzo del gráfico
* Se establece el primer nodo del cual derivará en todo el gráfico. 
* La herramienta permite seleccionar varios CIs como primeros nodos.

<br />
### ¿Mostrar primero el CI con el contexto actual?
* Permite utilizar el CI configurado siempre o que sea ocultado por el topico o proyecto actual.

<br />
### ¿Mostrar barra de herramientas?
* Permite mostrar en el dashboard la barra de herramientas del dashlet donde se puede configurar parámetros como el tipo de gráfico, añadir un filtro adicional y imprimir el gráfico.

<br />
### Incluir clases
* Permite seleccionar una o varias clases para mostrar y su relacion con el punto de comienzo.

<br />
### Excluir las clases seleccionadas
* Excluye las clases seleccionadas en el punto anterior y muestra el resto que **no** están seleccionadas.

<br />
### Condición avanzada JSON/MongoDB
* Permite añadir un filtro para las filtrar los topicos y/o categorias a mostrar
            
        {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25} 


&nbsp;&nbsp;• Donde *id* es la clave una de la categoria. Dicho id se puede consultar a través del REPL.

