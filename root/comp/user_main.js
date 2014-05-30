(function(){
    var gbtn_m = function(pressed,gr) { return new Ext.Button({ 
              text: _('Manage'),
              icon: '/static/images/icons/user_suit.gif',
              pressed: pressed, allowDepress: false, toggleGroup: 'user_main_btn'+gr,
              handler: function(){
                 main.getLayout().setActiveItem(0);
                 btn1m.toggle(true);
              }
            }); };
    var gbtn_f = function(pressed,gr) { return new Ext.Button({ 
              text: _('Flat View'),
              icon: '/static/images/icons/users.gif',
              pressed: pressed, allowDepress: false, toggleGroup: 'user_main_btn'+gr,
              handler: function(){
                 main.getLayout().setActiveItem(1);
                 btn2f.toggle(true);
              }
            }) };

    var btn1m=gbtn_m(true,'a');
    var btn1f=gbtn_f(false,'a');
    var btn2m=gbtn_m(false,'a');
    var btn2f=gbtn_f(true,'a');

    var main = new Ext.Panel({
        layout: 'card'
    });
    //Baseliner.ajaxEval('/user/grid', { tbar:[ btn1m, btn1f ] }, function(comp){
    Baseliner.ajaxEval('/user/grid', { tbar:[ btn1m] }, function(comp){  
        main.insert(0, comp );
        main.getLayout().setActiveItem(0);
    });

    Baseliner.ajaxEval('/comp/user_grid_flat.js', { tbar:[ btn2m, btn2f] }, function(comp){
        main.insert(1, comp );
        //main.getLayout().setActiveItem(1);
    });

    return main;

})
