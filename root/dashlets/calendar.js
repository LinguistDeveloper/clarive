(function(params){ 

    var id = params.id_div;

    var project_id = params.project_id;
    var topic_mid = params.topic_mid;
    var graph;
    var date = params.date || '';
    var categories = params.data.categories || [];
    var date_field = params.data.date_field || 'created_on';
    var date_type = params.data.date_type || 'today';
    var days_from = params.data.days_from || 0;
    var graph_type = params.data.type || 'area';

    var cal = new Baseliner.Calendar({
        tbar_end : [ '->', { xtype:'button', icon: IC('tab.png'), handler:function(){ Baseliner.tabCalendar() } } ],
        bar_where: 'bottom',
        query_type: params.data.query_type,
        id_fieldlet: params.data.id_fieldlet,
        default_view: params.data.default_view,
        id_project: project_id,
        topic_mid: topic_mid,
        categories: categories,
        label_mask: params.data.label_mask,
        show_jobs: params.data.show_jobs==undefined ? false : params.data.show_jobs,
        fullCalendarConfig: {
            events: Baseliner.calendar_events,
            timeFormat: { '':'H(:mm)', agenda:'H:mm{ - H:mm}' }
        }
    });
    var jqid=$('#'+id);
    jqid.html('');
    cal.render(id);
    cal.setHeight( jqid.height() );
});

