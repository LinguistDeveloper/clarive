---
title: Environment Loading and Discovery
index: 120
---

To create and map all the CIs needed to
finalize the environment model for a Clarive implementation
we recommend doing any of the following activities:

- Probe and discover infrastructure using rules
- Load CIs from a database or spreadsheet
- Duplicate configuration from/to current models

### Discovery

To discover environments, use Clarive's probe operations
to setup discovery logic that will detect and load infrastructure
resources from your network.

Steps:

- create a new rule of type `Action` and select where the
action will be available.
- add probe operations that suit the type of CIs you
wish to discovery. Probe operations available depend
on the plugins and features installed at your installation.

### Loading CIs

Loading CIs into Clarive can be done in 2 ways:

- Importing CSV, YAML or JSON file
- Calling a webservice

#### Importing from file

Use the `Import` menu option of each CI grid available
to import info.

#### Calling a Clarive Webservice

Calling into the Clarive API using a webservice is
another method of loading (and updating) CIs in the system.

Write a webservice rule in the `Rule Designer` to create
and load CIs.


