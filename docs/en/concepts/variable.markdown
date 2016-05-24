---
title: Variable
---

A variable in Clarive is a globally
defined CI belonging to the class Variable.

Each variable can hold values, like strings,
numbers, lists, hashes (dictionaries) and CIs.

Variables can be referenced in rules using
the notation `${variable-name}`.

When a rule runs, its [stash](concepts/stash)
is loaded with global variable default values.
Then, as the rule advances, either variable values
change or new variables are introduced to the stash.
