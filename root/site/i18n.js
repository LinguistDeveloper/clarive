/*

    i18n Internationalization for JavaScript using Catalyst's I18N files. 

    Do not load this JS directly. Call it thru its Controller instead: /i18n/js
        <script type="text/javascript" src="/i18n/js"></script>

    Usage: 
        alert( _("Hello %1 %2", "mundo", "azul") );

*/

// Loads the current Catalyst PO from the stash

var i18n = {
<% $c->stash->{po} %>
}

// translates
function _(string) {  
    if (typeof(i18n)!='undefined' && i18n[string]) {  
        string =  i18n[string];  
    }  

    for( var i = 1; i < arguments.length; i++ ) {
        var re = new RegExp( '%' + i );
        string = string.replace( re, arguments[i] );
    }
    return string;	
}  

// alias to translation
function _loc(string) {  
    if (typeof(i18n)!='undefined' && i18n[string]) {  
        string =  i18n[string];  
    }  

    for( var i = 1; i < arguments.length; i++ ) {
        var re = new RegExp( '%' + i );
        string = string.replace( re, arguments[i] );
    }
    return string;	
}  
