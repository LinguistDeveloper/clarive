---
title: Project combo
index: 400
icon: combo_box
---

    
<br />

* Allows to introduce a combo box with the projects in the form.

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
* Allow to set the type of the field. <br />

&nbsp; &nbsp;• **Single** - Allows to select one choice of the options available. <br />

&nbsp; &nbsp;• **Multiple** - The user can select multiples choices. <br />

&nbsp; &nbsp;• **Grid** - The added topics are shown in a table.


<br />
### Display field
* Set the field to show.

<br />
### Advanced filter JSON
* Allows to use a JSON format to add a condition.

            
        {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25} 


&nbsp;&nbsp;• Where id is the unique key of the category which can be consulted through the REPL.


<br />
### CI Class
* Specify the class of CI to be shown. Tipically the CI Class to use in this fieldlet is *project*.

<br />
### Default value
* To show a default project in the box. 

* The value indicated will be the ID of the CI.

<br />
### Roles
* Selection of roles to show in the grid.