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

The type of the field is **Grid** by default. It means that the added topics are shown in a table.

### Display field

Set the field to show.

### Advanced filter JSON

Allows to use a JSON format to add a condition.


        {"name":"Project_name"}
        {"moniker":"Moniker_of_the_project"}


* Selectable fields to filter can be found through the REPL. In this case the command would be: `CI> project-> find_one ();`


### Selection method

Choose between selections.

- **Role selection**

- **Class selection**

### Roles

Selection of roles to show in the grid.

Select only works if *Class selection* is selected as a method.

Specify the class of CI to be shown.


### Show class
If Class selection is selected, the value in this field must be ci.

### CI Class

Select only works if *Class selection* is selected as a method.

Specify the class of CI to be shown.

### Default Value

To show a default value in the grid.

This field will be active when CI Class is selected.

### Filter field

Specify a condition to the CI grid.

This is a combo with every fieldlets that are in the form. 

This field is required if next field is not empty.

### Filter data

Specify a condition to the data.

This field is required if previous field is not empty.

### Filter type

Specify the logic of the filter.

By default, filter type is OR.

For more information, there is a how-to called [Filters in fieldlets](how-to/filter-fieldlet).

### Show class
