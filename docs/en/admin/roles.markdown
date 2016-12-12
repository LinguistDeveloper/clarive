---
title: Role Administration
index: 5000
icon: role
---

Security within Clarive is handled thru a [role system](concepts/roles).

All access to administrator functions and user functions are defined through roles.
Users get then one ore more roles, that way the user’s access to Clarive is limited and controlled.

**Example**

An "administrator" role can be defined and all privileges can be set on administrator functionality within
the tool like report definition, topic administration, etc. A role "incident manager" can be defined with
full access to the topic category "Incident" but e.g. no access to topic category "release" because this topic
category will be managed by the role "Release manager".

A user will get one of more roles and inherit that way the access to the topics he can work on.

Role administration can be performed by selecting Admin - <img src="/static/images/icons/role.svg" /> Roles from the menu bar.
This will display all the currently available roles in a list view.

The list view contains the following columns:

- `Role` - The name of the Role
- `Description` - The description of the role
- `Mailbox` - The mailbox specific for the role, for notification purposes
- `Options` - Summary of all Role actions for this Role


## Role List Options


## <img src="/static/images/icons/add.svg" /> Creating a new Role

The following information needs to be provided for creation:

- **Role Name** - The name of the role e.g. developer, release manager, change manager
- **Description** - A longer description of the Role
- **Dashboard** - Clarive has several Dashboards, combining relevant reports, related to the roles.

The dashboards combo box is the list of dashboards that are available for users with that role. The first one (in order) will be the default one. The user can also select his default dashboard in his preferences (user menu on top right corner).


### Available Actions

All available actions are displayed in the left panel, Actions attributed to the role
are displayed in the left pane. A Group of actions or a specific action can be added by
selecting and dragging the action of group from the left pane to the right pane.

- `Remove Selection` <img src="/static/images/icons/delete-grid-row.svg" /> - Removes the currently selected action from the Role.
- `Remove All` <img src="/static/images/icons/delete-grid-all-rows.svg" /> - Removes all selections.


## Users that Have a Role

Select the`Users` tab to see the users that have the current role and in
what [scope](concepts/scope) they have the role assigned to.


## Scopes Where The Role is Assigned

This a pivoted version of the User list. Now you see what users have the
current rol.


 The permit also gives permission to administer see CIs so it is not necessary to add the two. To specify the CIs, you have to drag the action. In the new window, select the roles and collections that the user can view / manage. You can also add negative filters. For example, if the user can see all CIs least the project collection, you can add all roles and then a negative filter to the collection.

## Actions

Actions are logically grouped, actions can be added related to the following groups:

- `admin` - All actions related to the tool administration e.g. topic administration, user administration
- `artifacts` - All action related to Artifacts
- `calendar` - All actions related to Job Calendars
- `ci` - All actions related to configuration items.You can give permission to manage or view CIs. The action Admin CIs also give permission to view CIs so it is not neccesary to add both. To specify the CIs, you have to drag the action. In the new window, select the roles and collections that the user can view/manage. You can also add negative filters. For example, if the user can see all CIs except the project collection, you can add all roles and then add a negative filter to that collection.
- `development` - All actions related to the Development menu on the top bar of the tool.
- `git` - All actions for accessing the Git Repository
- `help` - Actions related to the Help menu
- `home` - Actions allowing to view Lifecycle panel or to the menu
- `job` - All actions related to jobs e.g. creating new jobs, restart jobs....
- `labels` - Action allowing to administer labels
- `notify` - Actions allowing the role to receive general admin and notification messages
- `projects` - Action allowing to access the Project Lifecycle
- `reports` - Actions allowing to view dynamics fields and reports
- `search` - Actions allowing to search for Jobs, Ci’s and topics
- `topics` - It allows the user to view topics, delete topics, create a topic, add comments to the topics, etc... Once the action is drawn, you can filter so the user can only apply that action for given categories.
- `topicfields` - It allows you to configure the actions to see and/or edit the fields of the topics. It is possible to configure each field depending on the category and the status of the topic. Just add the category, status and the field so the user can interact with it. It is also possible negative filters, for example, provide a user permission to view all fields of a category minus the 'Estimate' field. To do this, assigned permissions to see all the fields in that category and add a negative filter to the 'Estimate' field.

For each field of each topic in any status, this action has to be added for those role that need to edit this field.

### <img src="/static/images/icons/edit.svg" /> Edit the selected Role

Allows editing the selected Role. Once changes have been made, select the “Accept”. To avoid
any changes, select the “Close” button instead.

### <img src="/static/images/icons/copy.svg" /> Duplicate the selected Role

Allows duplication of the selected Role. A new Role is created with the same values as the
original Role. Its initial name will be the name of the original Role with a number concatenated.


### <img src="/static/images/icons/delete.svg" /> Delete the selected Role

The selected role will be deleted. The system will provide a confirmation message before actually
deleting the Role. If Users exist with that role, the role will be removed from the user.

Also, list search is available to look for roles by rol or description.
