---
title: cla/path - Path manipulation
icon: page
---

These utilities are useful for manipulating 
how paths names are broken down and reassembled 
together, and can come in handy for calculating 
relative paths.

### path.basename(path)

Extracts the file name and extension part from 
a long path. 

```javascript
var path = require("cla/path");
var filepath = "/tmp/dir/file.txt";
print( path.basename(filepath) ); // prints file.txt
```

### path.dirname(path)

Extracts the directory part of the path.

```javascript
var path = require("cla/path");
var filepath = "/tmp/dir/file.txt";
print( path.dirname(filepath) ); // prints /tmp/dir
```

### path.extname(path)

Extracts the file extension from a path.

```javascript
var path = require("cla/path");
var filepath = "/tmp/dir/file.txt";
print( path.extname(filepath) ); // prints txt
```

### path.join(path)

Concatenates a long path into its parts.

```javascript
var path = require("cla/path");
var path1 = "/tmp";
var path2 = "dad";
print( path.join(path1,path2,"file.txt") ); // prints /tmp/dad/file.txt
```


