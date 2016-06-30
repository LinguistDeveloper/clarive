---
title: Calendaring - When Can a Job Run?
index: 550
---

Clarive continuous delivery is about letting teams release their changes
whenever they think it's ready, just as it is about letting the organization
plan and execute a carefully organzized delivery process. The Clarive
calendaring system sits in the middle between these 2 approaches or speeds,
working as the arbriter between the organizational requirements and the agility
of teams working against the clock to compete.

Not all jobs can run whenever they are scheduled.  There are external
constraints to be observed, which is key to *avoid disruption* of applications
and services being delivery.

Clarive jobs can include automated and manual deployment and provisioning
tasks.  So, plan your calendar slots carefully to prevent both deploy and/or
provisioning tasks at a given time:

- Environment Calendars
- Nature (technology) Calendars
- Project Calendars
- Calendar for Other CIs

### Plan Weekly

Clarive calendars follow a 7-day layout that repeats weekly.

There can also be specific slots for specfic dates, such as holidays.

### Slot Types

There are 4 slot types:

- `Empty` - no slot has been defined, so no jobs can run
- `Normal` - normal deployment slot
- `Urgent` - urgent deployments only
- `No Job` - no jobs can run during this slot.

The difference between `Empty` and `No Job` is the way they act in a merge. See
below for more info.

### Global Calendar

The global calendar is the default calendar that will be used in case no other
calendar matches.

### Environment Slots

These are the simplest calendars to setup.

Create one calendar for each environment in the system. It's not mandatory, but
may be best to start with at least one calendar per environment, it will make
it easier in the future, in case you are planning to have different calendars
for at least one environment.

If no environment calendars have been setup, then the Global calendar will be
applied.

### Calendar Merge

Let's suppose Release 2.0 is going to deploy 2 different projects into the
Production environment, project A and B.

Project A only allows scheduling of jobs to PROD after 10pm.

Project B has a similar constraint, but after 11pm.

If you try to schedule Release 2.0 to deploy to Production, the first slot
available will be 11pm. That's because Clarive **intersects** slots
restrictively to determine which is the next available slot.

Implementation guidelines:

- set merge priorities for every calendar you create
- only use `No Job` if you want to block the slot at a high-precedence slot.

#### Precedence

The calendar precedence sets the order in which merge is applied.  A higher
precedence means it is more *important* than lower precedence numbers.

If 2 slots have the same precedence, the precedence will be defined by the
alphabetical order of each calendar name.

#### Wildcard Slots

The `Empty` slot is a wildcard slots, and even a higher precedence slot that is
`Empty` can be filled with data from lower precedence.

Use `Empty` to denote that deploy could happen at a given time if needed by any
calendar. Use `No Job` to effectively deny deployment for higher precedence
jobs.

### Calendaring Constraints Through Rules

You can also prevent a job from running by putting a control checking during a
pipeline rule `CHECK` step.

For example, you could check the existance of a file in a directory in the
Clarive server to prevent a job from being created. Just fail (use the `FAIL`
op) during the `CHECK` step to prevent a job from being created.

#### Outward Calendaring Integrations

The rule can also call other tools for checking Calendaring constraints during
the `CHECK` step of the rule.

