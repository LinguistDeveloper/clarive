---
title: Commits history of branch
icon: static/images/icons/lc/branch_obj.gif
---

Commits history grid shows all commits. To open the grid, click on branch node <img src="/static/images/icons/lc/branch_obj.gif" /> in lifecycle panel.

Every row refers to a different commit. To open a new tab with all the details of every commit, select one row and click on *DIFF* info in DIFF column.

To search for specific commits, use search field in toolbar. By default, searches are done by ID Revision. To apply filters in searching, Git formats supported are:

#### Date format

* Indicating the starting date, like this:

        --since="YYYY-MM-DD".

    An example:

        --since:"2016-05-01".

* Or the ending date of the range:

        --until="YYYY-MM-DD".

    Always the same pattern:

        --until "2016-05-31".

#### Author

* This filter allow us to search commits by commit author name. We can see users names in "Author" column on the grid. For example:

        --author="anthony"

#### Comments

* We can filter commits depending on the comments. To see comments we can check the "Comments" column. Next one could be a good example. With "help" grid will show commits with this string as a part of the whole comment:

        --comment="help"
