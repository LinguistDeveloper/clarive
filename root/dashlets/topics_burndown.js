(function(params){ 

    var id = params.id_div;

    var graph;
    var date = params.date || '';
    var categories = params.data.categories || [];
    var date_field = params.data.date_field || 'created_on';
    var date_type = params.data.date_type || 'today';
    var days_from = params.data.days_from || 0;

      Cla.ajax_json('/dashboard/topics_burndown', { days_from: days_from, date_type: date_type, date: date, categories: categories, date_field: date_field, _ignore_conn_errors: true  }, function(res){
           graph = c3.generate({
                bindto: '#'+id,
                data: {
                    x: 'x',
                    columns: res.data,
                    types: {
                      Topics: 'area',
                      Trend: 'line'
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
                        type: 'category',
                        tick: {
                            multiline: false
                        },
                        label: {
                          text: res.date,
                          position: 'outer-center'
                        }

                    },
                    y: {
                      label: {
                        text: '# topics',
                        position: 'outer-middle'
                      }
                    }
                },
                regions: [
                    {axis: 'x', start: 8, end: 18, class: 'workhours'}
                ]
           });
      });
});
