---
title: Calendar Administration
---

The Calendaring administration interface allows administrators
to setup when jobs can be scheduled depending on job scope and
contents.

A `Calendar` is a set of weekly (7) slots that go from 12am to 11:59pm (00:00h to 23:59h).

A `Calendar Slot` or `Slot` is the block formed by a start time, end time, slot type and either a given
weekday or specific date.

### Calendar List

This contains the list of calendars that have been configured.

To create a new calendar, select `Create`.

- `Calendar Name` - name of the calendar being
created.
- `Description` - a brief description (optional)
- `Precedence` - set the precedence this calendar has over others
when several calendars converge. The higher the precedence, the better.
- `Creation Mode` - either creates the calendar with an empty list of
slots (`Create as New`) or as a copy of another calendar slots ( `Create as Copy`)
- `Environment` - the environment the calendar applies to
- `Scope` - the scope of the calendar, either only for a specific Project, or for
any other scope in the system.

### Editing a Calendar

In edit mode, you can setup the calendar slots and change the
main properties of the calendar, such as precedence or scope.

#### Adding a weekly slot

To add a weekly slot, ie. one that will repeat everyday, just select
the block from `00:00` to `23:59` by clicking on it.

The slot edit window, `Edit Calendar Slot`, will open up:

- `Weekday` - the weekday selected
- `Type` - the type of slot, `Normal`, `Urgent` or `No Job`
- `Starts at` - time ends will start
- `Ends at` - time slot ends

If slots of the same type are created next to each other, they
will be automatically merged.

**NOTE**: the slots are saved immediately, so there's no cancel
button available.

#### Normal Slot

The normal slot means jobs can be schedule by anyone with a role
that has the `Create Job` action.

#### Urgent Slot

The urgent slot means users with `Create Job` action can also schedule,
but the job will be marked as `Urgent`.

The effect selecting a `Urgent` calendar slot on a job has to be
defined in the job pipeline rule. Typically, it will be rule logic
as following:

    IF job IS URGENT
        Request Approval

At the end of the `PRE` step.

#### Empty Slots

`Empty` slots mean they'll be overwritten by any other slot
that's set by another calendar with higher or lower precedence.

#### No Job

The `No Job` slot prevents lower precedence slots from enabling
`Normal` or `Urgent` slots. Use `No Job` instead of just `Empty` to
create a higher precedence slot that prevents job creation at
specific times.

#### Active / Inactive Slots

Slots can be created or modified into an "inactive" state.
The effect of an inactive slot is that it behaves as it did
not existed. This behavior will last until the slot is activated
again.

This is useful for situations where the slot is temporarily inactive
(ie. due to maintenance), but deleting the slot would result in
losing the information that was already defined.

### Date-Specific Slots

Date-specific slots are slots that only occur at one, non-recurring
date in time.

To create a date-specific slot, select the `new slot mm/dd/yyyy`
link in the bottom of the slot editor. Use the calendar widget
on the right to navigate to the week where the slot is defined.
