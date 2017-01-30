---
title: Calendar
index: 5000
icon: dashlet-topic-calendar
---

Shows the calendar in the dashboard.

There are a list of elements can be configured in the dashlet:

### Dimensions of the dashlet

Can personalize the size of the dashlet modifying the number of columns and rows.


### Autorefresh

Allows to make the dashlet more dinamic adding an automatic refresh (in minutes).


### Calendar query

Indicate what activity or issue will show in the calendar. The options are:

- **Topic Activity** - Allows to view topic ativity of selected topics from creation to modification.
- **Open topics** - Shows open topics from creation to final statuses.
- **Calendar planner** *(eg: Milestones or Environment planner)* - Show schedulers with job slots o specific milestones.
- **Own fields** - Personalize the fields to show, for example, if user want to see only a specific range of dates. Need to specify two fields:
  - *Initial date*.
  - *Final date*

### Default View

Establish the default view of the calendar:

- **Month** - Shows a month view by default.
- **Basic week** - Show the complete week (from Sunday to Monday)
- **Schedule week** - Show the week divided by hours.
- **Basic day** - Only shows the present day.
- **Schedule day** - Shows the present day divided by hours.s


### First weekday

Select the first day of the week to see the calendar.


### Select topics in categoroes

The option gives to user the chance to select the topics that will appear in the calendar view


### Advanced JSON/MongoDB condition for filter

Allows to use a JSON format o MongoDB query to add a condition.


### Label mask

Allows to personalize the information will show in the topic mask.

*Example*: *${category.acronym}#${topic.mid} ${topic.title}*