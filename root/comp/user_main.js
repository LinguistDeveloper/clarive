(function(){
    var main = new Ext.Panel({
        layout: 'card'
    });
    //Baseliner.ajaxEval('/user/grid', { tbar:[ btn1m, btn1f ] }, function(comp){
    Baseliner.ajaxEval('/user/grid', { }, function(comp){  
        main.insert(0, comp );
        main.getLayout().setActiveItem(0);
    });

    return main;
})
