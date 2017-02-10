---
title: Manual Steps in Deployment
index: 220
---

Although, ideally deployment is unattended, Clarive allows a deployment job to
have a series of manual steps and manual intervention operations for Dev and
Ops to intervene and collaborate.

Here are some of these manual *breakpoints* that can be implemented:

- Approvals
- Pauses
- (Error) Traps
- Annotations
- ChatOps

Read more about manual steps in a release strategy
by referring to the release execution strategies
in the [releasing guide](guide/releasing).

### Approvals

Approval is a control mechanism that allows a job to be put into an approval
state **after a step has finished**.

This means approvals can only run after a `CHECK`, `INIT`, `PRE` or `RUN` job
steps. Once in an approval state, the job will only advance to the next step if
the approver has approved the job.

If an approver does not approve the job, it will not rollback.

Jobs in an approval state **do not** take resources up.  The job hibernates
until either approval or rejection occurs.

Remember approvals can also be setup as part of a (release, changeset) topic
transition.

### Pause

A pause operation puts the job in a sleep state, waiting for a user with the
adequate permissions to resume the job.

Resume is an operation in the `Job Monitor`.

To setup a pause, add a `Pause` op anywhere in the deployment rule. Pauses
cannot be used during the `CHECK` job step, since this phase occurs at user
time *before* the job has been created.

### Traps

Traps are intended to stop the job as failure occurs.  This topic is covered in
the [rollback guide](guide/rollback).  But traps can be also used for
**assertion**, which means a rule can assert if ie. if a container that has
just been deployed is running.

Traps can be added to assert operations though its op `Properties` right-click
menu option.

For example, call a remote command on a target node to verify that the
container is up after deployment, and setup `Fail on Error` mode.  Then setup
the error trap on this op to prevent the deployment job to rollback at that
point in time.

### Annotations

Annotations are a way that teams that are following a deployment job
can intervene and report results thought the job log interface in Clarive.

Annotations can contain any of the following:

- user comments
- attached files
- large log text
- others

Annotations can be created at any time during the life of the job,
although typically it's used to manage a job while it executes, adding
more data to errors, failures and other information.

#### ChatOps

Clarive talkback and ChatOps functionality can be used to report back
information into the job before, during and after its execution.

To open a ChatOps channel for discussing manual activities over the life of the
job, create a new channel in Slack with the following command:

   @cla add #job-qa-1234

Where `#job-qa-1234` is the job id from the monitor.

All commands and comments executed within the Slack chat window will be
reported back into the job.

To define authorized commands Clarive can execute, please setup `Talkback`
configuration items in Clarive that associate actions that the Clarive `@cla`
opbot can execute.
