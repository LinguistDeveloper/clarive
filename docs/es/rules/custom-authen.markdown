---
title: Reglas de autenticación personalizadas
index: 5000
icon: rule
---

Es posible escribir reglas de autenticación personalizadas usando el editor de reglas de Clarive.

Para crear su propia regla de autenticación es necesario hacer lo siguiente:

### Crear una regla de evento para los intentos de conexión

Desde el editor de reglas, crear una nueva regla de tipo `Evento` asociada al evento `User Login Attempt` (`event.auth.attempt`).


### Escriba los detalles de la regla

Escriba sus propias rutinas de autenticación dentro la regla, por ejemplo, llamar a un servicio web o buscar a un usuario a través de un comando.

Las variables puestos a disposición en el alijo para usted, son los siguientes:* Las variables puestas a disposición del usuario en el stash son:

- `Username` - El ID de usuario, debe coincidir con el registro en la base de datos de usuario en Clarive.
- `Login` - El texto completo introducido en el cuadro de inicio de sesión.
- `Password` - La contraseña introducida por el usuario.
- `Realm` - Define el dominio de autenticación de inicio de sesión que el usuario ha introducido. Puede estar vacío o puede tener algo como 'local' para usuarios locales.

### Permiso para que el usuario se autentique

Arrastre y suelte la tarea `Login usuario autorizado` de la paleta a la regla para autorizar al usuario.

### Denegar la autentificación de un usuario

Arrastre y suelte la tarea `Login usuario denegado` de la paleta a la regla para denegar al usuario el acceso a Clarive.

Considere también el uso del elemento de la paleta `Mensaje de error en el login` para publicar un mensaje de error en caso cuando un usuario que tenga denegada la autenticación lo intente.

### Notas

Si no se permite que ni negar la autenticación de usuario, Clarive seguirá sus controles normales de autenticación.

En caso de que ni se permita ni se niegue de manera explicita la autenticación a un usuario, Clarive seguirá los pasos establecidos en el sistema para ello.

Esta regla invoca la clave de autenticación [Clave API](concepts/api_key).

### Ejemplo

Esta regla es un ejemplo de la estructura básica para validar un usuario mediante una regla. Se puede importar desde las reglas importándola y pegando el código.

```yaml
[{
"attributes": {
    "palette": false,
    "icon": "/static/images/icons/statement-if.svg",
    "disabled": false,
    "on_drop_js": null,
    "key": "statement.if.var",
    "text": "IF username == root",
    "expanded": true,
    "run_sub": true,
    "leaf": false,
    "name": "IF var THEN",
    "active": 1,
    "holds_children": true,
    "data": {
        "variable": "username",
        "value": "root"
    },
    "nested": "0",
    "on_drop": ""
},
"children": [{
    "attributes": {
        "icon": "/static/images/icons/user-delete.svg",
        "palette": false,
        "disabled": false,
        "active": 1,
        "name": "Deny User Login",
        "data": {},
        "key": "service.auth.deny",
        "text": "Deny User Login",
        "expanded": false,
        "leaf": true
    },
    "children": []
}, {
    "attributes": {
        "icon": "/static/images/icons/user-delete.svg",
        "palette": false,
        "disabled": false,
        "active": 1,
        "name": "Login Error Message",
        "data": {
            "msg": "User no way",
            "args": []
        },
        "key": "service.auth.message",
        "text": "Login Error Message",
        "expanded": false,
        "leaf": true
    },
    "children": []
}]
}, {
"attributes": {
    "palette": false,
    "icon": "/static/images/icons/statement-if.svg",
    "disabled": false,
    "on_drop_js": null,
    "key": "statement.if.else",
    "text": "ELSE",
    "expanded": true,
    "run_sub": true,
    "leaf": false,
    "name": "ELSE",
    "active": 1,
    "holds_children": true,
    "data": {},
    "nested": "1",
    "on_drop": ""
},
"children": [{
    "attributes": {
        "icon": "/static/images/icons/user-add.svg",
        "palette": false,
        "disabled": false,
        "active": 1,
        "name": "Authorize User Login",
        "data": {},
        "key": "service.auth.ok",
        "text": "Authorize User Login",
        "expanded": false,
        "leaf": true
    },
    "children": []
}]
}]
```