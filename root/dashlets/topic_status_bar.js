(function(params){ 
    var id = params.id_div;

    var graph;
    var categories = params.data.categories || '';
    var statuses = params.data.statuses || '';
    var group_threshold = params.data.group_threshold || '5';
    var not_in_status = params.data.not_in_status;
    var condition = params.data.condition || '';


    if (graph) graph.unload();

    Cla.ajax_json('/dashboard/topics_by_status', { condition: condition, not_in_status: not_in_status, group_threshold: group_threshold, categories: categories, statuses: statuses }, function(res){
        require(['d3','c3'], function(d3,c3){
            c3.generate({
                bindto: '#'+id,
                data: {
                    columns: res.data,
                    type : 'bar',
                    colors: res.colors,
                    onclick: function (d, i) { 
                       Baseliner.add_tabcomp('/comp/topic/topic_grid.js', d.id , { topic_list: res.topics_list[d.id] });
                    },
                },
                axis: {
                 x : {
                    tick: {
                        format: function (x) { return ''; }
                    }
                  },
                  y: {
                    label: {
                      text: '# ' + _('Topics'),
                      position: 'outer-middle'
                    }
                  }
                }
            });
        });
    });

});
