---
title: User Administration
---

Clarive users are stored directly in the database. Even if 
external authentication is used, users must be created in the 
Clarive database for login to work.

User administration can be performed by selecting Admin-Users from the menu bar. 
This will display all the currently available Users in a list view.

The list view contains the following columns:

- `Avatar`: The user's avatar
- `User`: Userid of the user, used for login into the system
- `Name`: Full name of the user
- `Alias`: Alias for the userid
- `Language`: The selected user language
- `Email`: Email address of the User
- `Phone`: Phone number of the user

## Creating a User

The following information needs to be provided for creation :

- `User`: The Userid the user will use to logon to Clarive Software
- `Password`: The password the user will use in combination with the userid to logon to Clarive
- `Confirm Password`: The password the user will use in combination with the userid to logon to Clarive
- `Alias`: An Alias for a User
- `Name`: Full name of the User
- `Language`: Future use
- `Phone`: Phone number of the User
- `Email`: Email Address of the Use

You must save the entered data before assigning Roles and Projects. 

Under these fields, the Roles defined in the database are displayed on the left, and the available 
[scopes](concepts/scope) this user might get a role for are displayed on the right.

**IMPORTANT NOTE**: Assigning Roles is only available to saved users. 
So save first before adding roles to a user.

To add a Role or multiple roles for a user, mark the checkbox(es) 
next to the role in the left pane, in the right pane select either ALL project, or 
one or multiple Clarive projects by marking the checkbox next all or next to one or more Clarive scopes. 
Click on the bottom left button   to add the project related roles for that user.

In the bottom window the roles assigned to that user for the scopes selected.

To Unassign roles/projects from a User, there are several options.

A few examples : 

1. To unassign the Role “Developer” for all Clarive Projects from the user, mark the checkbox next to “Developer“ and click on   
2. To Unassign the Role “Developer” from the Clarive Project “ClientApp”  from 
the user, mark the ckeckbox next to “Developer” in the left pane, mark the checkbox next to “ClientApp” in the right pane and click on  
3. To unassign all Roles for the Clarive Project “ClientApp” from  a user, 
mark the checkbox next to “ClientApp” in the right pane, click on  

## Duplicating a User

In the bottom window the roles assigned to that user for the Clarive Projects selected is shown

To Unassign roles/projects from a User, there are several options.

A few examples : 

1. To unassign the Role “Developer” for all Clarive Projects from the user, 
mark the checkbox next to “Developer“ and click on   
2. To Unassign the Role “Developer” from the Clarive Project “ClientApp”  from the user, 
mark the ckeckbox next to “Developer” in the left pane, mark the checkbox 
next to “ClientApp” in the right pane and click on  
3. To unassign all Roles for the Clarive Project “ClientApp” from  a user, mark the checkbox next to “ClientApp” in the right pane, click on  

## User Preferences

The administrator can change user preferences, such as language or 
avatar by selecting a user and clicking on the Preferences button.

## Licensing

Clarive is generally licensed on a named-user base, except for ELA (Enterprise
Level Agreements) licenses. 
Creating new users will usually consume one of such licenses, except in
the case the user is **inactive**. 

Check your license file for details on your user limits. 


