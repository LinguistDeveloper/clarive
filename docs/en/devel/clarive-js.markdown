---
title: The Clarive JavaScript DSL
index: 300
---

Accessing the powerful Clarive functionality from the JS DSL
is done through the `Cla` singleton object, from where a hierarchy 
of modules and namespaces hang:

These are the top-level namespaces available:

- `Cla` - top level namespace and shortcuts to other often used utilities
- `Cla.ci` - CI manipulation
- `Cla.db` - MongoDB database manipulation
- `Cla.log` - Logging
- `Cla.fs` - Filesystem manipulation
- `Cla.path` - File path manipulation
- `Cla.rule` - Rule manipulation
- `Cla.sem` - Semaphores
- `Cla.util` - Generic utilities
- `Cla.web` - Web tools 
- `Cla.ws` - Webservice rule Request/Response

More namespaces may be available to the developer 
as they can be added by `require()` modules. 

## Cla functions

The Cla namespace encapsulates all classes, singletons and
functions provided by Clarive's JS API. 

Most useful functions are at a lower level of nesting in the namespace, 
but many common utility functions are provided as direct properties of the Cla namespace.

Many applications are initiated with Ext.application which is called once the DOM is ready. This ensures all scripts have been loaded, preventing dependency issues. For example:

#### Cla.stash()

Gets and sets data in and out of the current [stash](concepts/stash). 

    Cla.stash("filename", "/tmp/file.txt");  
    print( Cla.stash("filename") );

    // it also supports nested data structures with JSON pointers
    Cla.stash("/domain/filename", "/tmp/file.txt");  
    print( Cla.stash("domain.filename") );

To read or set data in nested levels, Clarive implements 
a subset of the standard ISO JSON pointers:

- `/foo/bar` - get/sets the key `stash.foo.bar`
- `//foo/bar` - turns off pointers, get/sets the key `stash["/foo/bar"]`
- `foo/bar` - not a pointer if it doesn't start with a forward 
slash `/`, so it get/sets the key `stash["foo/bar"]`
- `/foo/0` - get/sets the key `stash["foo"][0]` from an array 
- `/foo/0/bar` - get/sets the key `stash["foo"][0]["bar"]` from an object within an array 

#### Cla.config()

Gets and sets configuration data into the Clarive config system.

The config system in Clarive is built through the combination of 3 
layers of values:

- From the current and global environment files (clarive.yml, env.yml)
- Command-line parameters when starting the server

    // gets the value from workers in the clarive.yml file
    var wks = Cla.config("workers");

    // our current database name
    var dbname = Cla.config("/mongo/dbname");

This is useful for creating site specific .yml files
and putting your automation configuration in there. 

#### Cla.configTable()

Gets and sets configuration data from/to the [config table](concepts/config-table).

The config system in Clarive is built through the combination of 3 
layers of values:

    // gets the value from workers in the clarive.yml file
    var gitHome = Cla.configTable('config.git.home');

The config table is a flat table with values separated with
dots `.`, such as `config.git.home`. 

This is also useful for creating administrator modifiable global configuration
values that can be easily changed without editing the rule, although 
in general, it's better to use [variables](concepts/variable) (CI) for that.

#### Cla.parseVars(target,data)

This function replaces Clarive variables (`${varname}`) 
in strings or any nested data 
structure, such as arrays and objects. The values for the 
variables will come either from the `data` argument or
the [stash](concepts/stash).

    Cla.stash("foo", 99);
    var txt = Cla.parseVars("This is feet"); // This is 99 feet

    Cla.stash("name", "Haley");
    var txt = Cla.parseVars("Hello ${name}", { name: "Joe" });  // Hello Joe


### Cla.printf(fmt,args)

Prints a string formatted by the usual printf conventions of the C library function sprintf. 

    Cla.printf("This file is %d bytes long", Cla.fs.stat("/tmp/myfile").size );

### Cla.sprintf(fmt,args)

Returns a string formatted by the usual printf conventions of the C library function sprintf. 

    var msg = Cla.sprintf("This file is %d bytes long", Cla.fs.stat("/tmp/myfile").size );
    print( msg );

### Cla.dump(data)

Prints the data in the data structure
dumped using YAML format. 

### Cla.loc(lang,str,arguments)

Localizes the string using I18N formatting 
for the lang specified in the lang string.
This function uses the Clarive I18N translation files.

    var jobNum = 1234;
    var msg = Cla.loc("es","Job %1 started", jobNum );
    print( msg );

### Cla.lastError()

Returns the last error string.

