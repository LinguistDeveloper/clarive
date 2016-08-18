---
title: Administracion de estados
icon: status
---
* Clarive soporta un gran número de estados que pueden ser usados por una gran cantidad de tópicos.
* Para la administración de estados, hay que acceder a través del menú de la izquierda y la opcion de `Elementos de configuración`.
* Se mostrará la lista de Estados creados.

## Columnas
* Las columnas, al igual que el resto de tablas de Clarive, permiten cambiar el orden ascendente/descendente haciendo click en la columna que se quiera ordenar asi como mostrar u ocultar las columnas deseadas
    `Estado`: El nombre del estado. Pulsando sobre el estado se abre la ventana para **editar** el **estado**
    `ID`: El identificador único que corresponde a cada estado
    `Colección`: Colección a la que pertenece el CI. En este caso todos los estados pertenecen a la colección *Estados*.
    `Nemónico`: Se muestra el nombre nemotécnico del estado.
    `Versión`: Versión que corresponde al estado.
    `Fecha`: Fecha de creación del estado.
    `Modificado por`: Muestra el último usuario que ha modificado el estado.

## Opciones

#### Búsqueda
* Como todas las tablas de Clarive, el cuadro de búsqueda interno permite realizar búsquedas y/o filtros de manera personalizada. Estas búsquedas están descritas en [Búsqueda avanzada](getting-started/search-syntax).

#### <img src="/static/images/icons/add.svg" /> Crear
* Pulsando en Crear, se abre una nueva ventana con las opciones necesarias para configurarlo:
    **Nombre**: El nombre que define el estado
    **Descripción**: Una breve descripción del estado.
    **Estado**: Permite especificar si el estado se quiere activo una vez creado.
    **Nemónico**: Permite utilizar un sobrenombre para el estado. Si no se rellena, el nemónico se completará con el nombre del estado.
    **Versión**: Especifica la versión del estado.
    **Entornos**: Permite especificar en que entornos se podrá utilizar el estado.
    **Secuencia**: Un número que permite ordenar los estados en la lista.
    **Agrupar releases**: Indica si los Cambios serán agrupado en una Release en este estado.
    **Agrupar releases**: Indica si los Cambios serán agrupado en una wRelease en este estado.
    **Ver en el árbol de proyecto**: Permite ver todos los tópicos de este estado en el árbol de proyectos en el panel izquierdo de la herramienta.
    **Tipos**: Establece el tipo de estado y su comportamiento:
        *General* - Tipo por defecto. Utilizado para los estados intermedios de un flujo.
        *Inicial* - Estado inicial para un tópico. Tiene que existir al menos un estado inicial para cada categoría. El primer estado de un tópico tiene que ser uno de tipo Inicial.
        *Desplegable* - Desde este estado permite realizar un despliegue. Estos estados aparecerán dentro de los proyectos en el explorador del panel de la izquierda.
        *Cancelado* - Estado final. Los tópicos no podrán progresar más.
         *Final*  - Estado final. Los tópicos no podrán progresar más.
    **Color**: Permite mostrar el tópico que esté en este estado de un color diferente.
    **Ruta de icono**: Personaliza el icono del estado.


##### Otras opciones
    **Dependencias**: Se puede añadir al Estado dependencias de tipo CI.
    **Calendario**
    **Datos**: Se muestran los elementos del estado tales como la clase, si está activo, el icono, etc...
    **Servicios*

#### <img src="/static/images/icons/delete_.png" /> Borrar
* Elimina uno o varios estados seleccionados.

#### <img src="/static/images/icons/export.png" /> Exportar
* Permite exportar uno o varios estados.
* Se pueden exportar en **YAML, JSON, HTML o CSV**.

#### <img src="/static/images/icons/import.png" /> Importar
* Permite importar uno o varios estados desde distintan fuentes.
* Se pueden importar estados que estén en alguno de los siguientes formatos **YAML, JSON, HTML o CSV**.