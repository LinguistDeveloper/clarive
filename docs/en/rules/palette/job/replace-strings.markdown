---
title: Replace Strings
index: 5000
icon: rename-items
---

Parse specified files from a given path. Parsed files can be processed in different ways according to the user criteria from the configuration window.

Form to configure has the following fields:

- **Path** - Path to search for files to be processed.
- **Slurp** - Checkbox to put all contents file in memory.
- **Items mode** - Option to select files to be parsed. Values supported are:
  - All files - All files from path will be processed.
  - Only job items - Only files from nature will be parsed.
- **Output dir** - Directory where parsed files will be left.
- **Suffix** - Processed files will be renamed adding the configured suffix to the file.
- **Patterns** - File data will be processed with assigned patterns from this field.
- **Includes** - Files in list to be parsed must match patterns configured in this field.
- **Excludes** - Files matching this pattern will be excluded from the list of files to be parsed.