---
title: Email Notifications
icon: email
---

* In the menu bar, "Administration" menu we select the 
<img class = "bali-topic-editor-image" src = "/static/images/icons/email.png" /> Notifications options. 

* This shows in the main panel of the grid Clarive notification and the top bar with the available actions (buttons).

<br />

* The information is presented in the form of columns with the following order: 

<br />
### Events

* It is based on the procedure for creating notifications. In Clarive notifications are configured by events. 

* Check the "Event ..." for further information on the classification of events in Clarive.

<br />
### Recipients
* Recipients of the notifications. More information on "Create Notification: Recipient ...".

<br />
### Scopes

* Three subcategories with whom you can relate the field (see "<img src ="/static/images/icons/edit.gif "/> Edit"). <br />
    
    &nbsp; &nbsp;• *Project*: Project defined.<br />
    
    &nbsp; &nbsp;• *Category*: Category topics. <br />
    
    &nbsp; &nbsp;• *Category Status*: Range defined states.

<br />
### Action
* Two possible options, Send or Exclude.

<br />
### Active
* All notifications can be enabled or not created. This column shows the state through a <img  src = "/static/images/icons/start.png" /> or <img src ="/static/images/icons/stop.png "/>.

* All column headers have the same functionality as in the rest of the panels Clarive. By clicking the button we can arrange additional information and select the columns you want to see on the panel.

<br />


<br />
### <img src = "/static/images/icons/add.gif" /> Create

* To create a new notification click on create button.


* There are a several options to configure:

&nbsp; &nbsp;• `Event` - The range of events is extensive yet intuitive, because its syntax follows a definite rule: <br />
<p style = "text-align: center; font-weight: bold"> Example: event.topic.create → event element + action + item </p>

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;• Summarized below: <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Auth*: Authentication system. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *File*: File. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Job*: Jobs. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Post*: Comments. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Repository*: Events. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Rule*: Rules. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Topic*: Topics. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *User*: Comments (creation only). <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Ws*: Web services. <br />



&nbsp; &nbsp;• `Send/Exclude` <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;• Notifications can be set up to ship or exempt them where appropriate. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;• In the order of the notifications, they will be executed first and then the exclusions shipments. <br />


<br />


&nbsp; &nbsp;• `Template` <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;• HTML templates define the notification interface. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;• Select the options that start with "generic". <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;• The *generic.html* template is the simplest (a title + body) <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;• The rest of the templates are created for more concrete elements: <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *generic_assigned.html*: Specific to `event.topic.modify_field` notification. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *generic_post.html*: Notifications about comments. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *generic_rule.html*: Notifications of rules. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *generic_topic.html*: Notifications on topics. <br />

<br />

&nbsp; &nbsp;• `Subject` - You can create a default subject (leaving check marked "Default") or edit the field. The issue may be: <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;• A simple string. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;• A dynamic subject, referencing stash variables (for example $ {username}). <br />


<br />


&nbsp; &nbsp;• `Recipients` - Through the <img src = "/static/images/icons/add.gif" /> Create button select the recipient/s notification (may be erased in this window). <br />


&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;• First combo: <br />


&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *To* <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *CC* <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *BCC* <br />


&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;• Second combo: <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Users* <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Roles* <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Actions* <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Fields* <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Owner* <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Email* <br />

<br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;• In some cases notifications need additional information about the scope of the event, ie, the conditions to be met by the deployment event. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Job*. Additional field: Project. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Post*. Additional fields: Project/Category/State. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Topic*. Additional fields: Project/Category/State. <br />

<br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;• Each system event has a different scope: <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• When left blank when defining the notification, the notification will only be launched if the event also has the empty field. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• When we mark the checkbox "All", to the right of the fields, the condition is satisfied for any value of the data in the event. <br />



<br />

* Once complete all fields is the OK button is selected to create the new notification.



<br />
### <img src = "/static/images/icons/edit.gif" /> Edit

* The issue of notification option is activated when you select one from the list (by checking the checkbox to the left of each row in the "Event" column).

* Access the same window with the same fields as the Create menu.

<br />
### <img src = "/static/images/icons/start.png" /> Activate / <img src = "/static/images/icons/stop.png" /> Deactivate

* To enable or disable one or more notifications, select the checkbox to the left of each row.

<br />
### <img src = "/static/images/icons/delete_.png" /> Delete

* Erasing notifications.

<br />
### <img src = "/static/images/icons/import.png" /> Import / <img src = "/static/images/icons/export.png" /> Export

* In the button bar, press <img src = "/static/images/icons/wrench.gif" />.

* Selecting/notifications, and clicking the Export button, the system generates a YAML file with the data/the notification/s.

* The import option activates the same window, empty, where you can enter text.

