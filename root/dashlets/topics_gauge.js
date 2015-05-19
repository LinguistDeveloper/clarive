(function(params){ 
    var id = params.id_div;

    var categories = params.data.categories || [];
    var statuses = params.data.statuses || [];
    var not_in_status = params.data.not_in_status;
    var condition = params.data.condition || '';
    var days_from = params.data.days_from || 0;
    var days_until = params.data.days_until || 0;
    var date_field_start = params.data.date_field_start;
    var date_field_end = params.data.date_field_end;
    var numeric_field = params.data.numeric_field;

    var green = params.data.green || 10;
    var yellow = params.data.yellow || 20;

    Cla.ajax_json('/dashboard/topics_gauge', { numeric_field: numeric_field, days_from: days_from, days_until: days_until, date_field_start: date_field_start, date_field_end: date_field_end, condition: condition, not_in_status: not_in_status, categories: categories, statuses: statuses }, function(res){
              c3.generate({
                bindto: '#'+id,
                data: {
                    columns: res.data,
                    type: 'gauge',
                },
                gauge: {
                    label: {
                        format: function(value, ratio) {
                            return value;
                        },
                        // show: false // to turn off the min/max labels.
                    },
                    units: 'ffff  saldkffsaj',
                    max: res.max
                },
                color: {
                    pattern: ['#60B044', '#F7D358', '#FA5858'], // the three color levels for the percentage values.
                    threshold: {
                        unit: 'value', // percentage is default
                        values: [green,yellow]
                    }
                },
                size: {
                    height: 300
                }

            });
    });

});
