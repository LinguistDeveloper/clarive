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

Cla.isIE = !(window.ActiveXObject) && "ActiveXObject" in window;

Cla.BrowserVersion = function(){
    var ua = navigator.userAgent.toLowerCase();
    var match = ua.match('version/([^ ]+)') || ua.match('chrome/([^ ]+)');
    return match && match[1] ? match[1] : -1;
}();

// our own, simpler requirejs
Cla.loaded_scripts = new Array();
Cla.use = function(urls, callback, cache){
    var load_url = function(url,cb){
        if( !cache ) {
            var sep = (url.indexOf('?') > -1) ? '&' : '?';
            url += sep + 'clarnd=' + Math.random();
        }
        if ($.inArray(url, Cla.loaded_scripts) > -1) {
            cb();
        }
        else {
            Cla.loaded_scripts.push(url);       
            jQuery.ajax({
                type: "GET",
                url: url,
                success: cb,
                dataType: "script",
                cache: cache
            });
        }
    };
    if( urls instanceof Array ) {
        var counter = urls.length;
        var rets = [];
        var done_cb = function(a,b){
            rets.push([a,b]);
            counter--;
            if( counter <= 0 ) {
                callback(rets);
            }
        };
        $(urls).each(function(ix,url){ load_url(url,done_cb) });
    } else {
        load_url( urls, callback );
    }
};
