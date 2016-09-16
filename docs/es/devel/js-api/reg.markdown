---
title: cla/reg - Manipulación del registro
index: 5000
icon: page
---

El registro Clarive sostiene los puntos de extensión en muchas partes del
el sistema, tanto el cliente como el servidor.


Estas funciones son sobretodo útiles en `init/`, puntos de entrada de plug-in para registrar cosas como las operaciones de la paleta (servicios), las entradas de menú, eventos y demás.

### cla.register()

Crea una entrada de registro en Clarive.

En el siguiente ejemplo, se crea una nueva entrada en el menú.

```javascript
var reg = require('cla/reg');
reg.register('menu.admin.test',{ name: 'Test Menu', url: '/comp/testmenu.js' });
```

### cla.launch(clave,opcs)

Lanza un servicio de registro.

```javascript
var reg = require('cla/reg');
reg.register('service.test',{
    name: 'Foo Service',
    handler: function(){ return 99 }
});

reg.launch('service.test', { name: 'just trying this out', config: { foo: 'bar' } });
```

Opciones:

- `config` - Un objeto de configuración que se enviará al controlador.
- `name` - Informa el nombre de la operación para que quede la información de registro es más descriptivo.
- `dataKey` - Informa el nombre de la operación para que quede la información capturada en el log sea más descriptiva.
- `stash` - Un *stash* alternativo; por defecto es el *stash* actual.