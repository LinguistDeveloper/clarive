---
title: Releasing
index: 400
---

Releasing a new version of an application, configuration or infrastructure
in Clarive is done by executing the given release (or changeset) topic
as a **deployment job**.

This the **job** executes a combination of all automatic and orchestrates all the
manual tasks needed to deploy a release.

## Release Strategies

Releasing can adapt to a set of strategies:

- Big-bang releases
- Gradual releases
- Stepped deployment

#### Big-Bang Releases

Deploy all of the changesets at once in a single job.

This is the best strategy for production environments, because it makes changes
"transactional".  This means Clarive guarantees that it can rollback the full
job in case of failure.

To implement big-bang releases:

- Add "Bind Releases" in the Status CI where you want to avoid deploying
  gradual changesets, ie. `Production` status.
- Develop a job pipeline rule that takes full advantage of job rollback
  strategies.
- If necessary, add manual deployment ops to your deployment rule: approvals,
  pauses, etc.

#### Gradual Releases

Gradual releases mean to deploy changesets individually
into an environment.

This strategy is typically better suited for preproduction environments.
The main advantages is that we can *cherry pick* releases that are going
to be deployed into an environment.

#### Stepped Deployment

This means that the gradual release steps are implemented through pauses, traps
or approvals during the deployment job.

We recommend using stepped deployment if it the release execution not going to
take more than 24h.

Having a job running for over 24h means having the job processes taking up
resources in the Clarive server (and related targets).

### Calendaring

To schedule release deployments, Clarive uses its calendaring engine
to process what can be deployed when. Use the `Calendaring` admin interface
to define available job slots by any scope or job content:

- Global schedule
- Environment-based slots
- Specific dates (ie. holidays) exceptions
- Project or CI based calendar slots.

### Release Infrastructure Relationship

Releases and changesets hold relationship to CIs in the Clarive graph. This
allows, for instance, to identify which releases may be affected by certain
infrastructure outage.

To use the CI Graph dashlet, add it to the release topic category dashboard:

1) create a new Dashboard rule in the `Rule Designer` and add the `CI Graph`
dashlet from the `Palette` 2) open the `Admin Topics` administration panel 3)
select the release topic 4) add the dashboard created in step 1 to the
`Dashboard` field

Once you open the release topic, the user can drill down through the related
CIs, including infrastructure, for a given environment or project for that
release.

#### Deployment Infrastructure

Infrastructure that's going to be needed for deploying a release
is also available when creating a `New Job`.

### Redeploying a Release

If a release fails, or the environment is rebuilt from the
outside, a release can be redeployed to that environment using
either of the following:

- Job rerun
- Creating a new deploy transition into the environment

Either way, release will be redeployed to the environment.

#### Job Rerun

By rerunning the job through the `Job Monitor`, the same variables and
values used in each step will be reused. That means the same version
of the configuration is going to be deployed to the environment.

A Job Rerun also allows the user to control which job step is going
to be re-executed. This allows users to rerun only the `RUN` phase
of the job.

#### Static Redeploy

If the release is already in an environment, and the
transition from and to the status exists in the workflow
for the release with **job type** `static`, then Clarive
can redeploy a release to an environment where it is already
installed.

To setup static redeploys, edit the workflow for the topic category:

- If it's a simple workflow, head over to the `Admin Topic` panel
to add a workflow transition with Job Type `static` from and to the
same status (ie. from QA to QA).
- If it's a rule workflow, modify the workflow rule so that it has
a transition from and to the same status, set as Job Type `static`.

### Provision / Decommission Configuration

Using catalog repositories, users can add provisioning tasks to a
release changesets.

Provisioning is executed when the rule executes. Make sure the
rule has a `Run Provision Tasks` operation configured at some point,
otherwise no provisioning tasks will be executed.

A good strategy for setting up provisioning during the release process is to
setup the deployment during a `PRE` job step operation to deploy provisioned
tasks *before* the scheduled time (`RUN` step).

### Federation After Deployment

Federate important application configuration information with external
CMDBs if you have one.

Add webservices and federation calls to your deployment
rule that will federate the configuration changes deployed
by your last deployment job.
