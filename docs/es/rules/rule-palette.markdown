---
title: Paleta de reglas
index: 3000
icon: rule
---

Las operaciones (ops) de la paleta ofrece los mecanismos necesarios para crear reglas para automatizar.

Todos ellos tienen un menú contextual con las siguientes opciones:

### Configuración

Dependiendo de la operación escogida, se muestra la ventana de configuración del elemento con los elementos necesarios para su correcto funcionamiento.

Toda la información de cada campo se describe en el momento de abrir la configuración del elemento..

### Renombrar

Se abre una ventana para introducir el nuevo nombre para la operación.
Por defecto, el nombre de la operación es el mismo que se muestra en la paleta.

- **Aceptar** - Guarda cualquier cambio que se haga en el nombre y cierra la ventana.
- **Cancelar** - Cierra la ventana sin guardar los cambios, en caso de haberlos realizado..

### Propiedades

Las propiedades de las operaciones si son comunes para todas las operaciones usadas en una regla.

Se muestra una ventana con tres pestañas habilitadas, las acciones disponibles son:

- **Cancelar** - Cancela todos los cambios que se realicen desde la ultima vez que se guardaron y cierra la ventana.
- **Aceptar** - Guarda todas las propiedades y metadatos que han sido modificados. Una vez guardadas las propiedades es posible que se incluya alguna etiqueta en la operación para indicar algún parámetro establecido.

Las pestañas de esta ventana son:

### **1. Opciones** - Parámetros configurables para ejecutar la operación:

*Habilitado* - Habilita/deshabilita la operación. Por defecto está la casilla activada.

*Clave de retorno* - Clave del stash definida por el usuario donde los datos de salida son guardados después de la ejecución de la operación. Este valor puede ser accesible a través del stash en forma:

     cla.stash("<return_key_value>.output");

*¿Es necesaria marcha atrás?* - Flag que controla cuando se debe realizar el rollback en caso de fallo en el mismo pase.

Se se detecta un error, comienza el rollback.

Por defecto, el valor es *Rollback no necesario*.

El usuario establece cuando salta el flag de acuerdo a 4 opciones:

- *La marcha atrás será necesaria después* - El flag se establece después de la ejecución de la operación.
- *La marcha atrás será necesaria antes* - El flag se establece antes de la ejecución de la operación.
- *Marcha atrás necesaria siempre* - El flag se establece en el momento de construir el DSL.
- *No es necesario el rollback* - El flag no se establece nunca.
- *Se necesita clave de rollback* - Relacionada con la opción anterior, es un campo de texto que se muestra cuando la opción `¿Es necesaria marcha atrás?` es diferente al valor 'No es necesario rollback'. Define la operación que será ejecutada en caso de error. El rollback está implementado para operaciones de scripting y gestión de archivos.
- *Sólo en Marcha Adelante* - La operación se ejecuta si el pase avanza hacia adelante.
- *Sólo en Marcha Atrás* - Se ejecuta la operación solo si se está realizando un rollback.
- *Timeout* - Número de segundos para que la regla ejecute el elemento, si se llega al número de segundos establecido, se informa al usuario a través de un mensaje.
- *Clave de semáforo* - Pide un intervalo de tiempo para ejecutar la regla. Una vez terminada la ejecución el semáforo se libera.
- *Modo paralelo* - Define como se ejecuta la regla, si los procesos se pueden ejecutar de manera paralela o en serie. Por defecto, el valor es `No paralelo`. Existen tres opciones más disponibles:
   - *No paralelo* - Todas las operaciones se ejecutan tal y como están en la regla.
   - *Fork and Wait* - La regla se ejecuta en modo paralelo, y después, espera a que los procesos hijos terminen.
   -*Fork and Leave* - La regla se ejecuta en modo paralelo pero no espera al resultado de los hijos.
- *Debug Mode* - Permite depurar la operación. Existen tres opciones:
   - *No debug* - No muestra información interna al ejecutar la operación.
   - *Op trace* - Muestra información de la traza.
   - *Op Trace + Stash Dump* - Muestra información de la traza y vuelca la información del stash actual en el log.
- *Captura del error* - Define como tratar un error en una operación en caso de que ocurra. Por defecto, el valor establecido es `No Trap`. Hay 3 opciones más:
   - *No Trap* - Los errores no son tratados.
   - *Trap Errors* - Se trata al error y se espera a la acción del usuario, dichas acciones son:
     - Retrying - Reintentar la operación.
     - Skipping - Omitir la operación.
   - *Ignorar errores* - El error es ignorado.
- *Trap timeout (segundos)*: Establece el número de segundos antes de lanzar un trap.
- *Trap timeout action*: Establece la acción a realizar tras un timeout:
   - Abortar - Aborta la operación.
   - Ignorar - Ignora el error.
   - Reintentar - Reintenta ejecutar de nuevo la operación.
- *Máximo número de reintentos (0 ilimitado)* - Permite establecer al usuario el número máximo de reintento en caso de error durante la operación.
- *Trap in Rollback?* - Activa o desactiva los errores si se está ejecutando el rollback.

