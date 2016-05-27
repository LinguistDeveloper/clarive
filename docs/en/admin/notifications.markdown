---
title: Email Notifications
index: 4
icon: email
---

In the menu bar, "Administration" menu we select the
<img class = "bali-topic-editor-image" src = "/static/images/icons/email.png" /> Notifications options.

This shows in the main panel of the grid Clarive notification and the top bar with the available actions (buttons).

The information is presented in the form of columns with the following order:

### Events

It is based on the procedure for creating notifications.

In Clarive notifications are configured by events.

Check the "Event..." for further information on the classification of events in Clarive.


### Recipients

Recipients of the notifications. More information on "Create Notification: Recipient ...".

### Scopes

Describe more properties of the notification. These properties are:

 - *Project*: The project defined when creating the notification. This allows you send notification according to the project where the event occurs.

 - *Environment*: The environment defined for the notification.

 - *Status*: The final status defined for the notification.

 - *Step*: The step defined for the notification.

 - *Category*: Category topics.

 - *Category Status*: Range defined states.

### Action

Action indicates the type of notification, Send or Exclude.


### Active

All notifications can be enabled or not created.

This column shows the state through a <img  src = "/static/images/icons/start.png" /> or <img src ="/static/images/icons/stop.png "/>.

All column headers have the same functionality as in the rest of the panels Clarive.

By clicking the button we can arrange additional information and select the columns you want to see on the panel.


### <img src = "/static/images/icons/add.gif" /> Create

To create a new notification click on create button.

There are a several options to configure:

- `Event` - The range of events is extensive yet intuitive, because its syntax follows a definite rule:
<p style = "text-align: center; font-weight: bold"> Example: event.topic.create → event element + action + item </p>

Summarized below:

*event* - Show the type of notification. In this case are of type **event**.

*topic*: Indicates the category of the notification.

*create*: Indicates the action to do.

* As a rule,the events are described below:

*Auth*: Authentication system.

*File*: File.

*Job*: Jobs.

*Post*: Comments.

*Repository*: Events.

*Rule*: Rules.

*Topic*: Topics.

*User*: Comments (creation only).

*Ws*: Web services.

- `Send/Exclude` - Notifications can be set up to send and filter out where appropriate.

The notifications that apply to every event triggered
is calculated by an algorithm that first chooses which notifications apply,
then calculates the exclusions to filter out.

- `Template` - HTML templates define the notification interface.

Select the options that start with "generic".

The *generic.html* template is the simplest (a title + body)

- The rest of the templates are created for more concrete elements:

*generic_assigned.html*: Specific to `event.topic.modify_field` notification.

*generic_post.html*: Notifications about comments.

*generic_rule.html*: Notifications of rules.

*generic_topic.html*: Notifications on topics.

- `Subject` - You can create a default subject (leaving check marked "Default") or edit the field. The issue may be:

A simple string.

A dynamic subject, referencing stash variables (for example $ {username}).

- `Recipients` - Through the <img src = "/static/images/icons/add.gif" /> Create button select the recipient/s notification (may be erased in this window).

First combo:

*To*

*CC*

*BCC*

Second combo:

*Users*: Selects users who receive the notification.

*Roles*: Selects the group of users who receive the notification.

*Actions*: Selected an action, sends a notification to all users who are assigned this action based projects.

*Fields* - Allow to send notification to users that are specified in a user combobox fieldlet.

*Owner* - Send a notification to the owner of the topic.

*Email*: Send the notification to the email selected.

In some cases notifications need additional information about the scope of the event, ie, the conditions to be met by the deployment event.

*Job*. Additional field: Project/Environment/Steps.

*Post*. Additional fields: Project/Category/State.

*Topic*. Additional fields: Project/Category/State.

Each system event has a different scope:

- When left blank when defining the notification, the notification will only be launched if the event also has the empty field.

- When we mark the checkbox "All", to the right of the fields, the condition is satisfied for any value of the data in the event.


Once complete all fields is the OK button is selected to create the new notification.

### <img src = "/static/images/icons/edit.gif" /> Edit

The issue of notification option is activated when you select one from the list (by checking the checkbox to the left of each row in the "Event" column).

Access the same window with the same fields as the Create menu.


### <img src = "/static/images/icons/start.png" /> Activate / <img src = "/static/images/icons/stop.png" /> Deactivate

To enable or disable one or more notifications, select the checkbox to the left of each row.

### <img src = "/static/images/icons/delete_.png" /> Delete

Erasing notifications.

### <img src = "/static/images/icons/import.png" /> Import / <img src = "/static/images/icons/export.png" /> Export

In the button bar, press <img src = "/static/images/icons/wrench.gif" />.

Select notifications from the list, then click the Export button,
the system generates a YAML file with the the notifications data.

The import option opens a window that allows
to enter the exported notification YAML and import it.
