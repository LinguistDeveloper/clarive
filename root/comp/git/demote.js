(function(node) {
    if( node == undefined ) node = {};
    var ns = node.attributes.data.ns;
    var bl = node.attributes.parent_data.bl;
    var bl_from = node.attributes.data.bl_from;
    Baseliner.confirm( _('Are you sure you want to demote %1 to baseline %2', ns, bl_from ), function() { 
        Baseliner.ajaxEval( '/gittree/newjob', { ns: ns, bl: bl, job_type: 'demote', nextbl: bl_from }, function(res) {
            if( res.success ) {
                Baseliner.message( _('Git'), res.msg );
            } else {
                Ext.Msg.alert( _('Error creating job'), res.msg );
            }
        });
    });
})


