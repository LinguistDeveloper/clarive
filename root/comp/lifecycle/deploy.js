(function(d) {
    var node = d.node;
    var action = d.action;
    if( node == undefined ) node = {};
    if( node.attributes == undefined ) node.attributes = {};
    if( node.attributes.data == undefined ) node.attributes.data = {};

    var ns = node.attributes.data.ns;
    if( ns == undefined  ) {
        Ext.Msg.alert( _('Error'), _('Missing ns') );
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
    var to_state_name = action.status_to_name;
    var status_from = node.attributes.data.topic_status;
    Baseliner.confirm( _('Are you sure you want to deploy %1 to baseline %2?', String.format("<b>{0}</b>", name), String.format("<b>{0}</b>",_(to_state_name)) ), function() { 
        Baseliner.ajaxEval( '/topic/newjob', { ns: ns, bl: bl, job_type: job_type, status_to: status_to, status_from: status_from }, function(res) {
            if( res.success ) {
                Baseliner.message( _('Job'), res.msg );
            } else {
                Ext.Msg.alert( _('Error creating job'), res.msg );
            }
        });
    });
})
