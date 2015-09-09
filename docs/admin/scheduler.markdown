---
title: Scheduler
---

The Scheduler allows to you to plan, enable, disable or run independent rules in the background,
at given frequencies or times. 

The Scheduler has the folloring information:

- Name of the task along with the log output. 
- Actual status of the task.
- Next time: The time scheduled for the next run.
- Last time: Date and time of the last ejecuciónde the task.
- PID: PID of the last process.
- Description.
- Frequency: Follow the format (1H - 1 hour, 1D - one day ...).
- Day.
- What: The name of the rule and the id has been executed. 

## Creating Scheduled Tasks

To create a new scheduled task, select the `New` button. 

The following fields are required:

- Name: Name of the task.
- Rule: drop-down combo with the independent rules created in Clarive.
- Date: Selecting this button will display a calendar field to select the desired execution date.
- Time: Default actual shows the system time and the arrows can increase or decrease the minutes.
- Frequency: Format (1H - 1 hour, 1D - one day ...).
- Only weekdays: Checkbox to select if you want to run only on weekdays.

## Running Tasks On Demand

If you press the `Run Now` button, the service execution will force immediately, 
regardless of the date of planning.
