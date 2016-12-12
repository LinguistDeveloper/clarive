---
title: Custom CIs Grid
index: 5000
icon: class
---

Feature CIs are formed at least by one perl file where functionality is defined, and a javascript file that have all visual configuration. If you want to personalize the grid columns that are shown in list class elements it is needed to add custom_grid method in perl CI definition file that returns the specified path of the custom grid, like:

	sub custom_grid {'comp/customized_grid.js'}

The grid definition file have to be written in well format javascript. It is your responsility to make sure the custom grid is working with Clarive.