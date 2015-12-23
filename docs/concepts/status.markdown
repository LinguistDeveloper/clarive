---
title: Statuses and transitions
index: 400
icon: status
---

* A status represents the state of an issue at a particular point in a specific [workflow](concepts/workflow). An issue can be in only one status at a given point in time.

* When defining a status, you can optionally specify properties. Read more about them in the [administration page](admin/status). 


<br />
### Transitions

* A transition is a link between two statuses that enables an issue to move from one status to another. In order for an issue to move between two statuses, a transition must exist.

* A transition is a one-way link, so if an issue needs to move back and forth between two statuses, two transitions need to be created. The available workflow transitions for an issue are listed on the View issue screen.

<br />
### Status Types

* There are 3 status types: <br />

&nbsp; &nbsp;• **New** - Indicates that a [topic](concepts/topic) has just been created and has not been "picked up" by the team <br />

&nbsp; &nbsp;• **Cancelled** - Indicates an aborted status <br />

&nbsp; &nbsp;• **Closed** - Indicates that the status is probably the last one in the flow. By setting a status to Closed, we are preventing the topics in this state to be shown in most view, like the topic lists / grids and Kanbans. <br />

&nbsp; &nbsp;• **Deployable** - Means that, as part of a transition into this status (promote), Changeset topics need to be deployed to one of the associated environments. As part of the transition out (demote), Changeset topics need to be backed-out from the environment. <br />

&nbsp; &nbsp;• **Generic** - Any other statuses fall into this category.

<br />
### Promote

* Promote transitions in Clarive are meant to represent transitions to Deployable states.

<br />
### Demote

* Demote transitions, on the other hand, generate backout transitions, with a rollback [job](concepts/job).
