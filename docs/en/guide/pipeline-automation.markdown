---
title: Release Pipeline Automation
index: 800
---

Release Pipeline Execution Clarive rules can support 3 key phases in the
delivery process: PRE, RUN, POST. During the PRE phase, the PREparation for
delivery steps are documented and automated. During this phase, typically the
following actions are modeled:

- Environment building/provisioning
- Binary building: compilation from associated revisions across the various
  platforms

Upon completing the build step, the RUN step takes place, this is when the
system starts operating within the job schedules (release windows) for each
environment. During this phase, depending on the various natures/types of
binaries, executables and data is placed onto the right target environments.
This is done either through SSH, Clarive Push or Pull agents, depending on
customer topology and architectural constraints.

During the POST phase, Clarive can orchestrate the post deployment activities,
such as cleanups, CMDB updates etc.

A Clarive rule makes use on environment variables. These variables have
specific content for each environment and allow the SAME deployment rule to be
used across every environment and platform.

This capabilty allows Clarive to be used to validate and test the deployment
logic (just as code) across every environment. Clarive allows organisations to
test the build, deploy, provision, and test logic across every environment from
a SINGLE rule. On top of that every rule is governed by version control and
change tracking, which provides extra value for agility and control.

During rule definition, Clarive allows the rule designer to define and document
the rollback strategy per line entry at the same time.

## Pipeline Recreation

Pipeline recreation is the ability to rerun a deployment using
a previous version of environment models and overall rule logic.

To recreate a previous version, select the `Rule Version` in the `New Job`
panel. By default the rule version is always the latest.

### Tagging Versions

To know what configuration versions are best, just tag
the rule versions in the `Rule Designer` interface, under the
version button for the rule.

### Pipeline Version Storage

Versions are stored in the system according to the capped collection
size `rule_version`. Just modify the capped collection size
to hold more or less configuration versions, according to your storage
available and organizational policies.

### Job Version Snapshot

Clarive automatically stores snapshots of the job contents that was used
to deploy a release to production environments, just set the `Snapshot Environment`
checkbox in the Environment CI of your production environment.
