/*

Global vars and data structures.

This is non reloadable, otherwise everything is reset. 

*/

Ext.ns('Baseliner');
Ext.ns('Baseliner.store');
Ext.ns('Baseliner.model');

Baseliner.tabInfo = {};
Baseliner.keyMap = {};
Baseliner.in_edit = {};
Ext.Ajax.timeout = 60000;
Baseliner.DEBUG = <% Baseliner->debug ? 'true' : 'false' %>;
Prefs = {};
