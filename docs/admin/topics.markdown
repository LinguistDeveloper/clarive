---
title: Topics Administration
icon: topic
---


 * Topic administration is performed by selecting Admin-Topics from the menu bar. This will display all the
currently available topics in a list view:

<br/>
### General interface
<br/>

 * The list view contains the following columns: <br/>

&nbsp; &nbsp;• `Checkbox column`: The checkbox needs to be selected for the editing buttons to become activated. Note that multiple selections can be made, but that certain buttons are only available when a single topic is selected (eg. Edit).  <br />
    


&nbsp; &nbsp;• `Category`: The name of the Topic. <br />

&nbsp; &nbsp;• `ID`: The master ID (mid) of the Topic within Clarive. <br />

&nbsp; &nbsp;• `Acronym`: The short notation used when creating instances of this Topic class. <br />

&nbsp; &nbsp;• `Description`: Short description of this Topic class. <br />

&nbsp; &nbsp;• `Type`: Type of Topic class. <br />
    
&nbsp; &nbsp;&nbsp; &nbsp;• *Normal*: this is a normal discussion topic that is used to collaborate in the Lean Application Delivery process. Examples are Requirement, Change Request, Test  Scenario, etc. <br />

&nbsp; &nbsp;&nbsp; &nbsp;• *Changeset*: A changeset Topic is used to track changes to assets that are part of the application delivery process. They are typically used <br />

 &nbsp; &nbsp;&nbsp; &nbsp;• *Release*: This is a Topic that is used to releasing/deploying to certain environments.to tie/assign (code) changes to. 

<br/>

* The following actions buttons are available above the list of Topics:


<br/>
### <img src = "/static/images/icons/add.gif" alt='New topic' /> Create a new topic

* The following information needs to be provided for creation. <br />

&nbsp; &nbsp;• `Category`: Textfield. Name of the new Topic. <br />

&nbsp; &nbsp;• `Description`: Textarea. Short description to explain the definition and purpose of the topic. <br />

&nbsp; &nbsp;• `Type`: The type of topic in a DevOps Context. This can be either Normal, Changset or Release (see also above). <br />

&nbsp; &nbsp;• `Pick a Color`: Select the color to be used for this Topic. Colors support better visibility. <br />

&nbsp; &nbsp;• `Provider`: Specifies the provider of the Topic. This can be either internally created or any of the available
integrations, such as for example Bugzilla/Basecamp/Trac/Redmine/BMC Remedy/Jira/HP PPM/Clarity. <br />

&nbsp; &nbsp;• `Options`: Currently only one option is available: make the topic read only. This is used only for integrations to avoid overwrite of information. <br />

&nbsp; &nbsp;• `Status Grid`: Select the different statuses this topic can have. The grid shows the available statuses (as defined under configuration items-ci-status) and their description. Select statuses by making the corresponding checkboxes. Maintaining a Status is explained in a separate chapter “Maintaining Statuses”


<br/>
### <img src = "/static/images/icons/delete_.png" alt='Delete topic' /> Delete the selected Topics.

* All the Topic classes that have their checkbox selected will be deleted. 

* The system will provide a confirmation message before actually deleting the Topic classes. 

* The Topic class can not be deleted as long as there are instances for that topic in the database. The instances should be inspected first and deleted before the topic class can be deleted, assuring database integrity.


<br/>
### <img src = "/static/images/icons/edit.gif" alt='Edit topic' /> Edit the selected Topic Class 

 * Allows editing the selected Topic class. Note that this button is only available when a single Topic class has been selected. Once changes have been made, select the “Accept”. To avoid any changes, select the “Close” button instead.


<br/>
### <img src = "/static/images/icons/copy.gif" alt='Duplicate topic' /> Duplicate the selected Topic Class 

 * Allows duplication of the selected Topic class. Note that this button is only available when a single Topic class has been selected. A new Topic class is created with the same values as the original class. Its initial name will be the name of the original Topic Class with a number.

<br/>
### <img src = "/static/images/icons/wrench.gif" alt='Import_export' /> Import/Export

* Import/Export low level configuration data of the selected Topic Classes
Allows importing or exporting low level configuration data of the selected Topic classes. When
clicking on the above symbol, an option for Export <img src = "/static/images/icons/export.png" alt='Export' /> as well as an option for Import <img src = "/static/images/icons/import.png" alt='Import' /> will be available. 

* Import and export format is in YAML


<br/>
### Edit the Workflow of the selected Topic Class

- Allows editing of the workflow restrictions of the selected Topic class. Note that this button is only available when a single Topic class has been selected.<br />

- Workflow restrictions are tight to a specific role defined within Clarive. 

- The workflow editor window will show all available roles in the top left window. To create the possible transitions per role, you first select the role(s) that can make the status transition, then you select the status from where the transition starts (the dropdown “Status from”), then in the listbox under the status from, you can select all the status that are allowed for the selected roles. Once ready you hit <img src = "/static/images/icons/down.png"/> to add the selected transitions to the list shown in the bottom part of the window. <br />

- In case you want to remove certain transitions,you can select for which roles, which transitions need to be removed (same way as for adding as described above), but you then hit <img src = "/static/images/icons/remove.png" alt='Remove'/> to remove the transitions from the list.
