---
title: Rule Concepts
icon: rule
---

Once the different needs are recorded and managed through the
various states that make up their lifecycle, they must be deployed and delivered for final operation.
It is highly related to Change set Management.
Rule Management is in charge of automation and deployment among systems.

Automation is done through rules executions; they must be
created first using Clarive process definition, also Clarive supplies
all needed tools to manage rules. For rule management, a number of
Clarive concepts are describe here.

### Types of rules

There are six types of rules:

**Event**

Triggers or triggers based on actions performed on the system.

There are 3 types of event rules:

1) **Pre online**

Load rule before the execution of the event

2) **Post online**

The rule loads synchronously with the event

3) **Post offline**

The rule runs after the event.

**Pipeline Rule**

A pipeline rule is a rule that promotes, demotes or just deploys
changes from releases and/or changesets into an environment.

The rule can also become the default for a given transition:

**Promote**

Promotes a conceptually superior environment,
for example from pre-production to production

**Static**

Used to redeploy changesets to the same environment they currently occupy.

**Demote**

Demotes a conceptually inferior environment,
for example from production (PROD) to pre-production (PREP).

### Job Steps

When a rule is created, 5 steps are displayed, these are:

- **CHECK**: Check before creating the job, job object not yet available.

- **INIT**: Check after creation, but in order to job longer available.

- **PRE**: Immediate implementation prior to the scheduled time.

- **RUN**: Run at the scheduled time.

- **POST**: Runs allways when job finishes right or wrong.


### Types of Tasks

It is divided in three types of tasks:

1) **Statements**

Provide control flow rule, they are IFs and Fors, and ad- hoc tasks.

2) **Services**

Operating in the pass,  they can be:

3) **Job Services**

Tasks associated to a job.

4) **Generic Services**

General type.

**Rules**: Allow including rules within other rules, these rules to be include have to be of independent type.

### Other rules

**Report**

Create a report with Perl code.

**Webservice**

Allows to integrate webservices in rules.

**Independent**

Little rules to include within more complex rules, simplifying the system.

**Dashboard**

Rule that allows the user to create a personalized dashboard with dashlets components.

**Form**

Rule composed by fieldlets that shape the form of a topic.

### Stash

The stash of the rules is Clarive system that keeps the state of the pass between runs.
Stash variables are used to communicate between tasks and
it is used to replace the variables in the different configurations.
