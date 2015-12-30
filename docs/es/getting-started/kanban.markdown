---
title: Topic Kanban Board
index: 1200
icon: kanban
---

* Clarive has a Kanban board generator utility that is available from two places: <br />

&nbsp; &nbsp;• The topic grid <br />

&nbsp; &nbsp;• From withing a topic that holds other topics.

* The Kanban board can be opened by clicking on the following icon: 
<img src="/static/images/icons/kanban.png" />


<br />
### How does it work?

* Clarive Kanban boards always start from either a list of topics (from the grid)
or from the topics contained within a topic. 

* From that list, the Kanban will show all from and to statuses available as immediate topic
transitions (transitions that can be performed for the topics shown). 

* It will hide statuses that the user cannot transition to/from or that are not
available as a transition. 

* To change the status of a topic, just drag and drop the status. Only allowed statuses 
are displayed. When a topic is dropped into another status column, that becomes 
the topic new status. 


<br />
### Promote / Demote to Environments

* Statuses that are tied to environments have the environment name(s) on top. 

* If a topic gets dragged into a promotable environment, a new job window will popup. Schedule the job accordingly. When the job runs, the pipeline will take 
care of deploying the changeset contents and promoting the topics into (or demoting them out of) the destination evnironment and corresponding status. 

<br />
### Customizing the Kanban Board

* Kanban boards can be customized by adding or removing status columns. 

* These customizations can be saved by hitting the `Save Layout` button, which is only available
for kanban boards generated within topics. Topic grid boards do not have this option. 
