---
title: Environment
index: 5000
icon: add
---

In DevOps, an environment typically is defined as a place
where we deploy changes to. But to be more thorough,
we can say an environment is a logical grouping of
configuration items or resources.

### Environment CI

In Clarive, an environment is itself a CI. Create a new CI
and you are creating an environment.

### How do I configure the contents of an environment?

This is mostly done 2 ways:

- For each CI we create we can set to what environment it belongs. Some
CIs don't support this, like the Project CI; others like GenericServer do.
- For every scope, or project, we can define which CIs belong
to a given environment for that scope in particular.

### Environment Naming

DEV, TEST, QA, PRE, PREP (preproduction), PRO, PROD (production)
are all names of environments often used. By convention, we
propose name of environments be limited from 2 to 4 letters all
caps.

### The Common (*) Environment

The Common environment is a special
environment in Clarive that holds
CIs, resources and variables that are common to
every environment or that are not specific to
any environment.

For example, these CIs:

- a GenericServer class CI may be available to all environments or to
just a few. So here the common environment means **ALL**.
- a GitRepository CI may be assigned to the Common environment, but
actually means **NONE**, since a source code repository does not have the
concept of environment itself (ie. you don't create one Git repository
to every environment).

### Legacy: Baseline and a bl

Older versions of Clarive had the
concept of a "bl", which translated as baseline
but actually its meaning is environment.

Internally, environment is stored with the name `bl`, and
so it's visible that way in YAML files and others places.
