---
title: Grid editor
index: 5000
icon: fieldlet-grid-editor
---

Allows to introduce a grid in the form with a column for a description.

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

### Columns

Set the columns and the format table.

Names of columns should be separated by ;

After name of column, we need to set the column type:

Example:

    Sub-task,textfield,250;Status,combo_dbl,,New,New#In progress#Done;Date,datefield

In this example we set three columns. First one is a text column called Sub-task, limited to 250 characters.

The second column call Status, is a combobox (type combo_dbl) with a value (New) as default option but with two more options you can set in the combo.

The last one, Date, is a date field which allows you to choose from a calendar a date.


			 Sub-Task  |    Status    |    Date
           ----------------------------------------
            <textarea> | <combo-box>  | <datefield>