---
title: Extending the JS system with modules
index: 2000
---

To extend the JS code we recommend 
using 2 strategies:

## Modules

User included modules should be stored in the filesystem, under 
the `CLARIVE_BASE/plugins/[plugin-name]/modules` folder.

To create the modules folder, we recommend 
creating a plugin first in your `CLARIVE_BASE` [location](install/directories)

```javascript
// create the file plugins/myplugin/modules/myutil.js:
(function(){
    return {
        doThis: function(num) {
            print("This is it: " + num);
        }
    }
}());

// now use it in your code
var myutils = require("myutil");
if( myutils ) {
    myutils.doThis(123);
} else {
    print( "could not find myutil" );
}
```

## Rules

Write an independent rule with common logic needed by other rules. 
Then invoke that rule as part of your code.

Write a rule with a JS CODE operation with the following content:

```javascript
var something = Cla.stash("something");
Cla.stash("myresults", something * 1000 );  

var stash = { something: 123 };
Cla.rule.run('my_rule_runner', stash);
print( "results=" + stash.myresults );  // you get 123000
```

Read more about `Cla.rule` [here](devel/js-api/rule)
