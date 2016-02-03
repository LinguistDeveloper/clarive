---
title: Busquedas avanzadas
index: 2000
icon: search-small
---
* Existen dos vias para buscar elementos dentro de la herramienta Clarive. La primera es a través del búscador general, situado en la parte superior derecha el cual sirve para buscar (Pases)[ ], Tópicos o CIs. 
* Existe otro cuadro de búsqueda situado en algunas de las pestañas de Clarive como pueden ser informes o listas (listas de tópicos, de usuarios, de roles, etc...). La finalidad de estos cuadros es realizar una búsqueda dentro de la pestaña en la que se encuentra.
* En ambos cuadros el funcionamiento es el mismo, la búsqueda no hace distinciones entre mayúscula y minúscula.
* En caso de buscar dos términos, el motor de búsqueda hará una búsqueda excluyente (búsqueda OR) devolviendo los resultados donde aparezca el primer término y los resultados donde aparece el segundo término. Por ejemplo:
            
        gui seguridad


&nbsp; &nbsp;• Devuelve todos los documentos que tengan gui **o** seguridad en uno de los campos de los documentos.

* Sin embargo:

        +gui +security

&nbsp; &nbsp;• En este caso el resultado de la búsqueda son los documentos donde aparecen las dos palabras en el documento. 

<br />
### Mayúsculas y minúsculas
* Como se ha indicado anteriormente, todas las búsquedas no hacen distinción entre caracteres en mayúscula y en minúscula. Sin embargo si es posible realizar una búsqueda que filtre entre las dos formas. Para ello, es necesario poner la palabra a buscar entre comillas dobles.
            
        "GUI"


&nbsp; &nbsp;• Se muestran solo los resultados donde el término GUI está en mayúsculas.

* Las búsquedas que se pueden realizar dentro de Clarive pueden ser avanzadas utilizando la sintaxis permitida. Además de los ejemplos anteriormente descritos, el motor de búsqueda soporta incluye los siguientes ejemplos: <br />
            
        desarroll?  - Reemplaza ? por un único caracter. Los resultados serán documentos donde aparezcan alguna de estas palabras: desarrollo, desarrolla, desarrolle, etc...

        desarroll*  - Reemplaza * por cualquier cadena de caracteres. Los resultados serán documentos donde aparezcan alguna de estas palabras: desarrollo, desarrollos, desarrollando, etc..

        +termino1 -termino2  - Busca documentos donde aparezca el primer termino pero no el segundo.
       
        /termino regex.*/  - Tambien adminte busquedas con expresiones regulares.


<br />

    
<br />
### Busqueda en un campo concreto
* Clarive tambien soporta buscar por una o varias palabras que estén en un campo del documento en concreto, por ejemplo:
            
        status:"QA Finalizado"

* El resultado solo muestra documentos donde el estado sea 'QA Finalizado'. Esto es muy útil a la hora de buscar un tópico en un determinado estado.

* También se puede acceder a un tópico en concreto desde el cuadro de búsqueda utilizando la # y el número identificador:
            
        #123456
