---
title: Email Notifications
icon: email
---

* This document describes the procedure for the administration of 
notifications in Clarive.

<br />
### Access and general interface.

* In the menu bar, "Administration" menu we select the 
<img class = "bali-topic-editor-image" src = "/static/images/icons/email.png" /> Notifications options. 

* This shows in the main panel of the grid Clarive notification and the top bar with the available actions (buttons).

** The information is presented in the form of columns with the following order: **

<br />
### Events

* It is based on the procedure for creating notifications. In Clarive notifications are configured by events. 

* Check the "Event ..." for further information on the classification of events in Clarive.

<br />
### Recipients
* Recipients of the notifications. More information on "Create Notification: Recipient ...".

<br />
### Areas

* Three subcategories with whom you can relate the field (see "<img src ="/static/images/icons/edit.gif "/> Edit"). <br />
    
    &nbsp; &nbsp;• *Project*: Project defined.<br />
    
    &nbsp; &nbsp;• *Category*: Category topics. <br />
    
    &nbsp; &nbsp;• *Category/Status*: Range defined states.

<br />
### Action
* Two possible options, Send or Exclude.

<br />
### Enabled

* All notifications can be enabled or not created. This column shows the state through a <img class = "bali-topic-editor-image" src = "/static/images/drop-yes.gif" /> or <img class = "bali-topic-editor -image "src ="/static/images/close-small.gif "/>.

* All column headers have the same functionality as in the rest of the panels Clarive. By clicking the button we can arrange additional information and select the columns you want to see on the panel.

<br />
### Action bar
* In the top bar of the main panel the search bar to filter the grid, and buttons for managing notifications are provided.

<br />
### <img src = "/static/images/icons/add.gif" /> Create

* To create a new notification click on create button. A window appears, Create Notification. The fields to be filled are: <br />

<br />
### Action bar
* In the top bar of the main panel the search bar to filter the grid, and buttons for managing notifications are provided.

&nbsp; &nbsp;• *Event.* <br />

&nbsp; &nbsp;• *Radio "Send/Exclude".* <br />

&nbsp; &nbsp;• *Template.* <br />

&nbsp; &nbsp;• *Subject.* <br />

&nbsp; &nbsp;• *Recipients.* <br />

<br />
### Event
* The range of events is extensive yet intuitive, because its syntax follows a definite rule:

<p style = "text-align: center; font-weight: bold"> Example: event.topic.create → event element + action + item</p>

<!--- [comment]: <> &nbsp; &nbsp;&nbsp; &nbsp; • ** ** : Ask Doc "events Clarive map" for a detailed description. Summarized below:   
<br />
- auth: authentication system.
- file: file.
- job: jobs.
- post: comments.
- repository: events.
- rule: rules.
- topic: topics.
- user: Comments (creation only).
- ws: web services.

-->
<br />
* Action: Depending on the element to which it refers. It can be: create, delete, modify.

<br />
### Radio Send/exclude ...

* Notifications can be set up to ship or exempt them where appropriate.

* In the order of the notifications, they will be executed first and then the exclusions shipments.

<br />
### Templates ...

* HTML templates define the notification interfae. 

* Select the options that start with "generic". 

* The generic.html template is the simplest (a title + body).
The rest of the templates are created for more concrete elements: <br />

&nbsp; &nbsp;• *generic_assigned.html*: Specific to `event.topic.modify_field` notification. <br />

&nbsp; &nbsp;• *generic_post.html*: Notifications about comments. <br />

&nbsp; &nbsp;• *generic_rule.html*: Notifications of rules. <br />

&nbsp; &nbsp;• *generic_topic.html*: Notifications on topics. 

<br />
### Subject

* You can create a default subject (leaving check marked "Default") or edit the field. The issue may be: <br />


&nbsp; &nbsp;• *A simple string.* <br />

&nbsp; &nbsp;• *A dynamic subject, referencing stash variables (for example $ {username}).*

<br />
### Recipient

* Through the <img src = "/static/images/icons/add.gif" /> Create button select the recipient/s notification (may be erased in this window).

&nbsp; &nbsp;• First combo: <br />


&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• To <br />

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• CC <br />

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• BCC <br />

&nbsp; &nbsp;• Second combo: <br />


&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Users <br />

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Roles <br />

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Actions <br />

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Fields <br />

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Owner <br />

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Email <br />

&nbsp; &nbsp;• In some cases notifications need additional information about the scope of the event, ie, the conditions to be met by the deployment event. <br />


&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Job. Additional field: Project. <br />

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Post. Additional fields: Project/Category/State. <br />

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Topic. Additional fields: Project/Category/State.

* Each system event has a different scope:


&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• When left blank when defining the notification, the notification will only be launched if the event also has the empty field. <br />

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• When we mark the checkbox "All", to the right of the fields, the condition is satisfied for any value of the data in the event.

<br />
* Once complete all fields is the OK button is selected to create the new notification.

<br />
### <img src = "/static/images/icons/edit.gif" /> Edit

* The issue of notification option is activated when you select one from the list (by checking the checkbox to the left of each row in the "Event" column).

* Access the same window with the same fields as the Create ...

<br />
### <img src = "/static/images/icons/start.png" /> Activate / <img src = "/static/images/icons/stop.png" /> Deactivate

* To enable or disable one or more notifications, select the checkbox to the left of each row.

<br />
### <img src = "/static/images/icons/delete_.png" /> Delete

* Erasing notifications.

<br />
### <img src = "/static/images/icons/import.png" /> Import / <img src = "/static/images/icons/export.png" /> Export

* In the button bar, press <img src = "/static/images/icons/wrench.png" />.

* Selecting/notifications, and clicking the Export button, the system generates a YAML file with the data/the notification/s.

* The import option activates the same window, empty, where you can enter text.

