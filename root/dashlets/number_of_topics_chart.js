(function(params){ 
    var id = params.id_div;

    var graph_type = params.data.type || 'donut';
    var categories = params.data.categories || '';
    var statuses = params.data.statuses || '';
    var group_threshold = params.data.group_threshold || '5';
    var not_in_status = params.data.not_in_status;
    var condition = params.data.condition || '';
    var group_by = params.data.group_by || 'topics_by_status';
    var graph_title;

    Cla.ajax_json('/dashboard/'+group_by, { condition: condition, not_in_status: not_in_status, group_threshold: group_threshold, categories: categories, statuses: statuses }, function(res){
        require(['d3','c3'], function(d3,c3){
            c3.generate({
                bindto: '#'+id,
                data: {
                    columns: res.data,
                    type : graph_type,
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
                      position: 'outer-middle',
                      format: function (value, ratio, id) {
                          return d3.format('')(value);
                      }
                    }
                  }
                },
                tooltip: {
                   grouped: false // Default true
                },
                pie: {
                    label: {
                        format: function (value, ratio, id) {
                            return value;
                        }
                    }
                }


            });
        });
    });

});
