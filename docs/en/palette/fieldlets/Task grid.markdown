---
title: Task grid
index: 400
icon: grid
---

    
<br />

* Allows to add a tasks in the form.

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
* Allow to set the type of the field.<br />

&nbsp; &nbsp;• **Single** - Allows to select one choice of the options available. <br />

&nbsp; &nbsp;• **Multiple** - The user can select multiples choices. <br />

&nbsp; &nbsp;• **Grid** - The added tasks are shown in a table.

<br />
### Display field
* Set the field to show.

<br />
### Advanced filter JSON
* Allows to use a JSON format to add a condition. 

* For example, to show only a category user can use the filter:

            
        {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25} 


&nbsp;&nbsp;• Where id is the unique key of the category which can be consulted through the REPL.
