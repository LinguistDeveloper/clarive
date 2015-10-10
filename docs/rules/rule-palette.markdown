---
title: Rule Palette
---

Operations (ops) from the palette offers the needed mechanisms to create 
rules for automation. They all have a context menu with the following fields:

###Configuration

Depending on the op it displays a window with the necessary fields to implement its target. Full information about each field will be described at the time particular op is presented.    

###Rename    

A dialog box is showed with a field to introduce the new name for the op. Its default value is the op name as it appears in the Palette. 

* **OK**: Saves any changes made and closes the dialog.
* **Cancel**: Closes the dialog. If you have made any changes since the last OK they are not saved.    

###Properties  

Operation properties are common to all operations used in a rule. After clicking this option menu a new window is raised up with an action tab and three window tabs.

Action tabs are:

* **Cancel**: To cancel all actions done since last save and close properties window.
* **Save**: Save all properties and metadata. Once properties are saved, op may include some tags to indicate some attribute values.

Windows tabs are:

* **1. Options**: Configurable parameters to run the op:    

      • *Enabled*: To activate the operation. Its defaults value is checked.    
      • *Return Key*:  Key stash defined by the user where output data is stored after op execution. Its value can be accessed through the stash in the form of:         

   `$stash->{<return_key_value>}{output}`    
      
    • *Needs Rollback?*: Rollback flag that controls whether or not to rollback in case of failure in the same pass. If an error is detected, the rollback starts. Its default value is ‘No Rollback Necessary’.  User chooses when the flag is set according to 4 options:  

           
    - *Rollback Needed After*: Flag is set after op execution.    
    - *Rollback Needed Before*: Flag is set before op execution.    
    - *Rollback Needed Always*: Flag is set at the time DSL building.    
    - *No Rollback Necessary*: Flag is not set.    

    • *Needs Rollback Key*: Related to the option above, it is a text field that is showed when the needs_rollback? option is set to a different value other than ‘No Rollback Necessary’. It defines the op to be executed in case of error.
Rollback is implemented for scripting and fileman service op.     
           

    • *Run Forward*: Run if the pass is forward.  
          
    • *Run Rollback*: Run if the pass is rollback.    

    • *Timeout*: Number of seconds for the rule to run, if timeout is reached, rule stops with a message to inform the user.    

    • *Semaphore Key*: Asks for a time slot to execute the rule. After the rule is finished the semaphore is release.    

    • *Parallel Mode*: Defines how to run rules, in terms of parallel or serially processing. Its default value is ‘No Parallel’. There are three available option:       
    
    - *No Parallel*: All ops are performed as they are located in rule.    
    - *Fork and Wait*: Rule is running in parallel way and afterwards, wait for children to finish.     
    - *Fork and Leave*: Parallel way processing but it doesn’t wait for children results.    

    • *Error Trap*: Defines how to treat op error if it occurs. Its default value is ‘No Trap’. There are three options:        

    - *No Trap*: Errors are not traped.    
    - *Trap Errors*: Trap error and wait for an user action, it can be:        

    o RETRYING: Retrying op.             
    o SKIPPING: Skipping op.            
    
    - *Ignore Errors*: Error is ignored.    

    
* **2. Metadata**: Window including op metadata, which defines op properties and behavior. It displays three columns containing:

    • *Key*: Op attribute.      
   
    • *Type*: Attribute value type, it can be:    
    
    - *Value*: Key value is a simple type.    
    - *Array*: Key value is an array.    
    - *Hash*: Key value is a hash.   
   
    • *Value*: Key value.         

Contents of this window depend on the selected type of op and the properties defined above by the user.  Following it is described common attributes to all ops when op is dragged from the palette to the rule:      
   
    • *key*: Op registered.     
   
    • *id*: Op instance id, value is in the form of ‘xnode-<number>`.    
    
    • *name*: Op name,  it is a short description of what op does.    
    
    • *text*: Its default value is the op name. This field can be changed through the rename action from op context menu.    
    
    • *icon*: Op image, describes what op does in a graphic way.    
    
    • *leaf*: Set to 0, this key indicates op holds or cand hold nested ops.   

When metadata is saved others attributes are set, they are:  
  
    • *data*: this attribute is a hash with the data from the configuration property form entered by the user.  
  
    • *data_key*: Contains the value from the return key property filled by the user. 
   
    • *disabled*: set to true if the op property ‘enable’ is not checked.    

    • *expanded*: true if op holds other ops nested.

    • *run_forward*: this attribute is showed if the user manipulate property run_forward. Set to true if the property is checked.

    • *run_rollback*: showed if the user clicks on run_rollback property. Set to true if the property is checked.

    • *parallel_mode*: Attribute that indicates the running process mode. It can have three different values:

    - *none*: Process running in serial mode.    
    - *nohup*: Process running in fork and leave mode.    
    - *fork*: Process running in fork and way mode.    

    • *error_trap*: Attribute that indicates how to trap errors. It can have three different values:    

    - *none*: no trap error,    
    - *ignored*: ignore error,    
    - *trap*: trap error waiting for an action.    

    • *semaphore_key*: Contains the semaphore name filled by the user in semaphore_key option window. 
    
    • *timeout*: attribute with the number of seconds to wait. 
    
    • *note*: Contains note tab contents. 
    
    • *qtip*: Same as note.     

Attributes depending on the type ops selected are:

    • *Statements*:      

    - *holds_children*: Indicates if op can hold other op nested inside.    

    - *nested*: If value is 0, this attribute indicates that op is the beginning of code function.    
 
    - *children*: hash holding the nested ops.        

    • *Services*:     

    • *Rules*:     

    - *id_rule*: The value of this key is the id rule number. 
   
* **3. Note**: Window including notes written by the user.    

###Note    
It displays a window including op notes entered by the user or for the user to include.

###Copy    

Copy op from rule tree area to clipboard.

###Cut   

Drops op from rule tree area to clipboard.

###Paste   

Copy op from clipboard nested to the op selected, if possible.

###DSL   

Displays a window with title DSL: `<rule name>`. An action tab and three different areas are showed in DSL window, the action tab is composed of:

* **Run**: button to run dsl code from dsl area. Areas are:

* **stash area**: Textarea with stash variables in yaml format, variables can be set by the user, it the rule to run is of type job chain, three stash variables are showed by default:

      • changesets: []    
      • elements: []    
      • job_step: CHECK    
* **dsl area**: Textarea with dsl code from op and its configuration, this code can be changed and executed.    

* **output area**: Textarea with two tab:    

* **Ouput**: Result of dsl code execution.    

* **Stash**: Stash values from dsl code execution.    

* **Toggle**: Switch op state from enable to disable and viceversa. If op is not active a line through op is displayed.    

* **Delete**: Remove op selected.    

