---
title: cla/process - Process information
index: 5000
icon: page
---

The Clarive process extension points to let the user get some usefull information about the system and processes inside it.


### cla.pid()

Gets the process ID which is running the code.

```javascript
var proc = require("cla/process");
proc.pid();
```

### cla.title()

Gets the process Title which is running the code.

```javascript
var proc = require("cla/process");
proc.title();
```

### cla.arch()

Gets the system architecture.

```javascript
var proc = require("cla/process");
proc.arch();
```

### cla.os()

Gets the operating system.

```javascript
var proc = require("cla/process");
proc.os();
```

### cla.env()

Gets all the system environment variables and their values.

```javascript
var proc = require("cla/process");
proc.env();
```

You can also specify which environment variable value you want to know.

```javascript
var proc = require("cla/process");
proc.env('BASELINER_DEBUG');
```


### cla.argv()

Gets the vector of arguments that the process is using

```javascript
var proc = require("cla/process");
proc.argv();
```

### cla.args()

Gets the number of arguments that the process is using

```javascript
var proc = require("cla/process");
proc.args();
```

