---
title: Managing Status
index: 5000
icon: state
---

A given topic has different statuses, and one single status can be used by any number of topics.

Status administration is performed by selecting the Configuration items button in the explorer panel in the left.

This will display the configuration items tree structure in the left panel.

The following actions buttons are available above the list of Status:

- Search for all status containing the search string entered
- Delete the selected Status: All the Status that have their checkbox selected will be deleted.
- Import/Export low-level configuration data of the selected Status:

When clicking on the export button, low-level configuration data can be exported
in YAML, JSON, HTML and CSV formats by clicking on the symbol YAML and CSV formatted data can be imported.

This is handy for sharing and exchanging of status information.

### <img src="/static/images/icons/add.svg" /> Create a new Status

The following information needs to be provided for creation:

- `Name` - Name of the status
- `Description` - Long description of the status
- `Active` - The status is active and can be used for topics
- `Moniker` - Alternate unique key of the status
- `BLs` - Environment in which topics can have the status
- `Sequence` - A number allowing to sort the order in which status’s will be shown
- `Bind Releases` - Indicating whether Changesets will be bound to a release in this status
- `View in Tree` - Option to see all topics in this status in Clarive project tree explorer.


#### **Types of status**

- `General` - By default, not special treatment.
- `Initial` - Status initial from a category, any new topic from that category will have this status.
- `Deployable` - Status and target status from workflow will appear in the project tree explorer
- `Cancelled` - A Final status and unsuccesful end , topics are not in progress anymore.
- `Final` - A Final status and unsuccesful end , topics are not in progress anymore
- `Color` - Color the topics in this status will be displayed in
- `Icon Path` - To display defined icon in status menu.