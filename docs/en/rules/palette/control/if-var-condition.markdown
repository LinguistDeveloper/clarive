---
title: IF var condition THEN
icon: if
---

Allow to use multiples values in a conditional step.

To configure it, we have some combos to customize our conditions:

### When

Specify when the IF step is TRUE and can run the elements inside the IF service:

- **Any** - At least condition is true, same like an OR (x OR y OR z).
- **All** - All conditions should be true to make the IF flow. Same like an AND (x AND y AND z).
- **None** - None of the conditions are true. Same as !(x AND y AND z).

### Condition

Set the IF condition:

- **Stash Variable** - Fill with the variable to be compared.
- **Operator** - Set the type of comparison.

In some cases (like 'EQUALS'), we need to configure to more options:

- **Ignore case** - To ignore case type (uppercase or lowercase) in the comparison.
- **Numeric** - Compare values as a numeric type or string type.
- **Value** - Fill the value which will be compared with the Stash Variable field.

**Remove** - Remove the condition.

**Add Condition** - Allow to add a new condition.