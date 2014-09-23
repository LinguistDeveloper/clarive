<%args>
    $topic_mid
    $swEdit
    $permissionEdit
    $permissionDelete
    $permissionGraph
    $category_meta
    $permissionComment
    $viewKanban
    $HTMLbuttons => 0
    $status_items_menu => undef
    $menu_deploy => undef
</%args>

(function(params){
    var topic_mid = '<% $topic_mid %>';
    var swEdit = <% $swEdit == 1 ? 1 : 0 %>;
    var permEdit = <% $permissionEdit ? 'true' : 'false' %>;
    var permDelete = <% $permissionDelete ? 'true' : 'false' %>;
    var permGraph = <% $permissionGraph ? 'true' : 'false' %>;
    var permComment = <% $permissionComment ? 'true' : 'false' %>;
    var viewKanban = <% $viewKanban ? 'true' : 'false' %>;
    var html_buttons = <% $HTMLbuttons == 1 ? 1 : 0 %>;
    var status_items_menu = '<% $status_items_menu %>';
    var menu_deploy = '<% $menu_deploy %>';
    
    var category_meta = "<% $category_meta %>";
    var topic_main_class_name;
    if( category_meta ) {
        topic_main_class_name = Baseliner.topic_category_class[ category_meta ];
    }

    Ext.apply( params, {
        swEdit: swEdit,
        permEdit: permEdit,
        permGraph: permGraph,
        permDelete: permDelete,
        permComment: permComment,
        viewKanban: viewKanban,
        html_buttons: html_buttons,
        status_items_menu: status_items_menu,
        menu_deploy: menu_deploy
    });

    
    var topic_main;
    if( topic_main_class_name ) {
        eval( "var class_name = " + topic_main_class_name + ";" );
        var obj = new class_name(params);
        topic_main = obj;
    } else {
        topic_main = new Baseliner.TopicMain(params);
    }

    Baseliner.edit_check( topic_main, true );  // block window closing from the beginning

    //topic_main.tab_title = null; //Baseliner.topic_title( params.topic_mid, _(params.category), params.category_color, params.title );
    //topic_main.tab_icon = null;
    
    topic_main.print_hook = function(){
        var t = params.topic_mid || topic_main.title;
        return { title: t , id: topic_main.getLayout().activeItem.body.id };
    }
    
    return topic_main;
})

