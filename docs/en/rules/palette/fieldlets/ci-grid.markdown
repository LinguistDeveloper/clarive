---
title: CI Grid
index: 400
icon: grid
---

Allows to introduce a CI grid in the form.

There are a list of elements can be configured in the fieldlet:

### Section to view

Indicates in which part of the view position the fieldlet.

### Row width

Allows to personalize the anchor of the fieldlet.

### Hidden from view mode

Indicates if the field will be hidden from the view mode.

### Hidden from edit mode

Indicates if the field will be hidden from the edit mode.

### Mandatory field

Check if you want the field as mandatory.

### Type

Allow to set the type of the field.

**Single**

Allows to select one choice of the options available.

**Multiple**

The user can select multiples choices.

**Grid**

The added topics are shown in a table.

### Display field

Set the field to show.

### Advanced filter JSON

Allows to use a JSON format to add a condition.

For example, in this filter, only show one project to choose:
        {"name":"Project_name"}
        {"moniker":"Project_moniker"}

- Selectable fields to filter can be found through the REPL. In this case the command would be: `CI> project-> find_one ();`

### Selection method

Choose between selections.

- **Role selection*

- **Class selection**

### Roles

Selection of roles to show in the grid.

If Class selection is selected, the value in this field must be ci.

### CI Class

Select only works if *Class selection
is selected as a method.

Specify the class of CI to be shown.

### Show class
