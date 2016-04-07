---
title: Lista de topicos
index: 400
icon: report_default
---
* Muestra una lista de tópicos 
* La lista se puede configurar a través modificando los siguientes parámetros:


### Altura en canvas
* Define la altura en numero de filas que se le da al dashlet.
* El valor de la altura oscilará entre 1 y 4. Donde con 4 ocupará el 100% de la página.


### Anchura en canvas
* Establece el ancho que ocupará el elemento en el dashboard.
* El valor máximo permitido es de 12 (100% de anchura).

### Frecuencia de autorefresco
* Establece el intervalo de tiempo el cual el elemento se autorrefrescará.


###  Lista de campos a visualizar en el grid
* Permite personalizar las columnas que se muestras en la tabla.

* Para separar las columnas se utiliza el **;**

*  El formato para añadir una columna sería:
            
        ID,nombre,tipo,ancho,total,currency,símbolo; 




    **ID** : Viene dado en la regla del formulario.
    
    **nombre** : Nombre que se le quiera asignar al ID.
    
    **tipo** : Tipo de campo que queramos mostrar. Puede ser: **text**, **number**, **checkbox** o **ci**
       
    **ancho** : Asigna el ancho de la columna.


* En el caso que usemos el valor number en tipo, podremos usar los campos total,currency y símbolo.

  **total** : Puede tener los siguientes valores:

	  **sum** : Muestra la suma de todos los valores.

	  **max** : Muestra el máximo valor. 
	  
	  **min** : Muestra el mínimo valor.
	  
	  **count** : Muestra la cantidad de filas. 


  **currency** : Indicamos que nos muestre la separación por comas o por puntos dependiendo del país que le hayamos asignado en `Preferencias` 

   **símbolo** : Símbolo de la moneda que queramos mostrar. 
  
		Ejemplo de uso: numero,Mi numero,number,,sum,currency,€;




### Número máximo de tópicos a listar
* Establece el número máximo de tópicos que se van a mostrar en la tabla.


### Seleccionar tópicos en categorías
* Selecciona las categorías que se quieren mostrar en la tabla.


### Excluir las clases seleccionadas
* Excluye las clases seleccionadas en el punto anterior y muestra el resto que **no** están seleccionadas.


### Usuario asignado a los tópicos
* Permite añadir el filtro el cual solo muestra tópicos asignados a un usuario existente en la herramienta.


### Condición avanzada JSON/MongoDB
* Permite añadir un filtro para las filtrar los topicos y/o categorías a mostrar.
            
        {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25} 


       Donde *id* es la clave una de la categoría. Dicho id se puede consultar a través del REPL.

