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
* Para añadir una columna a la tabla basta con incluir su ID en este campo. El ID vinen dado en la regla del formulario.
* Para separar las columnas se utiliza el **;**

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

