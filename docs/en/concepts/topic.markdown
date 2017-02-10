---
title: Topic
index: 5000
icon: topic
---

The topic is Clarive's central delivery lifecycle entity.

Clarive is not just about the technical components put in releases.
Organizations that use Clarive manage logical "documents" called *topics* that
handle the different aspects of their delivery process. This may include
different types of releases, sprints, etc.  these documents have workflows
which can represent many different LOGICAL states changes are attached to these
topics. They also have fields, with role-based security and actions.

A **topic category** is an organization-defined form instance that has an
associated [workflow](concepts/workflow).  Think of it as a template.

A **topic** is an instance of the topic category, that has an assigned
[mid](concepts/mid).

### Topic Category

Every topic category in Clarive can have any number
of fields, a workflow with statuses and transition rules or constraints, as
well as dashboards for context filitered insight and reporting.

A topic category typically has the following properties:

-  A set of statuses
-  A workflow
-  A form rule, with its defined fieldlets
-  Field-level security
-  Transition-level security: which user/roles can transition a topic from one status to the next
-  A color, to visually represent
-  An acronym, to easily represent the topic category name
-  A discussion

Some topic categories may be:

-  Release
-  Changeset
-  Issue
-  Bug or Defect
-  Test Case
-  Estimation
-  Request
-  Sprint
-  User Story
-  Product Backlog

Changesets, and any other topics, can be grouped into releases. Having topics
grouped in releases is the key to full-fledged orchestration of the delivery
lifecycle.

### Why topics?

We believe that every installation must have full control
over how their process is defined. So having standard, out-of-the-box
entities in a delivery lifecycle tool actually interferes with the
ground-up thinking that is needed to have the most adapted process.

Topics are great for both brownfield and greenfield implementations,
as they can ajust and adapt to existing processes, but also help define
new, unconstrained processes that can best represent the organization needs.
