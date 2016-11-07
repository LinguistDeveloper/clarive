---
title: Create a report
index: 1
icon: report
---

Allow users to create a personalized topic grids. Users set the columns to show, categories and filters that makes possible to have in a topic grid the relevant information. This grid, can be configured with the following options:

### Creating a report ###

There are two ways:

The first way, is clicking on **Admin**->**Rules** and then, select the <img src="/static/images/icons/add.svg" /> Create
button.

In the next window there are the following options:

- **Name**: Assign a name to the report. This field is required.

- **Type**: Define the type of rule. In this case, we have to select report.

- **Compile Mode**

To create the report, click **Done** button.

By default, we will have three items in the rule:

- **Security**: We define the users that can see the report.

- **Meta**: Here, we can define the fields we want to see.

- **Data**: We treat the data.

The second way to create a report is:

Click on <img src="/static/images/icons/report.svg" />  in the **lifecycle panel**. Right click on  <img
src="/static/images/icons/magnifier.svg" /> **New search**.


#### Options ####

- **Name** - Set the report name.

- **Rows** - Set the number of rows per page in the grid.

- **Recursive level** - Ajust the depth of the relations between topics.

- **Permissions** - We can set the privacity of our report.
    - **Private**: Only the owner of the report can view it.

    - **Public**: Shows a combo box **Users and roles** where we can set who can see the report.


#### Query ###

In this tab we can select the setting of our report. At the left side we can see all categories and their fieldlets.

At the right side, the tree with added data into the report:

 - **Categories** - Drag and drop the category which we want to see in the report from left side to here.

 - **Fields** - Drag here the fieldlets we want to see in the report. Clicking in each field we can see some options:
     - Header: Set the title of the column.
     - Width: Set the width of the column.

 - **Filter** - In addition, we can filter data dragging the fieldlets here. Clicking on each fieldlet we can set some options, for example: 
    - String: We can filter a fieldlet by text.
    - CI: Can filter with some conditions like IN, NOT IN, etc.. in CI items
    - Date: Also we can filter data by date.

 - **Order**: Finally, we can set the default order to show the report. Drag a fieldlet here, and click on it. This will show a menu to set the order type: ASC or DESC.


To finish, just click on <img src="/static/images/icons/save.svg"/> Save.
