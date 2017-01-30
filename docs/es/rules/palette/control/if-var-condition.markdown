---
title: IF var condition THEN
icon: statement-if
---

Permite el uso de múltiples condiciones dentro de un paso condicional.

Para configurarlo, tenemos algunos combos para personalizar nuestras condiciones:

### Cuando

Especifica cuando el paso IF será VERDADERO y por lo tanto, entrará dentro del paso ejecutando los elementos anidados al IF:

- **Cualquiera** - Al menos una de las condiciones es cierta, funciona como un OR lógico (x OR y OR z).
- **Todos** - Todas las condiciones que se han configurado tienen que ser ciertas para continuar el flujo por dentro del IF. El funcionamiento lógico es como un AND (x AND y AND z).
- **Ninguno** - Accede al IF cuando ninguna de las condiciones se cumple. El funcionamiento es similar a !(x AND y AND z).

### Condición

Establece una condición para el IF:

- **Variable de Stash** - Se especifica la variable del stash que será evaluada.
- **Operador** - Establece el tipo de operador.

En algunos casos (como 'EQUALS') es necesario configurar dos parámetros más:

- **Ignorar Mayúsculas** - Active la casilla si quiere ignorar las mayúsculas y minúsculas.
- **Numérico** - Compara los valores como números y no como un cadena de texto
- **Valor** - Se establece el valor con el que se comparará la variable introducida en el campo 'Variable de Stash'.

**Eliminar** - Elimina la condición.

**Añadir condición** - Permite añadir una nueva condición al IF.