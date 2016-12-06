---
title: WHILE condition
icon: loop.gif
---

The WHILE control operation iterates a code block while the condition indicated is true.

A WHILE block checks if the condition is true first, then executes the code. If you need the opposite, first the code,
then check the condition, take a look at [DO-UNTIL](rules/palette/control/do-until).

To configure the WHILE control operation, the following values must be configured:

* `Stash Variable` - the name of the variable that the condition will be checked against.
* `Operator` - the condition comparison operator.
* `Options` - gives the ability to set options for some of the operators.
* `Value` - the value to be compared against.

### Operators

The following comparison operators are available:

- `IS TRUE` and `IS FALSE` - evaluates the stash variable for true and false. A value of undefined, zero (0) or blank ('').
- `IS EMPTY` - evaluates the stash variable for emptyness. An empty value, and empty array or an empty hash will be considered true.
- `EQUAL` - compares two strings or numbers for equality.
- `LESS THAN`, `LESS THAN EQUALS`, `GREATER THAN`, `GREATER THAN EQUALS` - compares either numbers or strings.
- `LIKE` - compares a stash value against a regular expression (ie `he..o world$`) in the `Value` field.
- `IN` - compares if the stash value (a single value) is in a list (an array) in the `Value` field. This is only useful
  if the value field contains a variable that will resolve to an array.
- `HAS` - compares if the list (array) in the stash value contains the item in the `Value` field. This is only useful if
  the stash value resolves to an array.

### Options

The following options are only available for certain comparison operators.

- `Ignore Case` - ignore uppercase and lowercase differences in string comparisons.
- `Numeric` - do the comparison in numeric context.

