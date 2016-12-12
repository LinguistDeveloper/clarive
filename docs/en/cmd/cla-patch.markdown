---
title: cla patch - Apply/Rollback patches
index: 5000
icon: console
---

Patching mechanism is useful when updating to a newer Clarive version without installing the whole distribution.

All the commands support `--dry-run` mode when no actual changes to files are made and `--quiet`mode where no message is displayed.

## Applying patches

To apply a patch received from Clarive do the following:

    cla patch-apply --patch clarive_VERSION1-VERSION2.patch.tar.gz

This is going to update your installation from VERSION1 to VERSION2. The command will fail if the local version is
invalid or the source code is not patchable.

## Rollbacking patches

To rollback a previously applied patch do the following:

    cla patch-rollback --patch clarive_VERSION1-VERSION2.patch.tar.gz

This is going to revert all the changes that were made by the patch.
