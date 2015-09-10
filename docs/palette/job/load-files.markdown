---
title: Load files/items
---

Assigns to a user configured stash variable all found files/items according to the options introduced by the 
user from the configuration form window. Form to configure has the following fields:   

* **varname**: variable to add to the stash with the found files/items.    

* **path**: base path to find files/items matching user criteria.    

* **path mode**: option used to find files/items. By default it is set to files_flat. It can be:    
    
      &nbsp; &nbsp; • files flat: Only files/items in the current directory.     

      &nbsp; &nbsp; • files recursive: Look through directories recursively. 
   
      &nbsp; &nbsp; • nature items: Look for files/items from nature path according to user options.      

* **dir mode**: Option set by the user to search files/items in some way. By default it is set to  file_only. It can be:     

      &nbsp; &nbsp; • file only: Just look for files, not directories.     

      &nbsp; &nbsp; • dir only: Only directories will be attended.    

      &nbsp; &nbsp; • file and dir: Look for files and through directories.    

* **filters**: According to the params from the filter panel, files/items will be included or excluded from the list.     

      &nbsp; &nbsp; • include paths: path patterns to search for files/items matching user criteria.   

      &nbsp; &nbsp; • exclude paths: any file/item matching the path pattern will be excluded from the list.    

