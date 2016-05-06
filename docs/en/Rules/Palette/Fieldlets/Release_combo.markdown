---
title: Release combo
index: 400
icon: combo_box
---
* Allows to introduce a combo box with the releases availables in the form.
* There are a list of elements can be configured in the fieldlet:


### Section to view
* Indicates in which part of the view position the fieldlet.


### Row width
* Allows to personalize the anchor of the fieldlet.


### Hidden from view mode
* Indicates if the field will be hidden from the view mode.


### Hidden from edit mode
* Indicates if the field will be hidden from the edit mode.


### Mandatory field
* Check if you want the field as mandatory.


### Type
* The type of the field is **Single** by default. It allows to select one choice of the options available.


### Display field
* Set the field to show.


### Advanced filter JSON
* Allows to use a JSON format to add a condition.
* For example, to show only a category user can use the filter:


        {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25}


&nbsp;&nbsp;• Where id is the unique key of the category which can be consulted through the REPL.


### Release field
* It establishes dependence between this Release topics type and dependent topics.
* It is through this field which should be completed by the ID field in the form of the dependent topics.