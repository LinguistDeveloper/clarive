---
title: cla/rule - Ejecución de reglas
index: 5000
icon: page
---

Este *namespace* contiene funciones
que permite a su código interactuar con el
sistema de reglas.

### rule.create(options,tree)

Crea una nueva regla a partir de un árbol de reglas.

El árbol de reglas es una estructura de datos de tipo Array con una o más operaciones (nodos)
que conforman su lógica implementada.

```javascript
var rule = require("cla/rule");
var ruleId = rule.create({ name: "myrule", type: "independent" }, [
    {
        attributes: {
            icon: "/static/images/icons/code.svg",
            key: "statement.code.server",
            name: "Server CODE",
            data: {
                lang: "js",
                code: "cla.stash('returning_value', 999)",
            },
        },
        children: []
    }
]);
```

### rule.run(regla,[stash])

Se ejecuta la regla identificada por el argumento
`rule`, que puede ser un nombre de regla o un id

El `stash` es un Objeto que puede ser creado por el usuario y enviado a una regla. Si el `stash` no se establece, se utilizará el establecido en el ese momento por el programa. Aquel que está contenido en `cla.stash()`.


La función devuelve el `stash` después de la ejecución de la regla.

Ejecución de una regla con el stash vacío:

```javascript
var rule = require("cla/rule");
var stash = rule.run('myrule', {});
```

Ejecución de una regla con el stash actual:

```javascript
var rule = require("cla/rule");
rule.run('myrule');
print( cla.stash("returning_value") );
```

