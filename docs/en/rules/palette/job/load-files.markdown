---
title: Load files/items into stash
index: 5000
icon: file
---

Assigns to a user configured [stash](concepts/stash) variable all 
found files/items according to the options introduced by the
user from the configuration form window.

Form to configure has the following fields:

- **Variable** - Variable to add to the stash with the found files/items.
- **Path** - Base path to find files/items matching user criteria.
- **Path mode** - Option used to find files/items. By default it is set to files_flat. It can be:
   - Files, non Recursive - Only files/items in the current directory.
   - Files recursive - Look through directories recursively.
   - Nature Items - Look for files/items from nature path according to user options.
- **Dir mode** - Option set by the user to search files/items in some way. By default it is set to  file_only. It can be:
   - File only - Just look for files, not directories.
   - Dir only - Only directories will be attended.
   - File and dir - Look for files and through directories.
- **Filters** - According to the params from the filter panel, files/items will be included or excluded from the list.
    - Include paths - Path patterns to search for files/items matching user criteria.
    - Exclude paths - Any file/item matching the path pattern will be excluded from the list.