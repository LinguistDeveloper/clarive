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
    var graph_type = params.data.type || 'area';
    var format = '%Y/%m/%d';

    Cla.ajax_json('/dashboard/topics_burndown_ng', {
            topic_mid: topic_mid,
            project_id: project_id,

            selection_method: params.data.selection_method,

            select_by_duration_range: params.data.select_by_duration_range,
            select_by_duration_offset: params.data.select_by_duration_offset,

            select_by_period_from: params.data.select_by_period_from,
            select_by_period_to: params.data.select_by_period_to,

            select_by_topic_filter_from: params.data.select_by_topic_filter_from,
            select_by_topic_filter_to: params.data.select_by_topic_filter_to,

            query: params.data.query,
            closed_statuses: params.data.closed_statuses,

            date: date,

            scale: params.data.scale || 'hour',
            date_field: date_field,
            categories: categories,
            _ignore_conn_errors: true
        },
        function(res) {
            var xFormat;
            if (params.data.scale == 'hour') {
                xFormat = '%Y-%m-%d %H';
            } else if (params.data.scale == 'day') {
                xFormat = '%Y-%m-%d';
            } else if (params.data.scale == 'month') {
                xFormat = '%Y-%m';
            } else if (params.data.scale == 'year') {
                xFormat = '%Y';
            }
            graph = c3.generate({
                bindto: '#' + id,
                data: {
                    x: 'x',
                    xFormat: xFormat,
                    columns: res.data,
                    types: {
                        Topics: graph_type,
                        Trend: 'line'
                    }
                },
                bar: {
                    width: {
                        ratio: 0.4
                    }
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
                            format: format,
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
                    start: new Date(),
                    class: 'workhours'
                }]
            });
        });
});