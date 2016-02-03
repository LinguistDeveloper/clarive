---
title: Roadmap de topicos
index: 400
icon: roadmap
---
* Muestra en una tabla los tópicos en función de la fecha de resolución.
* La lista de elementos para personalizar el dashlet son:

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
### Primer día de la semana
* Permite establecer el primer día de la semana laboral.

<br />
### Escala
* Se puede definir la escala para mejor visualización de los tópicos. Dicha escala puede ser por día, semana o mes

<br />
### Entornos
* Añade un filtro para poder visualizar topicos que se encuentren en uno o varios entornos determinados

<br />
### Excluir entornos seleccionadas
* Excluye los entornos seleccionadas en el punto anterior y muestra el resto que **no** están seleccionados.

<br />
### Inicio / Fin (Desplazamiento hacia delante en días desde hoy)
* Permite establece un margen en el que se visualizan días anteriores al día actual y dias posteriores.

<br />
### Seleccionar tópicos en categorias
* Selecciona las categorias que se quieren mostrar en la tabla.

<br />
### Excluir las clases seleccionadas
* Excluye las clases seleccionadas en el punto anterior y muestra el resto que **no** están seleccionadas.

<br />
### Condición avanzada JSON/MongoDB
* Permite añadir un filtro para las filtrar los topicos y/o categorias a mostrar
            
        {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25} 


&nbsp;&nbsp;• Donde *id* es la clave una de la categoria. Dicho id se puede consultar a través del REPL.


<br />
### Máscara de etiqueta de tópicos
* Permite personalizar la etiqueta de los tópicos.
* *Ejemplo*: ${category.acronym}#${topic.mid} ${topic.title}