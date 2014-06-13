(function(node) {
    if( node == undefined ) node = {};
    var ns = node.attributes.data.ns;
    var bl = node.attributes.parent_data.bl;
    var bl_to = node.attributes.data.bl_to;
    Baseliner.confirm( _('Are you sure you want to promote %1 to baseline %2', ns, bl_to ), function() { 
        Baseliner.ajaxEval( '/gittree/newjob', { ns: ns, bl: bl_to, job_type: 'promote' }, function(res) {
            if( res.success ) {
                Baseliner.message( _('Git'), res.msg );
            } else {
                Ext.Msg.alert( _('Error creating job'), res.msg );
            }
        });
    });
})

