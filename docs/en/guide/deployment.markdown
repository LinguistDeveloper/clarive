---
title: Deployment
index: 200
---

Clarive implements quite a hefty amount of useful features for continuous and
discrete deployment modes. Clarive deploys revisions from change providers.
Change providers typically are code or artifact repositories (ie. Git,
Subversion, Nexus) but could also be Salesforce or a database.

As part of implementing automated deployment at your organization, you must
plan for the following:

#### Applications

Select a set of target applications for this implementation

#### Technologies ("Natures")

Define the technologies that will be deployed (from a set of target
applications or services)

In Clarive, these are called natures.

#### Deployment and Rollback Logic

Collect all information on current automation logic being used, or manual
processes in place.

With this information at hand, you'll be ready to write automation rules.

#### Resources (CIs)

Determine all resources and environments used by the target applications and
natures for each configuration environment.

Write environment models for the patterns implemented at your organization.
This will help later with onboarding new applications as they join the
automated delivery flow implemented in Clarive.

## Deploying Topics

Clarive deploys topics. Topics contain the revisions to the configuration being
deployed. Clarive can deploy 2 types of topics:

- Changesets
- Releases

The way how releases are packaged can vary by application type and
organizational methodologies. Clarive supports top-down as well as bottom-up
release management and packaging. This way Clarive can support both traditional
as well as agile methods.

### Deploying Changesets

Clarive has multiple ways to "package" builds and deployments. The first type
is a Changeset where various revisions, which can come from ANY revision
repository, can be related/linked into. Once within a Changeset, anyone with
the right permission can click on the revision link and can see the revision
details straight from within Clarive, there is no need to go out of the tool.

Changesets can be build and deployed triggered by a status change, a job run,
or an internal or external event. Based on the different natures within the
associated revision, the build (and/or deployment) rule will execute the
appropriate actions to build, stage, test and/or deploy to the correct
environment.

### Deploying Releases

Clarive also has another way to "package" builds and deployments: a
release-type topic. This type allows changesets or releases to be combined
into another level of logical packaging. When such a "release" is build and/or
deployed, then Clarive will perform the operation for all revisions that are
part of the release, at any level further down in the hierarchy.

This way any type of composition can be formed and managed.

Changeset and Release are just 2 examples of possible discussion topics part of
application delivery, but can define as many as required to orchestrate the
delivery process as needed.

