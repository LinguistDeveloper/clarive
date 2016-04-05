---
title: Lista de topicos
index: 400
icon: report_default
---
* Muestra una lista de tópicos 
* La lista se puede configurar a través modificando los siguientes parámetros:

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
###  Lista de campos a visualizar en el grid
* Permite personalizar las columnas que se muestras en la tabla.

* Para separar las columnas se utiliza el **;**

*  El formato para añadir una columna sería:
            
        ID,nombre,tipo,ancho,total,currency,símbolo; 


&nbsp; &nbsp;• **ID** : Viene dado en la regla del formulario. <br />
&nbsp; &nbsp;• **nombre** : Nombre que se le quiera asignar al ID. <br />
&nbsp; &nbsp;• **tipo** : Tipo de campo que queramos mostrar. Puede ser: <br />
&nbsp; &nbsp; &nbsp;• **text** <br />
&nbsp; &nbsp; &nbsp;• **number** <br />
&nbsp; &nbsp; &nbsp;• **checkbox** <br />
&nbsp; &nbsp; &nbsp;• **ci** <br />
&nbsp; &nbsp;• **ancho** : Asigna el ancho de la columna.

* En el caso que usemos el valor number en tipo, podremos usar los campos total,currency y símbolo.

&nbsp; &nbsp;• **total** : Puede tener los siguientes valores: <br />
&nbsp; &nbsp; &nbsp;• **sum** : Muestra la suma de todos los valores. <br />
&nbsp; &nbsp; &nbsp;• **max** : Muestra el máximo valor. <br />
&nbsp; &nbsp; &nbsp;• **min** : Muestra el mínimo valor. <br />
&nbsp; &nbsp; &nbsp;• **count** : Muestra la cantidad de filas. <br />

&nbsp; &nbsp;• **currency** : Indicamos que nos muestre la separación por comas o por puntos dependiendo del país que le hayamos asignado en `Preferencias` <br />

&nbsp; &nbsp;• **símbolo** : Símbolo de la moneda que queramos mostrar. <br />
  
		Ejemplo de uso: numero,Mi numero,number,,sum,currency,€;

<br />
### Número máximo de tópicos a listar
* Establece el número máximo de tópicos que se van a mostrar en la tabla.

<br />
### Seleccionar tópicos en categorías
* Selecciona las categorías que se quieren mostrar en la tabla.

<br />
### Excluir las clases seleccionadas
* Excluye las clases seleccionadas en el punto anterior y muestra el resto que **no** están seleccionadas.

<br />
### Usuario asignado a los tópicos
* Permite añadir el filtro el cual solo muestra tópicos asignados a un usuario existente en la herramienta.

<br />
### Condición avanzada JSON/MongoDB
* Permite añadir un filtro para las filtrar los topicos y/o categorías a mostrar.
            
        {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25} 


&nbsp;&nbsp;• Donde *id* es la clave una de la categoría. Dicho id se puede consultar a través del REPL.

