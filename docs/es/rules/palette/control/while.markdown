---
title: WHILE condition
icon: statement-loop
---

El control WHILE permite iterar un bloque de código mientras la condición o condiciones indicadas se cumplan.

El bloque del WHILE primero comprueba si la condición se cumple y posteriormente ejecuta el código. En caso de que el usuario necesite ejecutar primero el bloque de código y después comprobar la condición, consulte el documento sobre [DO-WHILE](rules/palette/control/do-while).

Para configurar la operación WHILE, se deben de configurar los siguientes valores:

- `Variable Stash` - Nombre de la variable que será evaluada en la condición.
- `Operador` - El operador de la condición.
- `Opciones` - Permite establecer algunas opciones en función del operador indicado anteriormente.
- `Valor` - El valor con el que se comparará el `Stash Variable`.

### Operadores

Los siguientes operadores están disponibles en la lista desplegable:

- `IS TRUE` y `IS FALSE` - evalúa el valor de la variable stash para verdadero o falso. El valor *undefined*, cero (0) o en blanco ('').
- `IS EMPTY` - comprueba si la variable del stash está vacía. Un valor vacío, un array vacío o un hash vacío se considerará verdadero.
- `EQUAL` - compara si dos cadenas de texto o números son iguales.
- `LESS THAN`, `LESS THAN EQUALS`, `GREATER THAN`, `GREATER THAN EQUALS` - compara dos valores y devuelve verdadero o falso en función de si el valor de stash es menor, menor o igual, mayor o mayor o igual, que el valor indicado en el campo `Valor`
- `LIKE` - compara el valor de stash con una expresión regular (como `h..a mundo$`) indicada en el campo `Valor`.
- `IN` - compara si la variable de stash (un único valor) está en la lista (un array) indicada en el campo `Valor`. Este operador es útil si el campo valor contiene una variable que se resuelve como un array.
- `HAS` - compara si la lista (array) indicada en el valor stash contiene el elemento indicado en el campo `Valor`. Este operador es útil si el valor del stash es un array.

### Opciones

Las siguientes opciones están solo disponibles para ciertos operadores de comparación:

- `Ignorar mayúsculas` - ignora diferencias entre las mayúsculas y minúsculas en las comparaciones de texto.
- `Numérico` - realiza la comparación en un contexto numérico.

