---
title: CI combo
index: 5000
icon: fieldlet-system-cis
---

Allows to introduce a combo box with CIs in the form.

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

- **Single** - Allows to select one choice of the options available.
- **Multiple** - The user can select multiples choices.
- **Grid** - The added topics are shown in a table.


### Display field

Set the field to show.


### Advanced filter JSON

Allows to use a JSON format to add a condition.


        {"name":"Project_name"}
        {"moniker":"Moniker_of_the_project"}


Selectable fields to filter can be found through the REPL. In this case the command would be: `CI> project-> find_one ();`

### Selection method

You specify the values that appear in the form. Two types to choose from:

- **Role selection** - Select the role to be displayed on the form, 
regardless of class. For example, if we choose Agent, in the form we will see all
 Agents, *ftp_agent*, *clax_agent*, etc...
- **Class selection** - We can specify class of CI.

### Default value

To show a default value in the box.

### Filter field

Specify a condition to the CI combo.

This is a combo with every fieldlets that are in the form.

This field is required if next field is not empty.

### Filter data

Specify a condition to the data.

This field is required if previous field is not empty.

### Filter type

Specify the logic of the filter.

By default, filter type is OR.

For more information, there is a how-to called [Filters in fieldlets](how-to/filter-fieldlet).


### Description

Selection of type of description to show in the list.

- **Name** - Show the name.
- **Environment** - Show the Environment separated by commas.
- **Class** - Show the type object.
- **Moniker** - Show the moniker specified in CI configuration.
