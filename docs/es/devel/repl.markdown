---
title: REPL
index: 150
icon: page
---

REPL significa Read Eval Print Loop, es decir,
una interfaz para probar código mientras lo desarrollamos.

Clarive REPL es especialmente importante en el proceso de desarrollo,
ya que permitirá a los desarrolladores probar el código
dentro del entorno de servidor Clarive. El servidor
entorno incluye cosas como la conexión a la base de datos,
el acceso a los servidores. De esta forma puede probar el código
con pruebas reales.

## Componentes REPL

REPL que cuenta con 3 paneles principales:

- La zona de entrada de código, donde se debe introducir el código.
- El panel de la izquierda, donde están dos árboles con el histórico y los elementos guardados.
- El panel inferior donde se muestra la salida.

## Guardado automático de preferencias de usuario

Por defecto CLARIVE REPL guardara los valores que se toman para los siguientes menús:

- Menú de Lenguajes.
- Menú de Salidas.
- Menú de Temas.

La siguiente vez que el usuario entra en el REPL se cargarán los últimos valores cargados.


### Panel de Salida

El panel de salida lleva a cabo una representación de los datos
**por la evaluación de la última línea de la REPL**. En ambos
Perl y JS, simplemente poniendo la variable o el valor en la última línea
es suficiente para producir una salida.

Este código REPL:

```javascript
var xx = [1,2,3];
xx;
```

Los resultados en la siguiente representación:

```yaml
---
- 1
- 2
- 3
```

También, el motor del REPL captura todas las salidas estandar,
STDOUT y STDERR generadas por el código, incluyendo las excepciones
lanzadas

Este código:

```javascript
print( 123 );
```

Produce la siguiente salida (YAML):

```yaml
123

--- ~
```

Lo que básicamente se traduce como `123` impreso y un` undefined`
devuelve un valor de retorno representado por YAML, que comienza con `---`.

### Árbol de Historicos

El árbol de historicos de las últimas 20 ejecuciones de código son *únicas*
para la sesión del usuario actual.

Cada vez que se envía al servidor código, una entrada se guarda en el
árbol de la historia para esa sesión de usuario.

Si el usuario cierra la sesión y registra de nuevo, se pierde su usuario.

### Árbol de Guardado

El árbol de guardados llevará a cabo todos los guardados REPL. El árbol pertenece a
el usuario y se unirá a él durante el tiempo que no se elimina el usuario.

La eliminación de un usuario borra todas las entradas guardadas en el REPL.

## Uso del REPL

Introduzca un código en el panel principal del editor y pulsa `Ctrl-Enter` o `Cmd-Enter` (en Mac)
a presentar el código para su ejecución.

### Cancelación de una ejecución

Para cancelar una ejecución en realidad no matar el proceso
en el servidor, sólo que devuelve el control al usuario.

Eso significa que un servidor puede estar sobrecargado por solicitudes
si se ejecutan demasiados procesos REPL de ejecución larga.

#### Run

Ejecuta el REPL. Equivalente a ejecutar `Ctrl-Enter` o` Cmd-Enter`.

#### Menú de Lenguajes

El REPL permite la ejecución de 4 tipos de código, controlado
por el menú desplegable Idioma:

- Clarive JavaScript (Clarive JS).
- Perl (requiere permisos especiales).
- Clarive UI Web JS (ejecutado por el navegador).
- DB Code.

Esto es controlado por el menú `Lang` desplegable.

#### Menú de salida

Permite al usuario seleccionar el formato de los datos
se muestra en la parte inferior.

- YAML - la estructura de datos se muestra en formato YAML.
- JSON - la estructura de datos se muestra en formato JSON.
- Table - intentará dar formato a una tabla HTML a partir de una matriz (o similar tipo de lista).
- Data Editor - intentará mostrar un componente de interfaz de usuario del editor de datos con un objeto (JS) o hash tipo de datos / Diccionario.

#### Botón de Guardar

Guardará el actual REPL en el guardado de usuario.
Lista REPL.

#### Exportar todo a un fichero

Todas las exportaciones REPL se guardan en archivos en el sistema de archivos.

#### Borrar

Elimina el REPL actual en caso de que se haya guardado.

#### Ordenado

Reformatea (alias *embellece*) el código para que sea ordenada
y más legible.

#### Tiempo transcurrido

Este es el tiempo, en segundos, que el script tardo en compilar (a código de bytes) y ejecutar.

Esto es importante para obtener una perspectiva de la rapidez y la duración de una secuencia de comandos puede ejecutar, por lo que el desarrollador puede ajustar con precisión su ejecución.