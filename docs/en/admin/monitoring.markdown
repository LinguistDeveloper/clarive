---
title: Monitoring Jobs
index: 1000
---

The Clarive Job Monitor keeps track of all jobs running in the
system in a single, integrated interface.

Each job shown in the monitor links to both their Job Dashboard
and Job Log interface, for extensive detail on what is being run by the job.

## Monitor Fields and Data

#### Job Statuses

Here's a list of job statuses and their meaning:

- `Ready` - job is waiting to be picked-up by the job daemon, which can happen
  at any moment, except for the `RUN` step, which runs at a scheduled date.
- `Running` - job is currently running
- `Waiting for Approval` - waiting for an approver to approve or reject the job
  in the monitor.
- `Rejected` - approver has rejected the job. Job is at a stand-still and won't
  be run unless action is taken.
- `Expired` - the current date and time is greater than the `Max Start Date`,
  so the job `RUN` step has been canceled
- `Abend` - the Job Daemon could not find the job process on the server, so
  it's marked as an aborted (crashed or killed) process
- `Rollback` - job is running a rollback operation
- `Finished` - job finished running
- `Error` - job finished with an error at any of its steps
- `Canceled` - job was canceled by a user while it was running
- `Trapped` - an error was trapped and it's waiting for user input
- `Trap Paused` - user has decided to pause the trap timeout counter since a
  longer resolution time is expected.

Always check the `Step` column to get a sense of where the job is at a given point in time.

#### Job Steps

Job steps indicate which phase of the job is being run (or expected to be run)
by the job daemon at a given time.

- `CHECK` - this step is previous to a job being created in the database and is
  not visible in the monitor
- `INIT` - job has just been created, but the user is still waiting for
  confirmation. This is actually visible in the monitor
- `PRE` - during this step, the job will run all preparation that does not
  affect target environments, such as building an application or running tests.
- `RUN` - this step contains the rule logic that is going to run during the
  scheduled time.
- `POST` - this is the final step in the job pipeline chain. This step runs in
  the event of success or failure after a `PRE` or `RUN`steps

#### Job Progress

Progress is calculated by counting the number of total ops
against the ones that have run. It does not include any loop
unrolling, so the progress may not be 100% accurate, but
gives an idea of how far the job pipeline has advanced.

#### Job Natures

Once the job contents are determined, Clarive parses all
revisions and determines which natures are included.

So, this information is not necessarily available after job
creation, but only after the `PRE` step runs.

#### Job Dates

- `Start Date` - the real date-time that the job started its `PRE` step.
- `End Date` - the real date-time when the job reached its `END` step.
- `Scheduled` - this is when the `RUN` step is planned to run.
- `Max Start Date` - if the job does not start by this date, it is marked as
  `Expired` automatically by the job daemon.

## Monitor Actions

With the job monitor, you can control what happens
to each job running, such as starting, canceling, deleting, reruning, etc.

These actions also require that the user have the adequate permissions, discussed
further down this section.

### Rerun

Rerun allows a job to be put in `Ready` status for a given step.

Normally, jobs are either rerun for `PRE` or `RUN` steps, to repeat things like
build or deploy phases.

Also `POST` steps may be run for redoing things like resend notifications or
promotions.

**NOTE**: If you rerun a step, all following steps will also be rerun, with the
following behavior:

- if a `PRE` step is rerun, the `RUN` step still will preserve and wait for its
  scheduled date to be run.
- if a `RUN` step is rerun, the scheduled date can be overruled with the `Run
  Now` option.

### Reschedule

Jobs that are in `Ready`, `Expired` or `Waiting for Approval` can be
rescheduled, which means setting a new date for the `RUN` step to start.

### Job Expiration

Jobs expire automatically when its `Scheduled Date` is greater than their `Max
Start Date`.  The purpose of expiring jobs is to prevent them from start a
deployment beyond a system outage, in a off-time.

### Canceling Jobs

Jobs in a `Running` state can be canceled. That will terminate the job
immediately in the Clarive server, but **does not** prevent processes running


#### Handling Expired Jobs

If a job has expired, it is not going to run. But using the
monitor actions, the operator has 2 options:

- Rerun the job at either `PRE` or `RUN` steps
- Reschedule the job for another time

### Permissions

- `action.job.view_monitor` - has access to see jobs for the authorized scopes
  in the Job Monitor
- `action.job.approve_all` - approve any job, even if not in the approval list
- `action.job.restart` - rerun a job
- `action.job.cancel` - cancel a job
- `action.job.delete` - delete a job
- `action.job.create` - can create a job

