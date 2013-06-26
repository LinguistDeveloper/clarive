<%args>
    $swEdit
    $permissionEdit
    $category_meta
    $permissionComment
    $HTMLbuttons => 0
</%args>

(function(params){
    var swEdit = <% $swEdit == 1 ? 1 : 0 %>;
    var permEdit = <% $permissionEdit ? 'true' : 'false' %>;
    var permComment = <% $permissionComment ? 'true' : 'false' %>;
    var html_buttons = <% $HTMLbuttons == 1 ? 1 : 0 %>;
    
    var category_meta = "<% $category_meta %>";
    var topic_main_class_name;
    if( category_meta ) {
        topic_main_class_name = Baseliner.topic_category_class[ category_meta ];
    }

    Ext.apply( params, {
        swEdit: swEdit,
        permEdit: permEdit,
        permComment: permComment,
        html_buttons: html_buttons
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

    return topic_main;
})
