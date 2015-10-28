(function(params){ 

    var id = params.id_div;

    var project_id = params.project_id;
    var topic_mid = params.topic_mid;
    var graph;
    var date = params.date || '';
    var categories = params.data.categories || [];
    var date_field = params.data.date_field || 'closed_on';
    var date_type = params.data.date_type || 'today';
    var days_before = params.data.days_before || 0;
    var days_after = params.data.days_after || 0;
    var graph_type = params.data.type || 'area';
    var group = params.data.group || 'day';

    var format = '%Y/%m/%d';

      Cla.ajax_json('/dashboard/topics_period_burndown', { group: group, topic_mid: topic_mid, project_id: project_id, days_before: days_before, days_after: days_after, date_type: date_type, date: date, categories: categories, date_field: date_field, _ignore_conn_errors: true  }, function(res){
           graph = c3.generate({
                bindto: '#'+id,
                data: {
                    x: 'x',
                    columns: res.data,
                    types: {
                      Real: graph_type,
                      Expected: 'line'
                    }
                },
                bar: {
                    width: {
                        ratio: 0.4 // this makes bar width 50% of length between ticks
                    }
                    // or
                    //width: 100 // this makes bar width 100px
                },
                point: {
                        show: false
                },
                grid: {
                    x: {
                        show: true
                    },
                    y: {
                        show: true
                    }
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
                        text: '# topics',
                        position: 'outer-middle'
                      }
                    }
                }
                ,
                regions: [
                    {axis: 'x', start: res.future_start, end: res.date_to, class: 'workhours'}
                ]
           });
      });
});
