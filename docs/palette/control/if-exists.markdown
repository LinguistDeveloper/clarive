---
title: IF EXISTS nature THEN
---

Checks if changeset meets defined nature and if so process nested op. Following variables are included into stash

* **nature_items**: cis affected by defined natured.    
* **nature_item_paths**: Paths to changed items that meets defined nature and have not been deleted from repository.    
* **nature_item_paths_del**: Paths to changed items that meets defined nature and have  been deleted from repository.    
* **nature_items_comma**: String with all paths to changed items that meet the defined natured separated by commas.    
* **nature_items_quote**: String with all paths to changed items that meet the defined natured each of one quoted.    

Form to configure has the following fields:    

* **Nature**: combo box filled with data from ci ‘nature’, only one nature can be selected.    
* **Cut Path**: Path included in this field will be discarded from the changed items path.    


