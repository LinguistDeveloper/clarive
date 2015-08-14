(function(params){ 

    var id = params.id_div;

    var project_id = params.project_id;
    var graph;
    var date = params.date || '';
    var categories = params.data.categories || [];
    var date_field = params.data.date_field || 'created_on';
    var date_type = params.data.date_type || 'today';
    var days_from = params.data.days_from || 0;

    Cla.ajaxEval('/comp/roadmap.js', params, function(grid){
        var jqid=$('#'+id);
        grid.setHeight( jqid.height() );
        jqid.html('');
        grid.render(id);
    });
});

