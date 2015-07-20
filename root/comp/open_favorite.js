(function(params){
    var click = params.click;
    var title = params.title || args[1];
    var tabfav = click.tabfav;
    var fooname = tabfav.foo;  // function name
    var args = tabfav.args;  // function args
    var foo = eval(""+fooname); 
    var params = args[2] || {};
    params.current_state = click.current_state || {};
    //foo.apply({},args);
    foo(args[0],title,params,args[3],args[4]);
    return [];
});
