---
title: List topics
index: 400
icon: report_default
---
* Lists the selected topics and their status in a ordered list.
* There are a list of elements can be configured in the dashlet:


### Dimensions of the dashlet
* Can personalize the size of the dashlet modifying the number of columns and rows.

### Autorefresh
* Allows to make the dashlet more dinamic adding an automatic refresh (in minutes).


###  List of fields to view in grid
* Allows to select specific fields to view. By default, dashlet shows; ID, title, status, created_by and created_on.

This columns can be modify, separating fields (columns) with **;**.

* A example to use this field could be:
    `ID_fieldlet`,`column_name`,`type`,`width`;

Where:

   `ID_fieldlet`: Specify the ID_name of the fieldlet.

   `column_name`: Name of the dashlet column.

   `type`: Type of field to show. Can be *text*, *number*, *checkbox* or *ci*.

   `width`: Set the anchor of the column.

* In addition, if we user a number type, we can personalize it setting up the number of decimals we want to show, to make it, just add the number of decimas in parenthesis after type.

* Also we can use other properties for numbers like `total`. With this property, user can see:

   `sum`: Shows sum of all the values contains in the column.

   `max` : Shows maximum value of all the values contains in the column.

   `min` : Shows minium value of all the values contains in the column.

   `count` : Shows number of rows.

* Other of the properties for this `type number` are:

`currency`: Indicates that we are showing currency, changes the way to show decimals, using US format (. for decimals) or standard format (, for decimals). This format is predefined by user preferences.

`symbol`: Show type of currency;€, $, etc...  

		Example: title,Title;created_by, Created By;incoming,My incoming,number(2),,sum,currency,€;

In this example, users can see in the daslet, a table with the following columns:

            Title  | Created by  | My incoming
            --------------------------------
            Title1 | 2016-02-02  | 23,25 €



### Maximum number of topics to list
* Set the maximum number of topics.

### Sort by
* Set an order by a determinated field.

### Sort order
* Indicate ASC or DESC order.

### Show totals row?
Include a last row showing total if we have a number type in the table.

### Select topics in categories
* Select one o more categories to show in the grid.

### Select topics in statuses
* Select one o more status to configure the table.

### User assigned to topics
* Allow to filter the topics by user assigned.

### Advanced condition JSON/MongoDB
* Allows to use a JSON format o MongoDB query to add a condition.
