---
title: Cla.util - general utilities namespace
---

General utilities. 

### Cla.util.dumpYAML(data)

Dumps the `data` argument as [YAML](devel/yaml). 

    var data = { foo: 123 };
    print( Cla.util.dumpYAML(data) );

### Cla.util.loadYAML()

Loads `data` from a [YAML](devel/yaml) string. 

    var yaml = "---\nfoo: 12\n";
    print( Cla.util.loadYAML(yaml) );

### Cla.util.dumpJSON(data)

Dumps the `data` argument as [JSON](https://en.wikipedia.org/wiki/JSON).

    var data = { foo: 123 };
    print( Cla.util.dumpJSON(data) );

### Cla.util.loadJSON()

Loads `data` from a [JSON](https://en.wikipedia.org/wiki/JSON) string. 

    var json = '{ "foo": 30 }'
    print( Cla.util.loadJSON(json) );

### Cla.util.unaccent(str)

Removes accents and other strange characters from a given string, 
replacing them with their equivalent character without accent;

    print( Cla.util.unaccent("résumé") ); // returns "resume"

### Cla.util.benchmark(n,code)

Executes the block of `code` a total of `n` times and prints the 
timing results. This is useful to help debug performance issues
test how performant a code is before using it in production.

    Cla.util.benchmark(1000, function(){
        for( var i=0; i<100; i++) {
            var x = i * 2;
        }
    });

Which prints out the following results (depending on your system performance):

`timethis 100:  4 wallclock secs ( 4.16 usr +  0.03 sys =  4.19 CPU) @ 23.87/s (n=100)`

