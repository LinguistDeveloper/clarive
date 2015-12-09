---
title: User Administration
---


* Clarive users are stored directly in the database. Even if 
external authentication is used, users must be created in the 
Clarive database for login to work.

* User administration can be performed by selecting Admin-Users from the menu bar. 
This will display all the currently available Users in a list view.

* The list view contains the following columns: <br />

&nbsp; &nbsp;• `Avatar`: The user's avatar <br />
&nbsp; &nbsp;• `User`: Userid of the user, used for login into the system <br />
&nbsp; &nbsp;• `Name`: Full name of the user <br />
&nbsp; &nbsp;• `Alias`: Alias for the userid <br />
&nbsp; &nbsp;• `Language`: The selected user language <br />
&nbsp; &nbsp;• `Email`: Email address of the User <br />
&nbsp; &nbsp;• `Phone`: Phone number of the user 


<br />
### <img src="/static/images/icons/add.gif" /> Creating a User

* The following information needs to be provided for creation: <br />

&nbsp; &nbsp;• `User`: The Userid the user will use to logon to Clarive Software <br />
&nbsp; &nbsp;• `Password`: The password the user will use in combination with the userid to logon to Clarive <br />
&nbsp; &nbsp;• `Confirm Password`: The password the user will use in combination with the userid to logon to Clarive <br />
&nbsp; &nbsp;• `Alias`: An Alias for a User <br />
&nbsp; &nbsp;• `Name`: Full name of the User <br />
&nbsp; &nbsp;• `Phone`: Phone number of the User <br />
&nbsp; &nbsp;• `Email`: Email Address of the Use.


* You must save the entered data before assigning Roles and Projects. 

* Under these fields, the Roles defined in the database are displayed on the left, and the available 
[scopes](concepts/scope) this user might get a role for are displayed on the right.

**IMPORTANT NOTE**: Assigning Roles is only available to saved users. 
So save first before adding roles to a user.

* To add a Role or multiple roles for a user, mark the checkbox(es) 
next to the role in the left panel, in the right pane select either ALL project, or 
one or multiple Clarive projects by marking the checkbox next all or next to one or more Clarive scopes. 
Click on the bottom left button  to add the project related roles for that user.

* In the bottom window the roles assigned to that user for the scopes selected.

* To Unassign roles/projects from a User, there are several options.

* A few examples: <br />

&nbsp; &nbsp;1. To unassign the Role “Developer” for all Clarive Projects from the user, mark the row and click on <img src="/static/images/icons/delete_red.png" /> <br />
&nbsp; &nbsp;2. To unassign the Role “Developer” from the Clarive Project “ClientApp”  from  the user, mark the ckeckbox next to “Developer” in the left pane, mark the checkbox next to “ClientApp” in the right pane and click on  <img src="/static/images/icons/key_delete.png" /> <br />
&nbsp; &nbsp;3. To unassign all Roles for the Clarive Project “ClientApp” from  a user, mark the checkbox next to “ClientApp” in the right pane, click on <img src="/static/images/icons/key_delete.png" /> <br />
&nbsp; &nbsp;4. To unassign all Roles from  a user, click on <img src="/static/images/icons/del_all.png" /> 

<br />
### <img src="/static/images/icons/edit.gif" /> Editing a User
* Allows the Administrator can modify existing data of the selected user.

<br />
### <img src="/static/images/icons/delete_.png" /> Deleting a User

* The selected user will be deleted. The system will provide a confirmation message before deleting the user.

<br />
### <img src="/static/images/icons/copy.gif" /> Duplicating a User

* Allows duplication of the selected user. A new User is created with the same values as the original. 

<br />
### <img src="/static/images/icons/prefs.png" /> User Preferences

* The administrator can change user preferences, such as language or avatar by selecting a user and clicking on the Preferences button.

<br />
### <img src="/static/images/icons/surrogate.png" /> Surrogate

* The administrator can take the user profile


<br />
### <img src="/static/images/icons/envelope.png" /> Inbox
* Allows access to the user mailbox.


<br />
### <img src = "/static/images/icons/about.png" alt='Licensing' /> Licensing

* Clarive is generally licensed on a named-user base, except for ELA (Enterprise Level Agreements) licenses. 
* Creating new users will usually consume one of such licenses, except in the case the user is **inactive**. 
* Check your license file for details on your user limits. 


