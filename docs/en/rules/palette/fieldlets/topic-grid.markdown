---
title: Topic grid
index: 400
icon: grid
---

Allows to add topics into a grid to the form.

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

 Select one o more categories to show in the grid.

### Select topics in statuses

 Select one o more status to configure the table.

### Exclude selected statuses

Check if you want to exclude the statuses selected.

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

For example, to show only a category user can use the filter:

    {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25}

Where id is the unique key of the category which can be consulted through the REPL.

### List of columns to show in grid

Select the columns to show in the grid.

Default columns displayed are the topic name (shows the category and ID) and title of the topic.

To customize the table, first indicate the data of the column and subsequently the column name for example:

    name;title;Projects.project_name_list,Projects;name_status,Status;Assign.user_name,Assign,ci;priority,Priority;complex,Complex

**Name**

Displays the number of topic in a column called ID.

**Title**

Displays the title of the topic in a column called Title.

**Projects**

Displays the name of the projects through the variable:  *_project_name_list*.

**State**

Displays the name of the state.

**Assigned**

Displays the user name assigned to the topic.

**Priority**

Displays the priority of the topic.

**Complexity**

Sample complexity.

Only works if Grid is set in the type of field.

### Height of grid in edit mode

Specify the height of the field when the form is in edit mode

Only works if Grid is set in the type of field.

### Page size

Defines the number of elements will appear.

Only works if Grid is set in the type of field.

### Parent field

Select the parent field of the topics

### Grid page size

Select the size of the grid.

Only works if Grid is set in the type of field.

### Show grid controls?

Allows the user to configured when the grid controls will appear. The options are:

- **Only if paging**

- **Always**

- **Never**

Only works if Grid is set in the type of field.

### Sort by

 Set an order by a determinated field. For example by Title.

### Sort order

 Indicate ASC or DESC order.
