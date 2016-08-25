(function(d) {
    var node = d.node;
    var menu_action = d.action;
    if( node == undefined ) node = {};
    if( node.attributes == undefined ) node.attributes = {};
    if( node.attributes.data == undefined ) node.attributes.data = {};

    var mid = node.attributes.data.topic_mid;
    if( mid == undefined ) {
        Baseliner.error( _('Job'), _('Missing mid') );
        return;
    }
    
    var bl = node.attributes.data.bl || menu_action.bl_to;
    if( bl == undefined  ) {
        Ext.Msg.alert( _('Error'), _('Missing bl') );
        return;
    }
    var name = node.attributes.text;
    var job_type = menu_action.job_type;
    var state_name = node.attributes.data.state_name;
    var state_to = menu_action.status_to;
    var to_state_name = menu_action.status_to_name;
    var status_from = node.attributes.data.topic_status;
    var id_status_from = node.attributes.data.id_topic_status;
    var id_project = node.attributes.data.id_project;
    var id = menu_action.id;
    var data = node.attributes.data;
    var is_release = node.attributes.data.is_release;
    var topic = { 
            text: node.text, 
            topic_mid: data.topic_mid, 
            id: id,
            id_project: data.id_project, 
            is_release: is_release,
            state_id: data.state_id, 
            promotable: data.promotable, 
            demotable: data.demotable, 
            deployable: data.deployable , 
            job_type: job_type,
            state_to: state_to
    };
    Baseliner.ajaxEval( '/topic/json', { topic_mid: topic.topic_mid}, function(rec) {
        var db_status = rec.topic_data.id_category_status;
        var form_status = topic.state_id;
        var is_release = rec.topic_data.is_release && (rec.topic_data.is_release == "1" )? true : false;
        if ( !is_release && db_status != form_status){
            Ext.Msg.alert(_('Error'), _('That job cannot be created for that changeset probably because its status has changed. Please, reload the node.'));
        }else{
            Baseliner.add_tabcomp( '/job/create', _('New Job'), { node: topic } );
        }
    });
})
