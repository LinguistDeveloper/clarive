---
title: Rule Palette
---

* Operations (ops) from the palette offers the needed mechanisms to create 
rules for automation. They all have a context menu with the following fields:

<br />
###Configuration

* Depending on the op it displays a window with the necessary fields to implement its target. Full information about each field will be described at the time particular op is presented.

<br />
###Rename    

* A dialog box is showed with a field to introduce the new name for the op. Its default value is the op name as it appears in the Palette. <br />

&nbsp; &nbsp;• **OK**: Saves any changes made and closes the dialog. <br />
&nbsp; &nbsp;• **Cancel**: Closes the dialog. If you have made any changes since the last OK they are not saved.

<br />
###Properties  

* Operation properties are common to all operations used in a rule. After clicking this option menu a new window is raised up with an action tab and three window tabs.

* Action tabs are: <br />

&nbsp; &nbsp;• **Cancel**: To cancel all actions done since last save and close properties window. <br />
&nbsp; &nbsp;• **Save**: Save all properties and metadata. Once properties are saved, op may include some tags to indicate some attribute values.

<br />

* Windows tabs are:

&nbsp; &nbsp;• **1. Options**: Configurable parameters to run the op: <br /><br />
        &nbsp; &nbsp;&nbsp; &nbsp;• *Enabled*: To activate the operation. Its defaults value is checked. <br />
        &nbsp; &nbsp;&nbsp; &nbsp;• *Return Key*:  Key stash defined by the user where output data is stored after op execution. Its value can be accessed through the stash in the form of:

             $stash->{<return_key_value>}{output}

<br /> <br />
        &nbsp; &nbsp;&nbsp;&nbsp;• *Needs Rollback?*: <br /><br />
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; • Rollback flag that controls whether or not to rollback in case of failure in the same pass. <br />
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; • If an error is detected, the rollback starts.  <br />
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; • Its default value is *‘No Rollback Necessary’*. <br />
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; • User chooses when the flag is set according to 4 options:<br />
        <br /><br />
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; • *Rollback Needed After* - Flag is set after op execution. <br />
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; • *Rollback Needed Before* - Flag is set before op execution.<br />
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; • *Rollback Needed Always* - Flag is set at the time DSL building.<br />
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; • *No Rollback Necessary* - Flag is not set.<br />
     
<br /><br />
        &nbsp;&nbsp;&nbsp; &nbsp;• *Needs Rollback Key*: Related to the option above, it is a text field that is showed when the `needs_rollback?` option is set to a different value other than ‘No Rollback Necessary’. It defines the op to be executed in case of error. Rollback is implemented for scripting and fileman service op.  <br /><br />
        &nbsp;&nbsp;&nbsp;&nbsp;• *Run Forward*: Run if the pass is forward. <br /><br />
        &nbsp;&nbsp;&nbsp;&nbsp;• *Run Rollback*: Run if the pass is rollback. <br /><br />
        &nbsp;&nbsp;&nbsp;&nbsp;• *Timeout*: Number of seconds for the rule to run, if timeout is reached, rule stops with a message to inform the user. <br /><br />
        &nbsp;&nbsp;&nbsp;&nbsp;• *Semaphore Key*: Asks for a time slot to execute the rule. After the rule is finished the semaphore is release. <br /><br />
        &nbsp;&nbsp;&nbsp;&nbsp;• *Parallel Mode*: Defines how to run rules, in terms of parallel or serially processing. Its default value is ‘No Parallel’. There are three available option:
    <br /><br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• *No Parallel* - All ops are performed as they are located in rule.<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• *Fork and Wait* - Rule is running in parallel way and afterwards, wait for children to finish. <br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• *Fork and Leave* - Parallel way processing but it doesn’t wait for children results.<br />
    <br /><br />
    &nbsp; &nbsp;&nbsp;&nbsp;&nbsp; &nbsp;• *Error Trap*: Defines how to treat op error if it occurs. Its default value is ‘No Trap’. There are three options: <br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• *No Trap* - Errors are not traped.<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• *Trap Errors* - Trap error and wait for an user action, it can be:<br /><br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Retrying - Retrying op. <br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Skipping - Skipping op. <br />
     <br /><br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;• *Ignore Errors*: Error is ignored.

<br />

&nbsp; &nbsp;• **2. Metadata**: Window including op metadata, which defines op properties and behavior. It displays three columns containing: <br /><br />
    &nbsp; &nbsp;&nbsp; &nbsp;• **Key**: Op attribute. <br />
    &nbsp; &nbsp;&nbsp; &nbsp;• **Type**: Attribute value type, it can be: <br />
    &nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp;• *Value* - Key value is a simple type.<br />
    &nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp;• *Array* - Key value is an array.<br />
    &nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp;• *Hash* - Key value is a hash.<br />
    &nbsp; &nbsp;&nbsp; &nbsp;• **Value**: Key value.
<br />

