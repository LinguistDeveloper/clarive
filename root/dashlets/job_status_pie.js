(function(params){ 
    var id = params.id_div;

    var graph;
    var graph_type = params.data.type || 'donut';
    var graph_period = params.data.period || '1M';
    var graph_title;

    if ( graph_period == '1D') {
      graph_title = _('Last day');
    } else if ( graph_period == '7D') {
      graph_title = _('Last week');
    } else if ( graph_period == '1M') {
      graph_title = _('Last month');
    } else if ( graph_period == '3M') {
      graph_title = _('Last quarter');
    } else if ( graph_period == '1Y') {
      graph_title = _('Last year');
    }    

    var reload_dashlet = function( period, title ) {
        graph_title = title;
        if ( !period ) period = graph_period;
        graph_period = period;
        if (graph) graph.unload();

        Cla.ajax_json('/job/by_status', { period: period }, function(res){
            require(['d3','c3'], function(d3,c3){
                c3.generate({
                     bindto: '#'+id,
                     data: {
                         columns: res.data,
                         type : graph_type,
                         colors: {'FINISHED':'#5cb85c','ERROR':'#d9534f'},
                         onclick: function (d, i) { console.log("onclick", d, i); },
                     },
                     donut: {
                         title: title
                     }
                });
            });
        });
    };

    $(function () {
        reload_dashlet( graph_period,graph_title );
    });
});
