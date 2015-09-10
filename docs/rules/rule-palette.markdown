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

      &nbsp; &nbsp; • *Enabled*: To activate the operation. Its defaults value is checked.    
      &nbsp; &nbsp; • *Return Key*:  Key stash defined by the user where output data is stored after op execution. Its value can be accessed through the stash in the form of:         

   `$stash->{<return_key_value>}{output}`    
      
    &nbsp; &nbsp; • *Needs Rollback?*: Rollback flag that controls whether or not to rollback in case of failure in the same pass. If an error is detected, the rollback starts. Its default value is ‘No Rollback Necessary’.  User chooses when the flag is set according to 4 options:  

           
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - *Rollback Needed After*: Flag is set after op execution.    
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - *Rollback Needed Before*: Flag is set before op execution.    
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - *Rollback Needed Always*: Flag is set at the time DSL building.    
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - *No Rollback Necessary*: Flag is not set.    

    &nbsp; &nbsp; • *Needs Rollback Key*: Related to the option above, it is a text field that is showed when the needs_rollback? option is set to a different value other than ‘No Rollback Necessary’. It defines the op to be executed in case of error.
Rollback is implemented for scripting and fileman service op.     
           

    &nbsp; &nbsp; • *Run Forward*: Run if the pass is forward.  
          
    &nbsp; &nbsp; • *Run Rollback*: Run if the pass is rollback.    

    &nbsp; &nbsp; • *Timeout*: Number of seconds for the rule to run, if timeout is reached, rule stops with a message to inform the user.    

    &nbsp; &nbsp; • *Semaphore Key*: Asks for a time slot to execute the rule. After the rule is finished the semaphore is release.    

    &nbsp; &nbsp; • *Parallel Mode*: Defines how to run rules, in terms of parallel or serially processing. Its default value is ‘No Parallel’. There are three available option:       
    
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - *No Parallel*: All ops are performed as they are located in rule.    
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - *Fork and Wait*: Rule is running in parallel way and afterwards, wait for children to finish.     
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - *Fork and Leave*: Parallel way processing but it doesn’t wait for children results.    

    &nbsp; &nbsp; • *Error Trap*: Defines how to treat op error if it occurs. Its default value is ‘No Trap’. There are three options:        

    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - *No Trap*: Errors are not traped.    
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - *Trap Errors*: Trap error and wait for an user action, it can be:        

    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; o RETRYING: Retrying op.             
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; o SKIPPING: Skipping op.            
    
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - *Ignore Errors*: Error is ignored.    

    
* **2. Metadata**: Window including op metadata, which defines op properties and behavior. It displays three columns containing:

    &nbsp; &nbsp; • *Key*: Op attribute.      
   
    &nbsp; &nbsp; • *Type*: Attribute value type, it can be:    
    
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - *Value*: Key value is a simple type.    
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - *Array*: Key value is an array.    
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - *Hash*: Key value is a hash.   
   
    &nbsp; &nbsp; • *Value*: Key value.         

Contents of this window depend on the selected type of op and the properties defined above by the user.  Following it is described common attributes to all ops when op is dragged from the palette to the rule:      
   
    &nbsp; &nbsp; • *key*: Op registered.     
   
    &nbsp; &nbsp; • *id*: Op instance id, value is in the form of ‘xnode-<number>`.    
    
    &nbsp; &nbsp; • *name*: Op name,  it is a short description of what op does.    
    
    &nbsp; &nbsp; • *text*: Its default value is the op name. This field can be changed through the rename action from op context menu.    
    
    &nbsp; &nbsp; • *icon*: Op image, describes what op does in a graphic way.    
    
    &nbsp; &nbsp; • *leaf*: Set to 0, this key indicates op holds or cand hold nested ops.   

When metadata is saved others attributes are set, they are:  
  
    &nbsp; &nbsp; • *data*: this attribute is a hash with the data from the configuration property form entered by the user.  
  
    &nbsp; &nbsp; • *data_key*: Contains the value from the return key property filled by the user. 
   
    &nbsp; &nbsp; • *disabled*: set to true if the op property ‘enable’ is not checked.    

    &nbsp; &nbsp; • *expanded*: true if op holds other ops nested.

    &nbsp; &nbsp; • *run_forward*: this attribute is showed if the user manipulate property run_forward. Set to true if the property is checked.

    &nbsp; &nbsp; • *run_rollback*: showed if the user clicks on run_rollback property. Set to true if the property is checked.

    &nbsp; &nbsp; • *parallel_mode*: Attribute that indicates the running process mode. It can have three different values:

    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - *none*: Process running in serial mode.    
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - *nohup*: Process running in fork and leave mode.    
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - *fork*: Process running in fork and way mode.    

    &nbsp; &nbsp; • *error_trap*: Attribute that indicates how to trap errors. It can have three different values:    

    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - *none*: no trap error,    
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - *ignored*: ignore error,    
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - *trap*: trap error waiting for an action.    

    &nbsp; &nbsp; • *semaphore_key*: Contains the semaphore name filled by the user in semaphore_key option window. 
    
    &nbsp; &nbsp; • *timeout*: attribute with the number of seconds to wait. 
    
    &nbsp; &nbsp; • *note*: Contains note tab contents. 
    
    &nbsp; &nbsp; • *qtip*: Same as note.     

Attributes depending on the type ops selected are:

    &nbsp; &nbsp; • *Statements*:      

    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - *holds_children*: Indicates if op can hold other op nested inside.    

    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - *nested*: If value is 0, this attribute indicates that op is the beginning of code function.    
 
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - *children*: hash holding the nested ops.        

    &nbsp; &nbsp; • *Services*:     

    &nbsp; &nbsp; • *Rules*:     

    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; - *id_rule*: The value of this key is the id rule number. 
   
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

      &nbsp; &nbsp; • changesets: []    
      &nbsp; &nbsp; • elements: []    
      &nbsp; &nbsp; • job_step: CHECK    
* **dsl area**: Textarea with dsl code from op and its configuration, this code can be changed and executed.    

* **output area**: Textarea with two tab:    

* **Ouput**: Result of dsl code execution.    

* **Stash**: Stash values from dsl code execution.    

* **Toggle**: Switch op state from enable to disable and viceversa. If op is not active a line through op is displayed.    

* **Delete**: Remove op selected.    

