---
title: Load files/items
icon: file
---

<img src="/static/images/icons/file.gif" /> Assigns to a user configured stash variable all found files/items according to the options introduced by the 
user from the configuration form window. 

* Form to configure has the following fields: <br />

&nbsp; &nbsp; • **Varname**: Variable to add to the stash with the found files/items. <br />

&nbsp; &nbsp; • **Path**: Base path to find files/items matching user criteria.<br />

&nbsp; &nbsp; • **Path mode**: Option used to find files/items. By default it is set to files_flat. It can be: <br />
      
&nbsp; &nbsp;&nbsp; &nbsp; • *Files flat* - Only files/items in the current directory. <br />

&nbsp; &nbsp;&nbsp; &nbsp; • *Files recursive* - Look through directories recursively.  <br />

&nbsp; &nbsp;&nbsp; &nbsp; • *Nature items* - Look for files/items from nature path according to user options. <br />



&nbsp; &nbsp; • **Dir mode**: Option set by the user to search files/items in some way. By default it is set to  file_only. It can be: <br />

&nbsp; &nbsp;&nbsp; &nbsp; • *File only*: Just look for files, not directories. <br />

&nbsp; &nbsp;&nbsp; &nbsp; • *Dir only*: Only directories will be attended. <br />

&nbsp; &nbsp;&nbsp; &nbsp; • *File and dir*: Look for files and through directories. <br />



&nbsp; &nbsp; • **Filters**: According to the params from the filter panel, files/items will be included or excluded from the list.<br />
      
&nbsp; &nbsp;&nbsp; &nbsp; • *Include paths*: Path patterns to search for files/items matching user criteria. <br />
     
&nbsp; &nbsp;&nbsp; &nbsp; • *Exclude paths*: Any file/item matching the path pattern will be excluded from the list.
