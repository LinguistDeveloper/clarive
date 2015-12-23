---
title: Job
icon: job
---

* Jobs are rules executed by the Clarive server. 

* Jobs are always scheduled, even if scheduled to run "now" or in 3 months, 
they always have a schedule and are run by the job daemon. 

* Jobs can be executed many times through [reruns](concepts/rerun). 

* Unlike Jenkins, jobs are not a statically scheduled entity. You cannot schedule
repeateable jobs. Jobs are *schedule-once* and *run-once* (even though you may manually
reschedule or rerun them as many times as you like). 

* If you wish to schedule a job to run frequently (ie. nightly), use the [Scheduler](concepts/scheduler) facility.

<br />
## Job are CIs

* The job name identifies the job. But jobs are also CIs and therefore have a [mid](concepts/mid).
