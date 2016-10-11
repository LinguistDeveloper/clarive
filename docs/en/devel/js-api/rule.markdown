---
title: cla/rule - rule execution
---

This namespace contains functions 
that enables your code to interop with the 
rule system.

### rule.create(options,tree)

Creates a new rule from a rule tree.

The rule tree is an Array data structure with one or more operations (nodes) 
that conform its implemented logic. 

```javascript
var rule = require("cla/rule");
var ruleId = rule.create({ name: "myrule", type: "independent" }, [
    {
        attributes: {
            icon: "/static/images/icons/cog_perl.svg",
            key: "statement.code.server",
            name: "Server CODE",
            data: {
                lang: "js",
                code: "cla.stash('returning_value', 999)",
            },
        },
        children: []
    }
]);
```

### rule.run(rule,[stash])

Runs the rule identified by the argument
`rule`, which can be either a rule name or
id. 

The `stash` is an Object that can be created by the user
and sent to the rule. If no `stash` is set
the current program stash will be used. That's the 
one contained in `cla.stash()`.

The function returns the stash after the rule execution. 

Run with an empty stash:

```javascript
var rule = require("cla/rule");
var stash = rule.run('myrule', {});
```

Run with the current stash:

```javascript
var rule = require("cla/rule");
rule.run('myrule');
print( cla.stash("returning_value") );
```

