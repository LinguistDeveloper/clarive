---
title: Project combo
index: 400
icon: combo_box
---

Allows to introduce a combo box with the projects in the form.

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

        {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25}

- Where id is the unique key of the category which can be consulted through the REPL.

### CI Class

Specify the class of CI to be shown. Tipically the CI Class to use in this fieldlet is *project*.

### Default value

To show a default project in the box.

### Roles

Selection of roles to show in the grid.

### Description

Selection of type of description to show in the list.

* Name: Show the name.
* Environment: Show the Environment separated by commas.
* Class: Show the type object.
* Moniker: Show the moniker specified in CI configuration.