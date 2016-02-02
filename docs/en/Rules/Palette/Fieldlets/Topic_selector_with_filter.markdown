---
title: Topic selector with filter
index: 400
icon: combo_box
---
    
<br />

* Allows to add topics to the form.

* There are a list of elements can be configured in the fieldlet:

<br />
### Section to view
* Indicates in which part of the view position the fieldlet.

<br />
### Row width
* Allows to personalize the anchor of the fieldlet.

<br />
### Hidden from view mode
* Indicates if the field will be hidden from the view mode.

<br />
### Hidden from edit mode
* Indicates if the field will be hidden from the edit mode.

<br />
### Mandatory field
* Check if you want the field as mandatory.

<br />
### Type
* Allow to set the type of the field.

&nbsp; &nbsp;• **Single** - Allows to select one choice of the options available. <br />

&nbsp; &nbsp;• **Multiple** - The user can select multiples choices. <br />

&nbsp; &nbsp;• **Grid** - The added topics are shown in a table.


<br />
### Display field
* Set the field to show.

<br />
### Advanced filter JSON
* Allows to use a JSON format to add a condition. 

* For example, to show only a category user can use the filter:

            
        {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25} 


&nbsp;&nbsp;• Where id is the unique key of the category which can be consulted through the REPL.

<br />
### List of columns to show in grid
* Select the columns to show in the grid.

<br />
### Page size
* Defines the number of elements will appear.

&nbsp;&nbsp; *Note - Only works if Grid is set in the type of field.*

<br />
### Parent field
* Select the parent field of the topics.

<br /> 
### Filter field
* Specify a condition to the topic selector


<br />
### Filter data
* Specify a condition to the data.

<br />
### Table format

&nbsp; &nbsp;• **Always** <br />

&nbsp; &nbsp;• **Never** <br />

&nbsp;&nbsp; *Note - Only works if Grid is set in the type of field.*
