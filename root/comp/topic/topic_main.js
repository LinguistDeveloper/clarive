<%args>
    $swEdit
    $permissionEdit
    $category_meta
    $permissionComment
</%args>

(function(params){
    var swEdit = <% $swEdit == 1 ? 'true' : 'false' %>;
    var permEdit = <% $permissionEdit ? 'true' : 'false' %>;
    var permComment = <% $permissionComment ? 'true' : 'false' %>;
    
    //alert(permComment);
    
    var category_meta = "<% $category_meta %>";
    var topic_main_class_name;
    if( category_meta ) {
        topic_main_class_name = Baseliner.topic_category_class[ category_meta ];
    }

    Ext.apply( params, {
        swEdit: swEdit,
        permEdit: permEdit,
        permComment: permComment
    });

    if( topic_main_class_name ) {
        eval("var obj = new "+topic_main_class_name+"(params)");
        return obj;
    } else {
        return new Baseliner.TopicMain(params);
    }

})
