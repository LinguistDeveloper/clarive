---
title: Project
index: 5000
icon: project
---

A Project is the most common Clarive security [scope](concepts/scope).

A Clarive project is a collection of [topics](concepts/topic), and is defined according to your organization's
requirements. For example, a Clarive project could be:

- A software development project.
- A system.
- A group of software components.
- Or, more commonly, an application.

Topics can belong to none, one or more projects, but that is not a requirement. For example, Changeset topics must
belong to one, and only one, project.

Releases on the other hand may be multi-project or have no projects.

## Project Variables

Every project can have a set of variables with values set specifically for that project. Moreover for every
[Environment](concepts/environment), different values can be set.

### Copying variables between Environments

Setting variables can be a cumbersome process, and it is very common for different environments to have the same
variables but with different values. That is where Copying vars to another environment can be a real help. If the
variable has a Copy flag (see [Variable](concepts/variable) for more info) it is copied with the current value.
