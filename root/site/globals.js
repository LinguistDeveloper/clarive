/*

Global vars and data structures.

This is non reloadable, otherwise everything is reset. 

*/

Ext.ns('Baseliner');

Baseliner.tabInfo = {};
Baseliner.keyMap = {};
Baseliner.in_edit = {};
Ext.Ajax.timeout = 60000;
Baseliner.DEBUG = <% Baseliner->debug ? 'true' : 'false' %>;
