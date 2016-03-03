---
title: Cla.path - Path manipulation
---

These utilities are useful for manipulating 
how paths names are broken down and reassembled 
together, and can come in handy for calculating 
relative paths.

### Cla.path.basename(path)

Extracts the file name and extension part from 
a long path. 

    var path = "/tmp/dir/file.txt";
    print( Cla.path.basename(path) ); // prints file.txt


### Cla.path.dirname(path)

Extracts the directory part of the path.

    var path = "/tmp/dir/file.txt";
    print( Cla.path.dirname(path) ); // prints /tmp/dir


### Cla.path.extname(path)

Extracts the file extension from a path.

    var path = "/tmp/dir/file.txt";
    print( Cla.path.extname(path) ); // prints txt

### Cla.path.join(path)

Concatenates a long path into its parts.

    var path1 = "/tmp";
    var path2 = "dad";
    print( Cla.path.join(path1,path2,"file.txt") ); // prints /tmp/dad/file.txt


