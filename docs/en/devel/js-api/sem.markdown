---
title: cla/sem - semaphore control
---

This namespace contains 
functions that allow the developer to 
use semaphores in their code. 

#### sem.take(key,code)

Takes a semaphore to execute the code block
passed as an argument. 

```javascript
var sem = require("cla/sem");
var ret = sem.take('abc', function(){
    cla.sleep(0.05);
    print( 111 );
    return 123;
});
print( ret );
```

Take consumes 1 semaphore slot. This typically 
means that no other process can take the same semaphore, unless
an administrator has increased the semaphore slot availability, 
in which case more process can be taken. 

The semaphore slot is released at the end.

#### sem.purge(key)

Purges all semaphores that are blocked for the 
given key, releasing all processes that are waiting 
for a given semaphore simultaneously. 

This function is useful to unlock system resources that
were blocked and were not released. 
