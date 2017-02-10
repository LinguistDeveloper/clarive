---
title: Project Pipeline
---

The project pipeline dashlet shows how
releases and changesets are distributed in the different
environments.

#### Mode

- `Release` - group dashlet content by releases
- `Changeset` - group dashlet content by changesets
- `Revision` - group dashlet content by revision

#### Environments

Select which environment columns to show (or hide).

- `Exclude Selected Environments` - negate the selected environments
so they are hidden.

#### Select topics in categories

Select the topic categories to include.

This is a way to select a subset of changeset and releases to be shown in each
case.

#### Advanced JSON/MongoDB condition for filter

This is a space for an additional MongoDB filter to be added, which
will be applied to the topic.

#### Label Mask

This is the text shown in each of the releases or changesets listed.

The variables available are:

- `${category.name}`
- `${category.acronym}`
- `${category.color}`
- `${topic.mid}`
- `${topic.title}`
- `${topic.[field name here]}`

