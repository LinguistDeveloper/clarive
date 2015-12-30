---
title: Role Administration
icon: role
---

<br />

* Security within Clarive is handled thru a [role system](concepts/roles).

* All access to administrator functions and user functions are defined through roles. 
Users get then one ore more roles, that way the user’s access to Clarive is limited and controlled. 

* **E.g.**  An “administrator” role can be defined and all privileges can be set on administrator functionality within 
the tool like report definition, topic administration, etc... A role “incident manager” can be defined with 
full access to the topic category “Incident” but e.g. no access to topic category “release” because this topic 
category will be managed by the role “Release manager”.

* A user will get one of more roles and inherit that way the access to the topics he can work on.

* Role administration can be performed by selecting Admin-Roles from the menu bar. 
This will display all the currently available roles in a list view.

* The list view contains the following columns:  <br />


&nbsp; &nbsp;• `Role`: The name of the Role <br />

&nbsp; &nbsp;• `Description`: The description of the role <br />

&nbsp; &nbsp;• `Mailbox`: The mailbox specific for the role, for notification purposes <br />

&nbsp; &nbsp;• `Options`: Summary of all Role actions for this Role

<br />


## Role List Options
<br />

## <img src="/static/images/icons/add.gif" /> Creating a new Role

* The following information needs to be provided for creation:<br />


&nbsp; &nbsp;• **Role Name**: The name of the role e.g. developer, release manager, change manager  <br />

&nbsp; &nbsp;• **Description**: A longer description of the Role <br />

&nbsp; &nbsp;• **Dashboard**: Clarive has several Dashboards, combining relevant reports, related to the roles.  <br />

* The dashboards combo box is the list of dashboards that are available for users with that role. The first one (in order) will be the default one. The user can also select his default dashboard in his preferences (user menu on top right corner).

<br />
### Available Actions

* All available actions are displayed in the left panel, Actions attributed to the role 
are displayed in the left pane. A Group of actions or a specific action can be added by 
selecting and dragging the action of group from the left pane to the right pane.  <br />

 
 &nbsp; &nbsp;• `Remove Selection` <img src="/static/images/icons/delete_red.png" /> - Removes the currently selected action from the Role. </br>
 
 &nbsp; &nbsp;• `Remove All` <img src="/static/images/icons/del_all.png" /> - Removes all selections

<br />
## Users that Have a Role

* Select the`Users` tab to see the users that have the current role and in 
what [scope](concepts/scope) they have the role assigned to.

<br />
## Scopes Where The Role is Assigned

* This a pivoted version of the User list. Now you see what users have the 
current rol.

<br />
## Actions

* Actions are logically grouped, actions can be added related to the following groups :<br />


&nbsp; &nbsp;• `Admin`: All actions related to the tool administration e.g. topic administration, user administration <br />

&nbsp; &nbsp;• `Artifacts`: All action related to Artifacts <br />

&nbsp; &nbsp;• `Calendar`: All actions related to Job Calendars <br />

&nbsp; &nbsp;• `CI`: All actions related to configuration items. These actions are split in two groups, A group for administering the CI’s and a second group for Viewing the CI’s.  An example here is adding or viewing a status.<br />

&nbsp; &nbsp;• `Development`: All actions related to the Development menu on the top bar of the tool Git: All actions for accessing the Git Repository  <br />

&nbsp; &nbsp;• `Help`: Actions related to the Help menu <br />

&nbsp; &nbsp;• `Home`: <br />

&nbsp; &nbsp;• `Job`: All actions related to jobs e.g. creating new jobs, restart jobs.... <br />

&nbsp; &nbsp;• `Labels`: Action allowing to administer labels <br />

&nbsp; &nbsp;• `Notify`: Actions allowing the role to receive general admin and notification messages <br />

&nbsp; &nbsp;• `Projects`: Action allowing to access the Project Lifecycle <br />

&nbsp; &nbsp;• `Reports`: Actions allowing to view dynamics fields and reports <br />

&nbsp; &nbsp;• `Search`: Actions allowing to search for Jobs, Ci’s and topics <br />

&nbsp; &nbsp;• `SQA`: Actions allowing to access the quality portal <br />

&nbsp; &nbsp;• `Topics`: Actions on topics, For each topic in the database there is actions to, view, add, delete, edit the topic and to add/view comments to a topic. <br />

&nbsp; &nbsp;• `Topicfields`: For each field of a topic in a specific status, an action can be set to allowing the field to be edited by the role, or an action can be set to prohibit the role from viewing the field.  <br />

 &nbsp; &nbsp; *Note*: By default all fields of a topic in a specific status are READONLY. For ALL Fields that can be added when creating an instance of a topic or Fields that can  be changed when Editing an instance of a topic the action`: <br />

* For example, when adding the action “Can edit the field Changesets" in a category called "Change Request"
for the status "Deployed", the user with the role currently edited, will be able to edit 
and change the field “changeset” for the topic “Change Request”, 
when an instance of that topic has the status “Deployed”.

* For each field of each topic in any status, this action has to be added for those role that need to edit this field.
<br />

### <img src="/static/images/icons/edit.gif" /> Edit the selected Role

* Allows editing the selected Role. Once changes have been made, select the “Accept”. To avoid
any changes, select the “Close” button instead.

<br />
### <img src="/static/images/icons/copy.gif" /> Duplicate the selected Role

* Allows duplication of the selected Role. A new Role is created with the same values as the
original Role. Its initial name will be the name of the original Role with a number concatenated.

<br />
### <img src="/static/images/icons/delete_.png" /> Delete the selected Role

* The selected role will be deleted. The system will provide a confirmation message before actually
deleting the Role. If Users exist with that role, the role will be removed from the user.

<br />

* Also, list search is available to look for roles by rol or description. 
