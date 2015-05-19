// Simple JavaScript Templating
// John Resig - http://ejohn.org/ - MIT Licensed
// rgo: heredoc quote fix, XXX heredoc comment only works in FF >= 17
Baseliner.HEREDOC_SLICE_START = Ext.isSafari ? 15 : (Ext.isChrome || Ext.isGecko) && !Cla.isIE ? 14 : 13;  // 13 is for IE
Baseliner.HEREDOC_SLICE_END   = Ext.isSafari ? -4 : -3;
Function.prototype.heredoc = function(s){ return this.toString().slice(Baseliner.HEREDOC_SLICE_START,Baseliner.HEREDOC_SLICE_END) };
Function.prototype.tmpl = function(data){ return Baseliner.tmpl(this.heredoc(),data) };
String.prototype.tmpl = function(data){ return Baseliner.tmpl(this+"",data) };
Baseliner.tmpl_cache = {};
Baseliner.tmpl = function (str, data){
    // Figure out if we're getting a template, or if we need to
    // load the template - and be sure to cache the result.
    var st = Baseliner.HEREDOC_SLICE_START;
    var en = Baseliner.HEREDOC_SLICE_END;
    var he = ['function(){/*', '*/}.toString().slice('+st+','+en+')']; 
    var fn = !/\W/.test(str) && str.length>0
        ? Baseliner.tmpl_cache[str] = Baseliner.tmpl_cache[str] ||
           Baseliner.tmpl(document.getElementById(str).innerHTML) 
        :
     
      // Generate a reusable function that will serve as a template
      // generator (and which will be cached).
     new Function("obj",
        "var p=[],print=function(){p.push.apply(p,arguments);};" +

        // Introduce the data as local variables using with(){}
        "with(obj){p.push("+he[0]+

        // Convert the template into pure JavaScript
         str
          .replace(/[\r\t\n]/g, " ")    
          .split("[%").join("\t")
          .replace(/((^|%\])[^\t]*)/g, "$1\r")
          .replace(/\t=(.*?)%\]/g, he[1]+",$1,"+he[0])
          .split("\t").join(he[1]+");")
          .split("%]").join("p.push("+he[0])
          .split("\r").join("")
          + he[1]+");}return p.join('');"
      );

    // Provide some basic currying to the user
    return data ? fn( data ) : fn;
};


