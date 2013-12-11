(function(d) {
    var node = d.node;
    var action = d.action;
    if( node == undefined ) node = {};
    if( node.attributes == undefined ) node.attributes = {};
    if( node.attributes.data == undefined ) node.attributes.data = {};

    var mid = node.attributes.data.topic_mid;
    if( mid == undefined ) {
        Baseliner.error( _('Job'), _('Missing mid') );
        return;
    }

    var bl = node.attributes.data.bl;
    if( bl == undefined  ) {
        Ext.Msg.alert( _('Error'), _('Missing bl') );
        return;
    }
    var name = node.attributes.text;
    var job_type = action.job_type;
    if( bl == 'new' ) {
        bl = 'DESA';  // XXX
    }
    var state_name = node.attributes.data.state_name;
    var status_to = action.status_to;
    var bl_to = action.bl_to;
    var to_state_name = action.status_to_name;
    var status_from = node.attributes.data.topic_status;
    var id_status_from = node.attributes.data.id_topic_status;
    Baseliner.confirm( _('Are you sure you want to deploy/rollback %1 to baseline %2 (%3)?', String.format("<b>{0}</b>", name), String.format("<b>{0}</b>",_(to_state_name)),bl_to ), function() { 
        Baseliner.message( _('Job'), _('Starting job check and initialization...') );
        Baseliner.ajaxEval( '/topic/newjob', { changesets:[mid], bl: bl_to, job_type: job_type, status_to: status_to, status_from: status_from, id_status_from: id_status_from }, function(res) {
            if( res.success ) {
                Baseliner.message( _('Job'), res.msg );
            } else {
                Ext.Msg.alert( _('Error creating job'), res.msg );
            }
        });
    });
})
