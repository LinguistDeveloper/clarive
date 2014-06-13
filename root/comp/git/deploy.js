(function(node) {
    if( node == undefined ) node = {};
    //alert( "voys2");
    //alert( "P=" + node.attributes.parent_data.id_project );
    //alert( "P=" + node.attributes.parent_data.bl );
    //alert( "P=" + node.attributes.data.id_project );
    //alert( "P=" + node.attributes.data.ns );

    // job_type: 'static'
    //
    var ns = node.attributes.data.ns;
    var bl = node.attributes.parent_data.bl;
    Baseliner.confirm( _('Are you sure you want to deploy %1 in baseline %2', ns, bl ), function() { 
        Baseliner.ajaxEval( '/gittree/newjob', { ns: ns, bl: bl, job_type: 'static' }, function(res) {
            if( res.success ) {
                Baseliner.message( _('Git'), res.msg );
            } else {
                Ext.Msg.alert( _('Error creating job'), res.msg );
            }
        });
    });
})
