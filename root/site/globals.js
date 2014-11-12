/*

Global vars and data structures.

This is non reloadable, otherwise everything is reset. 

*/

Ext.ns('Baseliner');
Ext.ns('Baseliner.store');
Ext.ns('Baseliner.model');
window.Cla = Baseliner;

Baseliner.tabInfo = {};
Baseliner.keyMap = {};
Baseliner.in_edit = {};
Ext.Ajax.timeout = 60000;
Baseliner.DEBUG = <% Baseliner->debug ? 'true' : 'false' %>;
Prefs = {};

IC = function(icon){
    var path = '/static/images/icons/';
    return /\./.test(icon) ? path+icon : path+icon+'.png'; 
}
