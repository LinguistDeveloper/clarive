---
title: Monitor
index: 5000
icon: television
---

The monitor show the list of [jobs](concepts/job) that have been created and the status of the jobs.
You can change how the names appear in monitor modifying the variable config.job.mask [Config Job Mask](how-to/config-job-mask).

The following actions buttons are available above the list of Jobs:

<img src="/static/images/icons/html.svg" /> **HTML** - Shows the log of the job selected in html format.

<img src="/static/images/icons/project.svg" /> **Project** - Filters the jobs by project.

<img src="/static/images/icons/baseline.svg" /> **Environment** - Filters the jobs by environment.

<img src="/static/images/icons/nature.svg" /> **Nature** - Filters the jobs by nature.

<img src="/static/images/icons/state.svg" /> **Status** - Filters the jobs by [status](concepts/status).

**Type** - Filters the jobs by type.

<img src="/static/images/icons/job.svg" /> **New** - Create a new job.

<img src="/static/images/icons/moredata.svg" /> **Full log** - Shows the log of the job selected.

<img src="/static/images/icons/delete.svg" /> **Delete** - Delete the job selected.

<img src="/static/images/icons/left.svg" /> **Rollback** - Run the [rollback](concepts/rollback).

<img src="/static/images/icons/restart.svg" /> **Rerun** - Start the job again from the step user wants.

<img src="/static/images/icons/datefield.svg"  /> **Reschedule** - Modify the schedule of the job. This action is only available when the status of the job is Ready or Waiting for Approval.

