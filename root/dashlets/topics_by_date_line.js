(function(params){ 

    var format = '%Y-%m-%d';

    var id = params.id_div;

    var graph;
    var graph_type = params.data.type || 'area';
    var stacked = false;
    if ( graph_type.startsWith('stack-') ) {
        console.log("Type before: "+graph_type);
        graph_type = graph_type.replace('stack-','');
        console.log("Type after: "+graph_type);
        stacked = true;
    }
    var categories = params.data.categories || [];
    var statuses = params.data.statuses || [];
    var group_threshold = params.data.group_threshold || '5';
    var not_in_status = params.data.not_in_status;
    var condition = params.data.condition || '';
    var group = params.data.group || 'day';
    var date_field = params.data.date_field || 'created_on';

    if (graph) graph.unload();

    Cla.ajax_json('/dashboard/topics_by_date', { date_field: date_field, group: group, condition: condition, not_in_status: not_in_status, group_threshold: group_threshold, categories: categories, statuses: statuses }, function(res){
        var groups = new Array();
        if ( stacked ) {
            groups = [res.data.groups];
        }else{
            groups= []
        }
        require(['d3','c3'], function(d3,c3){
            graph = c3.generate({
                 bindto: '#'+id,
                 data: {
                     x: 'x',
                     columns: res.data.matrix,
                     type: graph_type,
                     colors: res.data.colors,
                     groups: groups
                 },
                 bar: {
                     width: {
                         ratio: 0.4 // this makes bar width 50% of length between ticks
                     }
                     // or
                     //width: 100 // this makes bar width 100px
                 },
                 axis: {
                     x: {
                         type: 'timeseries',
                         tick: {
                             rotate: 90,
                             multiline: false,
                             format: format
                         }
                     },
                     y: {
                       label: {
                         text: '# '+_('Topics'),
                         position: 'outer-middle'
                       }
                     }
                 },
                 tooltip: {
                    grouped: false // Default true
                 },
                 point: {
                     show: false
                 }
            });
        });
    });
});
