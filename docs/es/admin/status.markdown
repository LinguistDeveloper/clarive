---
title: Administración de estados
index: 5000
icon: status
---

Clarive soporta un gran número de estados que pueden ser usados por una gran cantidad de tópicos.

Para la administración de estados, hay que acceder a través del menú de la izquierda y la opción 
<img src="/static/images/icons/class_grey.svg" /> Elementos de configuración.

Se mostrará la lista de estados creados.

Las siguientes acciones están disponibles encima de la lista de estados:

- Búsqueda de todos los estados que contienen la cadena de búsqueda introducida
- Eliminar el estado seleccionado - Todos los estados marcados serán eliminados.
- Importar/Exportar los datos de configuración del estado seleccionado:

Haciendo clic en el botón de exportación, los datos de configuración se pueden exportar
en formatos YAML, JSON, HTML y CSV.

Esto es útil para compartir e intercambiar la información del estado.


#### <img src="/static/images/icons/add.svg" /> Crear un nuevo estado

Pulsando en Crear, se abre una nueva ventana con las opciones necesarias para configurarlo:

- `Nombre` - El nombre que define el estado
- `Descripción` - Una breve descripción del estado.
- `Estado` - Permite especificar si el estado se quiere activo una vez creado.
- `Nemónico` - Permite utilizar un sobrenombre para el estado. Si no se rellena, el nemónico se completará con el nombre del estado.
- `Versión` - Especifica la versión del estado.
- `Entornos` - Permite especificar en que entornos se podrá utilizar el estado.
- `Secuencia` - Un número que permite ordenar los estados en la lista.
- `Agrupar releases` - Indica si los Cambios serán agrupado en una Release en este estado.
- `Ver el árbol de proyecto` - Permite ver todos los tópicos de este estado en el árbol de proyectos en el panel izquierdo de la herramienta.

#### **Tipos de estado**

- `General` - Tipo por defecto. Utilizado para los estados intermedios de un flujo.
- `Inicial` - Estado inicial para un tópico. Tiene que existir al menos un estado inicial para cada categoría. El primer estado de un tópico debe ser uno de tipo Inicial.
- `Desplegable` - Desde este estado permite realizar un despliegue. Estos estados aparecerán dentro de los proyectos en el explorador del panel de la izquierda.
- `Cancelado` - Estado final. Los tópicos no podrán progresar más.
- `Final` - Estado final. Los tópicos no podrán progresar más.
- `Color` - Permite mostrar el tópico que esté en este estado de un color diferente.
- `Ruta de icono` - Personaliza el icono del estado.