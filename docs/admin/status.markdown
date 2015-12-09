---
title: Status Administration
---

* Clarive can support any number of states, and states can be used by any number of topics.

* Status administration is be performed by selecting the Configuration items button from the left explorer window.

* This will display the configuration items tree structure in the left pane.

* The following actions buttons are available above the list of Status: <br />

&nbsp; &nbsp;• Search for all states containing the search string entered <br />

&nbsp; &nbsp;• Delete the selected Status: All the Status that have their checkbox selected will be deleted.  <br />

&nbsp; &nbsp;• Import/Export low-level configuration data of the selected Status: <br />

* When clicking on the export button, low-level configuration data can be exported in YAML, JSON, HTML and CSV formats
by clicking on the symbol YAML and CSV formatted data can be imported. 

* This is handy for sharing and exchanging of states information.

<br />
### <img src="/static/images/icons/add.gif" /> Create a new Status 

* The following information needs to be provided for creation: <br />

&nbsp; &nbsp;• `Name`: Name of the status <br />
&nbsp; &nbsp;• `Description`: Long description of the status <br />
&nbsp; &nbsp;• `Active`: The status is active and can be used for topics <br />
&nbsp; &nbsp;• `Moniker`: Alternate unique key of the status <br />
&nbsp; &nbsp;• `BLs`: Environment in which topics can have the status <br />
&nbsp; &nbsp;• `Sequence`: A number allowing to sort the order in which status’s will be shown <br />
&nbsp; &nbsp;• `Bind Releases`: Indicating whether Changesets will be bound to a release in this status <br />
&nbsp; &nbsp;• `View in Tree`: Option to see all topics in this state in Clarive project tree explorer.

<br />
#### **Types of status**
<br />
&nbsp; &nbsp;• `General`: By default, not special treatment. <br />
&nbsp; &nbsp;• `Initial`: Status initial from a category, any new topic from that category will have this state <br />
&nbsp; &nbsp;• `Deployable`: Status and target status from workflow will appear in the project tree explorer <br />
&nbsp; &nbsp;• `Cancelled`: A Final status and unsuccesful end , topics are not in progress anymore. <br />
&nbsp; &nbsp;• `Final`: A Final status and unsuccesful end , topics are not in progress anymore <br />
&nbsp; &nbsp;• `Color`: Color the topics in this state will be displayed in  <br />
&nbsp; &nbsp;• `Icon Path`: To display defined icon in status menu. <br />

