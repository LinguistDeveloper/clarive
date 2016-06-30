---
title: Deployment Scaling
index: 230
---

Deployment sometimes cannot be neither a big-bang delivery of changes
nor they are filled with manual steps. They need a phased process.

Clarive supports different ways to scale deployments.

- Partial deployments
- Rolling and phased
- Canary and hot, blue, green, dark launch modes

### Blue-Green Deployment

Blue-green deployment scaling strategy is a type of active-passive target
deployment where one node is being deployed to (passive) while the other,
active node, is live.

To implement blue-green deployments, use either methods:

- Paused deployment (preferred)
- Blue-green Environments

Combined with a set of rule ops that change the active and passive node roles
(ie. by stopping and starting processes in each server or cluster).

#### Paused Deployment

Using a `Pause` op in the rule will stop deployment after the passive node has
been deployed to. After verifying the node, the rule op will switch passive-active
nodes and continue deploying.

#### Blue-Green Environments

One environment is Blue and another is Green, such as a PROD-GREEN and
PROD-BLUE environments.

Environments can inherit from a parent environment, so the only difference in
between them should be the target servers where one is deployed to.

This method permits a longer phased release to run in 2 different jobs.

### Dark Launch and Feature Toggles

Dark launching and feature toggle is a scaled deployment strategy
that involves setting up an *application specific* switch that can activate a
feature only to a certain group of users, geographies, etc.

Although Clarive is not actually part of a feature toggle mechanism, since
it should be application internal, there are several Clarive features that
support *externally* implementing dark launch in a application:

- Variable parsing in config files
- Conditional building and conditional deploy

An external dark launch strategy means that it is Clarive who
takes care of turning the feature switch on/off in your application
for a certain environment or conditional variable in the build or deployment
process.

#### Variable Parsing for Dark Launching

Setup a config file with optional values, then use a
deployment rule logic that activates the feature:

    FOREACH deployment_node
        DEPLOY artifact
        IF node = activated_feature THEN
            SET feature_toggle = ON
            PARSE config file
            DEPLOY config to node
        ELSE
            DEPLOY config to node

Here's the config file contents, before Clarive will parse
the variables:

    show_feature = ${feature_toggle}

#### Conditional Build and Deploy

Dark launches can be also controlled by conditional build
options in the pipeline rules. That way, rules
will build or deploy the feature according to the
target.

    IF node = active_feature THEN
        DEPLOY artifact_v1
    ELSE
        DEPLOY artifact_v2

### Canary

Canary deployments are a scaled and *tested* deployment strategy.

The recommended way is to configure a Canary environment and statuses to deploy
to:

- Create environments `PROD-CANARY` and `PROD`, then deploy to `PROD-CANARY`
  first.
- After deployment, trigger tests
- Move release to failed environment

### Hot Deployment

Clarive supports hot-deploying to servers. Hot-deploying means
that the application will not have any disruptions before, during or after
deploying a new version.

Usually it depends on the technology being targeted by the deploy.

For example, JBoss, WebSpehere® and Weblogic® application servers all support
a hot deploy mode.


