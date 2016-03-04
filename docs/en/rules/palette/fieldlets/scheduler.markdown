---
title: Schedule
index: 400
icon: clock
---

Allows to introduce a schedule in the form.

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

Set the columns to show in the schedule

The first literal indicate de name of the column and the second the type. The separator between columns are ;

    init_date,datefield; end_date, datefield; notes, text;

Types availables

**Datefield**

Introduced a calendar into the column to put a date.

**Textfield**

Put a text field into the column (one text row).

**Text**

Put a text field into the column for example for descriptions or observations (three text rows ).

    init_date,datefield; end_date, datefield; project, text;

