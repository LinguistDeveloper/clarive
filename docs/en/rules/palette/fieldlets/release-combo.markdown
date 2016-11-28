---
title: Release combo
index: 5000
icon: combo-box
---

Allows to introduce a combo box with the releases availables in the form.

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

### Select topics in categories

Select one o more categories of type Release to show.

### Select topics in statuses

Select one o more status to configure the table.

### Exclude the statuses selected

Exclude the statuses selected and shows the remainder are **not** selected.

### Type

Allow to set the type of the field.

- **Single** - Allows to select one choice of the options available.
- **Multiple** - The user can select multiples choices.
- **Grid** - The added topics are shown in a table.

### Display field

Set the field to show.

### Advanced filter JSON

Allows to use a JSON format to add a condition.

For example, to show only a category user can use the filter:

    {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25}

Where *id* is the unique key of the category which can be consulted through the REPL.

### Release field

It establishes dependence between this Release topics type and dependent topics.

It is through this field which should be completed by the ID field in the form of the dependent topics.

### Filter field

Specify a condition to the release combo.

This is a combo with every fieldlets that are in the form.

This field is required if next field is not empty.

### Filter data

Specify a condition to the data.

This field is required if previous field is not empty.

### Filter type

Specify the logic of the filter.

By default, filter type is OR.

For more information, there is a how-to called [Filters in fieldlets](how-to/filter-fieldlet).
