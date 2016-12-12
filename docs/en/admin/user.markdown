---
title: User Administration
index: 5000
icon: user
---

Clarive users are stored directly in the database. Even if
external authentication is used, users must be created in the
Clarive database for login to work.

User administration can be performed by selecting Admin-Users from the menu bar.
This will display all the currently available Users in a list view.

The list view contains the following columns:

- `Avatar` - The user's avatar.
- `User` - Userid of the user, used for login into the system.
- `Name` - Full name of the user.
- `Alias` - Alias for the userid.
- `Language` - The selected user language.
- `Email` - Email address of the user.
- `Phone` - Phone number of the user.

### <img src="/static/images/icons/add.svg" /> Creating a User

- `User` - The User id the user will use to logon to Clarive Software.
- `Account type` - Set the type of account. Two types:
   * Regular - For all users, they can use Clarive with all their functionalities.
   * System - Users that cannot login or surrogate but can be used in rules. These users are not counted for the user limit per license.
- `Password` - The password the user will use in combination with the userid to logon to Clarive.
- `Confirm Password` - The password the user will use in combination with the userid to logon to Clarive.
- `Alias` - An Alias for a user.
- `Name` - Full name of the user.
- `Phone` - Phone number of the user.
- `Email` - Email Address of the user.

You must save the entered data before assigning Roles and Projects.

Under these fields, the Roles defined in the database are displayed on the left, and the available
[scopes](concepts/scope) this user might get a role for are displayed on the right.

**IMPORTANT NOTE**: Assigning Roles is only available to saved users.
So save first before adding roles to a user.

To add a Role or multiple roles for a user, mark the checkbox(es)
next to the role in the left panel, in the right pane select either ALL project, or
one or multiple Clarive projects by marking the checkbox next all or next to one or more Clarive scopes.
Click on the bottom left button  to add the project related roles for that user.

In the bottom window the roles assigned to that user for the scopes selected.

To Unassign roles/projects from a User, there are several options.

A few examples:

- To unassign the Role “Developer” for all Clarive Projects from the user, mark the row and click on <img src="/static/images/icons/delete_red.svg" />
- To unassign the Role “Developer” from the Clarive Project “ClientApp”  from  the user, mark the ckeckbox next to “Developer” in the left pane, mark the checkbox next to “ClientApp” in the right pane and click on  <img src="/static/images/icons/key_delete.svg" />
- To unassign all Roles for the Clarive Project “ClientApp” from  a user, mark the checkbox next to “ClientApp” in the right pane, click on <img src="/static/images/icons/key_delete.svg" />
- To unassign all Roles from  a user, click on <img src="/static/images/icons/del_all.svg" />

### <img src="/static/images/icons/edit.svg" /> Editing a User

Allows the Administrator can modify existing data of the selected user.


### <img src="/static/images/icons/delete.svg" /> Deleting a User

The selected user will be deleted. The system will provide a confirmation message before deleting the user.

### <img src="/static/images/icons/copy.svg" /> Duplicating a User

Allows duplication of the selected user. A new User is created with the same values as the original.

### <img src="/static/images/icons/prefs.svg" /> User Preferences

The administrator can change user preferences, such as language or avatar by selecting a user and clicking on the Preferences button.

### <img src="/static/images/icons/surrogate.svg" /> Surrogate

The administrator can take the user profile

### <img src="/static/images/icons/envelope.svg" /> Inbox

Allows access to the user mailbox.

### <img src = "/static/images/icons/about.svg" alt='Licensing' /> Licensing

Clarive is generally licensed on a named-user base, except for ELA (Enterprise Level Agreements) licenses.

Creating new users will usually consume one of such licenses, except in the case the user is **inactive**.

Check your license file for details on your user limits.

