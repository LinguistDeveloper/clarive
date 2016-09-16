---
title: cla/log - Logging Classes
index: 5000
icon: page
---

Logging is useful to correctly print and report messages to 
the common Clarive log system. 

Also, when used in job context, logging automatically 
reports log messages to both the log file and the job log during job execution. 

### Common behaviour

All logging functions have common argument behaviour.

The first argument is either a message string or an object to be dumped. 
The second argument can either be an object to be dumped or a file with contents
to be downloaded, in case of a job log. 

### log.info(msg, args)

An informational message. 

```javascript
var log = require('cla/log');
log.info("This is plain information", { foo: 123 }); 
```

### log.debug(msg, args)

A lower level informational message. 

```javascript
var log = require('cla/log');
log.debug("This is plain information", { foo: 123 }); 
```

### log.warn(msg, args)

A warning message. 

```javascript
var log = require('cla/log');
log.warn("A warning"); 
```

### log.error(msg, args)

Error message.

```javascript
var log = require('cla/log');
log.error("An error"); 
```

### log.fatal(msg, args)

Error message that also raises an exception.

