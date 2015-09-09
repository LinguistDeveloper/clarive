---
title: Email Notifications
---

This document describes the procedure for the administration of 
notifications in Clarive.

## Access and general interface.

In the menu bar, "Administration" menu we select the 
<img class = "bali-topic-editor-image" src = "/static/images/icons/email.png" />Notifications options. 

This shows in the main panel of the grid Clarive notification and the top bar with the available actions (buttons).

** The information is presented in the form of columns with the following order: **

### Events

It is based on the procedure for creating notifications. In Clarive notifications are configured by events. Check the "Event ..." for further information on the classification of events in Clarive.

### Recipients
    
Recipients of the notifications. More information on "Create Notification: Recipient ...".

### Areas

Three subcategories with whom you can relate the field (see "<img src ="/static/images/icons/edit.gif "/> Edit").

* Project: Project defined.
* Category: Category topics.
* Category/Status: Range defined states.

### Action
  
Two possible options, Send or Exclude.

### Enabled

All notifications can be enabled or not created. This column shows the state through a <img class = "bali-topic-editor-image" src = "/static/images/drop-yes.gif" /> or <img class = "bali-topic-editor -image "src ="/static/images/close-small.gif "/>.


All column headers have the same functionality as in the rest of the panels Clarive. By clicking the button we can arrange additional information and select the columns you want to see on the panel.

## Action bar

In the top bar of the main panel the search bar to filter the grid, and buttons for managing notifications are provided.


### 21. <Img src = "/static/images/icons/add.gif" /> Create.

To create a new notification the <img class = "bali-topic-editor-image" src = "/static/images/icons/add.gif" /> Create menu button is selected. A window appears, Create Notification. The fields to be filled are:

* Event.
* Radio "Send/Exclude.
* Template.
* Subject.
* Recipients.

Event #### ...

The range of events is extensive yet intuitive, because its syntax follows a definite rule:

<p style = "text-align: center; font-weight: bold"> Example: event.topic.create ---> event element + action + </p>

& Nbsp; & Nbsp; & Nbsp; & Nbsp; • ** ** item: Ask Doc "events Clarive map" for a detailed description. Summarized below:

- auth: authentication system.
- file: file.
- job: jobs.
- post: comments.
- repository: events.
- rule: rules.
- topic: topics.
- user: Comments (creation only).
- ws: web services.

Action: Depending on the element to which it refers. It can be: create, delete, modify.

#### Radio Send/exclude ...

Notifications can be set up to ship or exempt them where appropriate.

In the order of the notifications, they will be executed first and then the exclusions shipments.

#### Templates ...

HTML templates define the notification interfae. 

Select the options that start with "generic". 

The generic.html template is the simplest (a title + body).
The rest of the templates are created for more concrete elements:

- generic_assigned.html: specific to `event.topic.modify_field` notification.
- generic_post.html: notifications about comments.
- generic_rule.html: notifications of rules.
- generic_topic.html: notifications on topics.

#### Subject ...

You can create a default subject (leaving check marked "Default") or edit the field. The issue may be:

& Nbsp; & Nbsp; & Nbsp; & Nbsp; • A simple string.
& Nbsp; & Nbsp; & Nbsp; & Nbsp; • A dynamic subject, referencing stash variables (for ejemmplo $ {username}).

#### Recipient ...

Through the <img src = "/static/images/icons/add.gif" /> Create button select the/the recipient/s notification (may be erased in this window).

• First combo:

- To
- CC
- BCC

• Second combo:

- Users
- Roles
- Actions
- Fields
- Owner
- Email

In some cases notifications need additional information about the scope of the 
event, ie, the conditions to be met by the deployment event.

- Job. Additional field: Project.
- Post. Additional fields: Project/Category/State.
- Topic. Additional fields: Project/Category/State.

Each system event has a different scope:

- When left blank when defining the notification, the notification will only be launched if the event also has the empty field.
- When we mark the checkbox "All", to the right of the fields, the condition is satisfied for any value of the data in the event.

Once complete all fields is the OK button is selected to create the new notification.

### <img src = "/static/images/icons/edit.gif" /> Edit

The issue of notification option is activated when you select one from the list (by checking the checkbox to the left of each row in the "Event" column).

Access the same window with the same fields as the Create ...

### <img src = "/static/images/start.gif" /> On/<img src = "/static/images/stop.gif" /> Off.

To enable or disable one or more notifications, select the checkbox to the left of each row.

### <img src = "/static/images/icons/delete.gif" /> Delete.

Erasing notifications.


### <img src = "/static/images/icons/import.png" /> Import/<img src = "/static/images/icons/export.png" /> Export.

In the button bar, press <img src = "/static/images/icons/wrench.png" />.

Selecting/notifications, and clicking the Export button, the system generates a YAML file with the data/the notification/s.

The import option activates the same window, empty, where you can enter text.

