(function(params){ 
    var id = params.id_div;
    var div = document.getElementById(id);
    div.style.clear = "left";
    var foo = function(html_code){
        div.innerHTML = html_code; 
        if( params.data.js_code ) {
            var js = params.data.js_code; 
            var comp = eval('(function(){\n' + js + '\n;})');
            comp = comp();
            // is this ExtJS ? 
            if( comp.render ) {
                comp.render( div );
            }
        }
    }
    var url = params.data.data_url;
    if( url ) {
        Cla.ajax_json( url, { }, function(res){
            var str = Cla.tmpl( params.data.html_code, res.stash );
            foo( str );
        });
    } else {
        foo( params.data.html_code ); 
    }
});