&nbsp; &nbsp;• Contents of this window depend on the selected type of op and the properties defined above by the user.  Following it is described common attributes to all ops when op is dragged from the palette to the rule: <br /><br />
    &nbsp; &nbsp;&nbsp; &nbsp;• `Key` - Op registered. <br /><br />
    &nbsp; &nbsp;&nbsp; &nbsp;• `ID` - Op instance id, value is in the form of `xnode-*number*`. <br /><br />
    &nbsp; &nbsp;&nbsp; &nbsp;• `Name` - Op name,  it is a short description of what op. <br /><br />
    &nbsp; &nbsp;&nbsp; &nbsp;• `Text` - Its default value is the op name. This field can be changed through the rename action from op context menu. <br /><br />
    &nbsp; &nbsp;&nbsp; &nbsp;• `Icon` - Op image, describes what op does in a graphic way. <br /><br />
    &nbsp; &nbsp;&nbsp; &nbsp;• `Leaf` - Set to 0, this key indicates op holds or cand hold nested ops.

<br /><br />

&nbsp; &nbsp;• When metadata is saved others attributes are set, they are: <br /><br />
    &nbsp; &nbsp;&nbsp; &nbsp;• `Data` - This attribute is a hash with the data from the configuration property form entered by the user.  <br /><br />
    &nbsp; &nbsp;&nbsp; &nbsp;• `Data_key` - Contains the value from the return key property filled by the user. <br /><br />
    &nbsp; &nbsp;&nbsp; &nbsp;• `Disabled` - Set to true if the op property ‘enable’ is not checked. <br /><br />
    &nbsp; &nbsp;&nbsp; &nbsp;• `Expanded` - True if op holds other ops nested. <br /><br />
    &nbsp; &nbsp;&nbsp; &nbsp;• `Run_forward` - This attribute is showed if the user manipulate property run_forward. Set to true if the property is checked. <br /><br />
    &nbsp; &nbsp;&nbsp; &nbsp;• `Run_rollback` - Showed if the user clicks on run_rollback property. Set to true if the property is checked. <br /><br />
    &nbsp; &nbsp;&nbsp; &nbsp;• `Parallel_mode` - Attribute that indicates the running process mode. It can have three different values: <br /><br />
    &nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp;• *None*: Process running in serial mode. <br />
    &nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp;• *Nohup*: Process running in fork and leave mode. <br />
    &nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp;• *Fork*: Process running in fork and way mode.  <br /><br />
    &nbsp; &nbsp;&nbsp; &nbsp;• `Error_trap` - Attribute that indicates how to trap errors. It can have three different values: <br />
    &nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp;• *None*: No trap error. <br />
    &nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp;• *Ignored*: Ignore error. <br />
    &nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp;• *Trap*: Trap error waiting for an action.<br /><br />
    &nbsp; &nbsp;&nbsp; &nbsp;• `Semaphore_key` - Contains the semaphore name filled by the user in semaphore_key option window.  <br /><br />
    &nbsp; &nbsp;&nbsp; &nbsp;• `Timeout` - Attribute with the number of seconds to wait. <br /><br />
    &nbsp; &nbsp;&nbsp; &nbsp;• `Note` - Contains note tab contents. <br /><br />
    &nbsp; &nbsp;&nbsp; &nbsp;• `Qtip` - Same as note.


<br /><br />

&nbsp; &nbsp;• Attributes depending on the type ops selected are: <br /><br />
    &nbsp;&nbsp;&nbsp; &nbsp;• `Statements`  <br /><br />
    &nbsp;&nbsp;&nbsp; &nbsp;&nbsp; &nbsp;• *Holds_children*: Indicates if op can hold other op nested inside.  <br />
    &nbsp;&nbsp;&nbsp; &nbsp;&nbsp; &nbsp;• *Nested*: If value is 0, this attribute indicates that op is the beginning of code function.  <br /><br />
    &nbsp;&nbsp;&nbsp; &nbsp;&nbsp; &nbsp;• *Children*: Hash holding the nested ops.  <br /><br />
    &nbsp;&nbsp;&nbsp; &nbsp;• `Services`  <br /><br />
    &nbsp;&nbsp;&nbsp; &nbsp;• `Rules`  <br /><br />
    &nbsp;&nbsp;&nbsp; &nbsp;&nbsp; &nbsp;• *Id_rule*: The value of this key is the id rule number.

<br />

&nbsp; &nbsp;• **3. Note**: Window including notes written by the user.

<br />
###Note    
* It displays a window including op notes entered by the user or for the user to include.

<br />
###Copy    

* Copy op from rule tree area to clipboard.

<br />
###Cut   

* Drops op from rule tree area to clipboard.

<br />
###Paste   

* Copy op from clipboard nested to the op selected, if possible.

<br />
###DSL   

* Displays a window with title DSL: `<rule name>`. An action tab and three different areas are showed in DSL window, the action tab is composed of:<br />

&nbsp; &nbsp;• **Run**: button to run dsl code from dsl area. Areas are: <br /> 

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• *Stash area*: Textarea with stash variables in yaml format, variables can be set by the user, it the rule to run is of type job chain, three stash variables are showed by default:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• changesets: [] <br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• elements: [] <br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• job_step: CHECK <br />

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• *Dsl area*: Textarea with dsl code from op and its configuration, this code can be changed and executed.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• *Output area*: Textarea with two tab <br /><br />

&nbsp;&nbsp;• **Ouput** - Result of dsl code execution.

&nbsp;&nbsp;• **Stash** - Stash values from dsl code execution.

&nbsp;&nbsp;• **Toggle** - Switch op state from enable to disable and viceversa. If op is not active a line through op is displayed.

&nbsp;&nbsp;• **Delete** - Remove op selected.

