---
title: Administracion de estados
icon: status
---

* Clarive soporta un gran número de estados que pueden ser usados por una gran cantidad de tópicos.

* Para la administración de estados, hay que acceder a través del menú de la izquierda y la opcion de `Elementos de configuración`.

* Se mostrará la lista de Estados creados. 

<br />
## Columnas

* Las columnas, al igual que el resto de tablas de Clarive, permiten cambiar el orden ascendente/descendente haciendo click en la columna que se quiera ordenar asi como mostrar u ocultar las columnas deseadas.<br />

&nbsp; &nbsp;• `Estado`: El nombre del estado. Pulsando sobre el estado se abre la ventana para **editar** el **estado** <br />

&nbsp; &nbsp;• `ID`: El identificador único que corresponde a cada estado <br />

&nbsp; &nbsp;• `Colección`: Colección a la que pertenece el CI. En este caso todos los estados pertenecen a la colección *Estados*. <br />

&nbsp; &nbsp;• `Nemónico`: Se muestra el nombre nemotécnico del estado. <br />

&nbsp; &nbsp;• `Versión`: Versión que corresponde al estado. <br />

&nbsp; &nbsp;• `Fecha`: Fecha de creación del estado. <br />

&nbsp; &nbsp;• `Modificado por`: Muestra el último usuario que ha modificado el estado.



<br />
## Opciones

<br />
#### Búsqueda

* Como todas las tablas de Clarive, el cuadro de búsqueda interno permite realizar búsquedas y/o filtros de manera personalizada. Estas búsquedas están descritas en [Búsqueda avanzada](Primeros_pasos/search-syntax)

<br />
#### <img src="/static/images/icons/add.gif" /> Crear

* Pulsando en Crear, se abre una nueva ventana con las opciones necesarias para configurarlo: <br />

&nbsp; &nbsp;• **Nombre**: El nombre que define el estado.<br />

&nbsp; &nbsp;• **Descripción**: Una breve descripción del estado. <br />

&nbsp; &nbsp;• **Estado**: Permite especificar si el estado se quiere activo una vez creado. <br />

&nbsp; &nbsp;• **Nemónico**: Permite utilizar un sobrenombre para el estado. Si no se rellena, el nemónico se completará con el nombre del estado. <br />

&nbsp; &nbsp;• **Versión**: Especifica la versión del estado. <br />

&nbsp; &nbsp;• **Entornos**: Permite especificar en que entornos se podrá utilizar el estado. <br />

&nbsp; &nbsp;• **Secuencia**: Un número que permite ordenar los estados en la lista. <br />

&nbsp; &nbsp;• **Agrupar releases**: Indica si los Cambios serán agrupado en una Release en este estado. <br />

&nbsp; &nbsp;• **Agrupar releases**: Indica si los Cambios serán agrupado en una wRelease en este estado. <br />

&nbsp; &nbsp;• **Ver en el árbol de proyecto**: Permite ver todos los tópicos de este estado en el árbol de proyectos en el panel izquierdo de la herramienta. 

&nbsp; &nbsp;• **Tipos**: Establece el tipo de estado y su comportamiento: <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp;• *General* - Tipo por defecto. Utilizado para los estados intermedios de un flujo. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp;• *Inicial* - Estado inicial para un tópico. Tiene que existir al menos un estado inicial para cada categoría. El primer estado de un tópico tiene que ser uno de tipo Inicial. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp;• *Desplegable* - Desde este estado permite realizar un despliegue. Estos estados aparecerán dentro de los proyectos en el explorador del panel de la izquierda. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp;• *Cancelado* - Estado final. Los tópicos no podrán progresar más. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp;• *Final*  - Estado final. Los tópicos no podrán progresar más. <br />

<br />
&nbsp; &nbsp;• **Color**: Permite mostrar el tópico que esté en este estado de un color diferente. <br />

&nbsp; &nbsp;• **Ruta de icono**: Personaliza el icono del estado.


<br />
##### Otras opciones

<br />

&nbsp; &nbsp;• **Dependencias**: Se puede añadir al Estado dependencias de tipo CI. <br />

&nbsp; &nbsp;• **Calendario** <br />

&nbsp; &nbsp;• **Datos**: Se muestran los elementos del estado tales como la clase, si está activo, el icono, etc... <br />

&nbsp; &nbsp;• **Servicios**<br />

<br />
#### <img src="/static/images/icons/delete_.png" /> Borrar

* Elimina uno o varios estados seleccionados.

<br />
#### <img src="/static/images/icons/export.png" /> Exportar

* Permite exportar uno o varios estados. 

* Se pueden exportar en **YAML, JSON, HTML o CSV**.

<br />
#### <img src="/static/images/icons/import.png" /> Importar

* Permite importar uno o varios estados desde distintan fuentes. 

* Se pueden importar estados que estén en alguno de los siguientes formatos **YAML, JSON, HTML o CSV**.