---
title: Category Administration
index: 5000
icon: topic
---

Categories administration is performed by selecting Categories from the menu bar. This will display all the
currently available topics in a list view:

### General interface

The list view contains the following columns:

- `Checkbox column` - The checkbox needs to be selected for the editing buttons to become activated. Note that multiple
  selections can be made, but that certain buttons are only available when a single topic is selected (eg. Edit).
- `Category` - The name of the Topic.
- `ID` - The master ID (mid) of the Topic within Clarive.
- `Acronym` - The short notation used when creating instances of this Topic class.
- `Description` - Short description of this Topic class.
- `Type` - Type of Topic class.
    * *Normal* - this is a normal discussion topic that is used to collaborate in the Lean Application Delivery process.
  Examples are Requirement, Change Request, Test  Scenario, etc.
    * *Changeset* - A changeset Topic is used to track changes to assets that are part of the application delivery process.
    * *Release* - This is a Topic that is used to releasing/deploying to certain environments.to tie/assign (code) changes
  to. The following actions buttons are available above the list of Topics:

### Create a new topic

The following information needs to be provided for creation.

- `Category` - Textfield. Name of the new Topic.
- `Description` - Textarea. Short description to explain the definition and purpose of the topic.
- `Type` - The type of topic in a DevOps Context. This can be either Normal, Changeset or Release (see also above).
- `Pick a Color` - Select the color to be used for this Topic. Colors support better visibility.
- `Default Grid` - This option allow to use report as a customized grid in order to view the data of the topic.
- `Form`  - is the form that is assigned to the topic and can be edited in the tab "Admin->Rules".
- `Dashboard` - This option allow to put a Dashboard in topic view.
- `Provider` - Specifies the provider of the Topic. This can be either internally created or any of the available
  integrations, such as for example Bugzilla/Basecamp/Trac/Redmine/BMC Remedy/Jira/HP PPM/Clarity.
- `Options` - Currently only one option is available: make the topic read only.  This is used only for integrations to
  avoid overwrite of information.
- `Status Grid` - Select the different statuses this topic can have.  The grid shows the available statuses (as defined
  under configuration items-ci-status) and their description. Select statuses by making the corresponding checkboxes.
  Maintaining a Status is explained in a separate chapter “Maintaining Statuses”

### Delete the selected Topics.

All the Topic classes that have their checkbox selected will be deleted.

The system will provide a confirmation message before actually deleting the Topic classes.

The Topic class can not be deleted as long as there are instances for that topic in the database.
The instances should be inspected first and deleted before the topic class can be deleted, assuring database integrity.

### Edit the selected Topic Class

Allows editing the selected Topic class. Note that this button is only available when a
single Topic class has been selected. Once changes have been made, select the “Accept”.
To avoid any changes, select the “Close” button instead.

### Duplicate the selected Topic Class

Allows duplication of the selected Topic class. Note that this button is only available
when a single Topic class has been selected. A new Topic class is created with the same
values as the original class. Its initial name will be the name of the original Topic Class with a number.

### Import/Export

Import/Export low level configuration data of the selected Topic Classes
Allows importing or exporting low level configuration data of the selected Topic classes. When
clicking on the above symbol, an option for Export <img src="/static/images/icons/export.svg" alt='Export' />
as well as an option for Import <img src="/static/images/icons/import.svg" alt='Import' /> will be available.

Import and export format is in YAML

### Edit the Workflow of the selected Topic Class

Allows editing of the workflow restrictions of the selected Topic class.
Note that this button is only available when a single Topic class has been selected.

Workflow restrictions are tight to a specific role defined within Clarive.

The workflow editor window will show all available roles in the top left window.  To create the possible transitions per
role, you first select the role(s) that can make the status transition, then you select the status from where the
transition starts (the dropdown “Status from”), then in the listbox under the status from, you can select all the status
that are allowed for the selected roles.  Once ready you hit <img src="/static/images/icons/down.svg"/> to add the
selected transitions to the list shown in the bottom part of the window.

In case you want to remove certain transitions,you can select for which roles, which transitions need to be removed
(same way as for adding as described above), but you then hit <img src="/static/images/icons/clear-all.svg"
alt='Remove'/> to remove the transitions from the list.

