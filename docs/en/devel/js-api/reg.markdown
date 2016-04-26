---
title: cla/reg - Registry Manipulation
---

The Clarive registry holds extension points to many parts of
the system, both client and server.

These functions are mostly useful in `init/` plugin entrypoints to register
things like palette operations (services), menu entries, events and others.

### cla.register()

Creates a registry entry in Clarive.

In the following example, we create a new menu entry.

```javascript
var reg = require('cla/reg');
reg.register('menu.admin.test',{ name: 'Test Menu', url: '/comp/testmenu.js' });
```

### cla.launch(key,opts)

Launches a registry service.

```javascript
var reg = require('cla/reg');
reg.register('service.test',{
    name: 'Foo Service',
    handler: function(){ return 99 }
});

reg.launch('service.test', { name: 'just trying this out', config: { foo: 'bar' } });
```

Options:

- `config` - a config object to be sent to the handler
- `name` - report the op name so that it's logging information is more descriptive
- `dataKey` - report the op name so that it's logging information is more descriptive
- `stash` - an alternative stash; defaults to the current stash
