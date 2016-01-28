(function(params) {

    var id = params.id_div;

    var project_id = params.project_id;
    var topic_mid = params.topic_mid;
    var graph;
    var date = params.date || '';
    var categories = params.data.categories || [];
    var date_field = params.data.date_field || 'created_on';
    var date_type = params.data.date_type || 'today';
    var days_from = params.data.days_from || 0;
    var days_from_format_date = params.data.days_from_format_date || 0;
    var group_by_period = params.data.group_by_period;
    var graph_type = params.data.type || 'area';

    Cla.ajax_json('/dashboard/topics_burndown2', {
            topic_mid: topic_mid,
            project_id: project_id,

            selection_method: params.data.selection_method,

            select_by_duration_range: params.data.select_by_duration_range,
            select_by_duration_offset: params.data.select_by_duration_offset,

            select_by_period_from: params.data.select_by_period_from,
            select_by_period_to: params.data.select_by_period_to,

            date: date,

            group_by_period: group_by_period,
            date_field: date_field,
            categories: categories,
            _ignore_conn_errors: true
        },
        function(res) {
            graph = c3.generate({
                bindto: '#' + id,
                data: {
                    x: 'x',
                    columns: res.data,
                    types: {
                        Topics: graph_type,
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
                regions: [{
                    axis: 'x',
                    start: 8,
                    end: 18,
                    class: 'workhours'
                }]
            });
        });
});