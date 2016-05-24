---
title: cla/ci - CI Classes
---

Programmatically speaking, each Configuration Item (CI)
can have both data and behaviour encapsulated into each
CI Class and CI instance.

## Instantiating an CI from the DB

Instantiate a CI means to load an existing CI from
the Clarive CI database.

This is accomplished using the `ci.load(mid)` function.

```javascript
var ci = require("cla/ci");
var server = ci.load(123);
```

## Instanciating CIs

To create a CI, first we need to load the desired CI class as a
class variable:

```javascript
var ci = require("cla/ci");
var GenericServer = ci.getClass('GenericServer');
```

Now we can generate an *in-memory* instance of the CI. This instance
is generaly usable, except that it's not yet permanent in the
database.

To save a CI to the database, we just have to invoke the `save()` method.

```javascript
var ci = require("cla/ci");
var GenericServer = ci.getClass('GenericServer');
var server = new GenericServer({ name: 'myhost', hostname:'myhost.intranet' });
server.save();
```

The `save()` method returns an `mid`, which identifies the CI in the database.

## Creating your own CIs

You can create your own CI classes, with its corresponding
storage and methods.

```javascript
var ci = require("cla/ci");
ci.create("MyClass",{
    has:{
        ipAddress: { is:"rw", isa:"Str", required: true }
    },
    superclasses: ['GenericServer']
});

var obj = ci.build("MyClass",{ ipAddress: 22, hostname:'myhost.intranet' });
obj.ipAddress();

//alternatively
var MyClass = ci.getClass("MyClass");
var obj  = new MyClass({ ipAddress: '123.0.0.1', hostname:'myhost.intranet' });

// now all CI methods will be available
var mid = obj.save();
var again = ci.load(mid);
```

Once you create your own CI class, you cannot add new methods or attributes.

## Searching CIs

Searching for CIs can be done in 2 different ways,
by returning instantiated CI objects or database documents.

The main difference resides in that database documents are faster to
retrieve, but can be only used *read-only*. CI objects have methods
that and can be manipulated and persisted.

### ci.find([class], query)

Returns a cursor for a result set of CI database documents.
The cursor has the same methods as a database cursor.

```javascript
var ci = require("cla/ci");
var rs = ci.find({ hostname: cla.regex("^127.0") });
rs.forEach(function(doc) {
    print( doc.mid );
});
```

Optionally, a class can be sent as a parameter to limit
the search to documents that belong only to that class.

```javascript
var ci = require("cla/ci");
var rs = ci.find('Status', { name: cla.regex('QA') });
print( rs.next() );
```

### ci.findOne([class], query,options)

Returns the first document that matches the query.

```javascript
var ci = require("cla/ci");
var doc = ci.findOne({ mid:"123" });
print( doc.mid );
```

Optionally, a class can be sent as a parameter to limit
the search to documents that belong only to that class.

```javascript
// find a document within the Status class only
var ci = require("cla/ci");
var doc = ci.findOne('Status', { name: cla.regex('^QA') });
```

### ci.load(mid)

Instantiate a previously persisted CI from the database.

### ci.delete(mid)

Deletes a CI with the given `mid`.

## General availability of a class

To be able to fully use a CI class outside of a rule code, the CI class must be loaded
as part of Clarive's startup process.

Put the JS file for the class in the corresponding `$CLARIVE_BASE/plugin/[plugin-name]/cis` folder
so that it's picked up by the `cla` command during system startup.

## Meta Programming

The following instrospection of the CI class system is available:

### ci.listClasses([role])

Returns an Array of loaded CI classes in Clarive.

With the optional parameter `role`, filters the list that do a given role.

```javascript
var ci = require("cla/ci");
var all = ci.listClasses();
var appservers = ci.listClasses('ApplicationServer');
```

This is useful to check if a certain dependent module is loaded before attempting
a given operation.