### **2. Metadatos**

Pestaña donde se incluye los metadatos de la operación, los cuales definen las propiedades de la misma así como su comportamiento. Se muestran tres columnas que contienen:

- **Clave** - Define la operación
- **Tipo** - Atributo de tipo valor, puede ser:
   - **Valor** - Valor clave de tipo simple.
   - **Array** - Valor clave de tipo array.
   - **Hash** - Valor clave de tipo hash.

El contenido de esta pestaña depende del tipo de operación y de las propiedades realizadas por el usuario en la pestaña Opciones.
A continuación se describen algunos atributos comunes a todas las operación una vez dicha operación ha sido arrastrada desde la paleta a la regla:

- `Key` - Define la operación.
- `ID` - ID de la instancia de la operación, el valor lleva la connotación `xnode-*number*`.
- `Name` - Nombre de la operación, una breve descripción de la finalidad de la operación.
- `Text` - Por defecto, este valor es el nombre de la operación. Este campo se puede cambiar a través del Renombre visto anteriormente.
- `Icon` - Icono de la operación, describe de una manera gráfica la finalidad de la operación.
- `Leaf` - Establecido a 0, esta clave indica si esta operación puede tener operaciones anidadas o no.

Cuando se guardan mas metadatos, se establecen otros atributos como:

- `Data` - Este atributo es un hash con los datos que se han introducido en la configuración del elemento.
- `Data_key` - Contiene el valor introducido por el usuario en la Clave de retorno.
- `Disabled` - Establecido a *true* si se ha deshabilitado la operación en la pestaña anterior.
- `Expanded` - Se establece a *true* si la operación contiene otras operaciones anidadas.
- `Run_forward` - Aparece si el usuario ha modificado la propiedad *run_forward*. Se establece a *true* si la propiedad está activada.
- `Run_rollback` - Muestra si el usuario ha habilitado la propiedad *run_rollback*. Se establece a *true* si la propiedad está activada.
- `Parallel_mode` - Indica el modo de procesamiento del elemento. Puede tener tres valores diferentes:
   - *None* - Proceso ejecutándose en serie.
   - *Nohup* - Proceso ejecutando en modo *fork and leave*
   - *Fork* - Proceso ejecutando en modo *fork and wait*.
- `Error_trap` - Indica como tratar los errores. Puede tener tres valores:
   - *None* -  Sin tratamiento de errores.
   - *Ignored* - Ignora el error.
   - *Trap* - Identifica el error y espera una acción externa.
- `Semaphore_key` - Contiene el nombre del semáforo que el usuario ha introducido en la pestaña anterior.
- `Timeout` - Contiene el número de segundos a esperar.
- `Note` - Contiene el contenido de la pestaña Notas.
- `Qtip` - Igual que la nota. Sus atributos dependen del tipo de operación seleccionada:
- `Statements`
	- *Holds_children* - Indica si la operación puede contener otras operaciones
	- *Nested* - Si está a 0, este atributo indica que la operación es el comienzo de una función de código.
- `Children` - Hash que contiene las operaciones anidadas
- `Services`
- `Rules`
	- *Id_rule* - El valor de esta clave es el id de la regla.


### **3. Nota**

Pestaña para incluir notas escritas por el usuario

### Nota
Se muestra una ventana que incluye las operaciones de notas introducidas por el usuario o por el usuario para incluir.
Se muestra una ventana con las notas de las operaciones introducidas por el usuario o para incluir por el usuario

### Copiar

Copia una operación de una regla al portapapeles.

### Cortar

Corta una operación de una regla al portapapeles.

### Paste

Pega, si es posible, una operación de una regla desde el portapapeles.

### DSL

Muestra una ventana con el título DSL: `<nombre de la regla>`.

Una pestaña de acción y tres zonas diferentes se muestran en la ventana de DSL, la pestaña de acción se compone de

En la ventana DSL se muestra una pestaña de acciones y tres áreas diferentes. La pestaña de acciones se compone de:

- **Ejecutar** - Botón para ejecutar el código DSL que aparece en el área DSL. Las áreas son:
- **Área Stash** - Cuadro de texto con las variables del stash en formato YAML. Las variables pueden ser establecidas por el usuario, si el tipo de regla es regla de pase, aparecen tres variables de stash por defecto:
   - changesets: []
   - elements: []
   - job_step: CHECK
- **Área DSL** - Cuadro de texto con el código DSL de la operación y su configuración, el código puede ser modificado y ejecutado desde aquí.
- **Área de salida** - Área de texto con dos pestañas:
   - **Output** - Resultado del código ejecutado por el DSL.
   - **Stash** - Los valores del stash, resulta de la ejecución del código DSL.
- **Interruptor** - Habilita/Deshabilita la operación. Si la operación está deshabilitado, una linea se muestra sobre el nombre de la operación.
- **Borrar** - Elimina la operación seleccionada.
