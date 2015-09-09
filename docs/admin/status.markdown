---
title: Status Administration
---

Clarive can support any number of states, and states can be used by any number of topics.

Status administration is be performed by selecting the Configuration items button from the left explorer window.

This will display the configuration items tree structure in the left pane.

The following actions buttons are available above the list of Status:

- Search for all states containing the search string entered

- Delete the selected Status: All the Status that have their checkbox selected will be deleted. 

- Import/Export low-level configuration data of the selected Status:

When clicking on the export button, low-level configuration data can be exported in YAML, JSON, HTML and CSV formats
by clicking on the symbol YAML and CSV formatted data can be imported. 

This is handy for sharing and exchanging of states information.

### Create a new Status: The following information needs to be provided for creation:

- `Name` : name of the status
- `Description` : Long description of the status
- `Active` : The status is active and can be used for topics
- `Moniker` : alternate unique key of the status
- `BLs` : environment in which topics can have the status
- `Sequence` : a number allowing to sort the order in which status’s will be shown
- `Bind Releases`: indicating whether Changesets will be bound to a release in this status
- `View in Tree` : option to see all topics in this state in Clarive project tree explorer
- `Type` :
    - `General` : By default, not special treatment.
    - `Initial` : Status initial from a category, any new topic from that category will have this state
    - `Deployable` : status and target status from workflow will appear in the project tree explorer
    - `Cancelled` : A Final status and unsuccesful end , topics are not in progress anymore.
    - `Final` : A Final status and unsuccesful end , topics are not in progress anymore
    - `Color` : Color the topics in this state will be displayed in 
    - `Icon Path` : To display defined icon in status menu.

