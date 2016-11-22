---
title: Rule Menu
icon: rule
---

The way to access rule stuff is through admin menu. Selecting **Admin → Rules**
a new tab appears with three different areas. From left to right:

### Rules grid area

Area with two columns and an action tab:

- **Rule**:  Rule id, rule name and rule type.
- **Time**:  Last modification time.

### Actions

Actions defined are:

<img src="/static/images/icons/search-small.svg" />**Search field**: To find rules
names according to the mask typed in search field, it list till 30 rules.

<img src="/static/images/icons/refresh.svg" /> **Refresh**: To refresh the list of rules.

<img src="/static/images/icons/add.svg" /> **Create**: Use to start a configure a new rule.

<img src="/static/images/icons/edit.svg" /> **Edit**: Edit selected rule.

<img src="/static/images/icons/delete.svg" /> **Delete**: Delete selected rule.

<img src="/static/images/icons/catalog-folder.svg" /> **Workflow**: Organise the rules based on the type.

<img src="/static/images/icons/restart_new.svg" /> **Activate**: Activate selected rule.

<img src="/static/images/icons/wrench.svg" /> **Tools**: <img src="/static/images/icons/import.svg" />
Import or <img src="/static/images/icons/export.svg" /> Export the rule to other Clarive system
in YAML format.

### Rule tree

Area where selected rule is displayed as a tree, it has an **action tab with some operations**,
they are:

<img src="/static/images/icons/search-small.svg" /> **Search field**: To find field names
according to the mask typed in search field.

<img src="/static/images/icons/refresh.svg" /> **Refresh**: To refresh the rule

<img src="/static/images/icons/save.svg" /> **Save**: To save rule.

<img src="/static/images/icons/edit.svg" /> **DSL**: Raises up a new window with DSL code
from the rule selected. This code can be executed. This functionality will be described in the
[rule palette](rules/rule-palette) page.

<img src="/static/images/icons/wrench.svg" /> **Tools**:

- <img src="/static/images/icons/import.svg" /> **Import YAML**: Import rule from
YAML.
- <img src="/static/images/icons/import.svg" /> **Import From File**: Import rule
from a file.
- <img src="/static/images/icons/downloads_favicon.svg" /> **Export YAML**: Export
rule in YAML format.
- <img src="/static/images/icons/downloads_favicon.svg" /> **Export to File**: Export
rule to a file.


### Some additional options

**Regular expression**: Allow to search a regular expression.

**Ignore case**: Activate/Desactivate case sentitive to search text.

**Blame by time**: Mark the changes in the elements by a specific period of time.

<img src="/static/images/icons/expandall.svg" /> **Expand all**: Expands every
single rule in any job step.

<img src="/static/images/icons/collapseall.svg" /> **Collapse all**: Collapse every
rule and step, just viewing start point.

<img src="/static/images/icons/history.png" /> **Version**: Expands all history versions from
the rule selected. The output shows date, time and user who saved the rule.

<img src="/static/images/icons/views.svg" /> **Views**:

- <img src="/static/images/icons/html.svg" /> **HTML**: Displays in another navigator tab,
op properties values and configuration from every op included in the selected rule.
- <img src="/static/images/icons/workflow.svg" /> **Flowchart**: Displays tree of the rule

Every op is indented as it is built in rules.

### Palette

Contains all operations (ops) that can be used for rule composition.

It has an action tab with two action:

<img src="/static/images/icons/search-small.svg" /> **Search**: To find a rule with a mask as input.

<img src="/static/images/icons/refresh.svg" /> **Refresh**: To refresh the palette