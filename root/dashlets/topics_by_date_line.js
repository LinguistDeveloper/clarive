(function(params){ 

    var format = '%Y-%m-%d';

    var id = params.id_div;

    var project_id = params.project_id;
    var graph;
    var graph_type = params.data.type || 'area';
    var stacked = false;
    if ( graph_type.indexOf('stack-') === 0 ) {
        graph_type = graph_type.replace('stack-','');
        stacked = true;
    }
    var categories = params.data.categories || [];
    var statuses = params.data.statuses || [];
    var group_threshold = params.data.group_threshold || '5';
    var not_in_status = params.data.not_in_status;
    var condition = params.data.condition || '';
    var group = params.data.group || 'day';
    var days_from = params.data.days_from || 0;
    var days_until = params.data.days_until || 0;
    var date_field = params.data.date_field || 'created_on';

    if (graph) graph.unload();

    Cla.ajax_json('/dashboard/topics_by_date', { project_id: project_id, days_from: days_from, days_until: days_until, date_field: date_field, group: group, condition: condition, not_in_status: not_in_status, group_threshold: group_threshold, categories: categories, statuses: statuses, _ignore_conn_errors: true  }, function(res){
        var groups = new Array();
        if ( stacked ) {
            groups = [res.data.groups];
        }else{
            groups= []
        }
            graph = c3.generate({
                 bindto: '#'+id,
                 data: {
                     x: 'x',
                     columns: res.data.matrix,
                     type: graph_type,
                     colors: res.data.colors,
                     groups: groups,
                     onclick: function (d, i) {
                        // console.log(d);
                        //var epoc = d.x.getTime();
                        // console.log(res.data.topics_list);
                        // console.log("Epoc: " + epoc);
                        // console.log("Id: " + d.id);
                        if ( res.data.topics_list[d.index] && res.data.topics_list[d.index][d.id] ) Baseliner.add_tabcomp('/comp/topic/topic_grid.js', d.id + " - " + d.x.toLocaleDateString() , { clear_filter: 1, topic_list: res.data.topics_list[d.index][d.id] });
                     }
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
                    grouped: false,
                    contents: function (d, defaultTitleFormat, defaultValueFormat, color) {
                        var $$ = this, config = $$.config,
                            titleFormat = config.tooltip_format_title || defaultTitleFormat,
                            nameFormat = config.tooltip_format_name || function (name) { return name; },
                            valueFormat = config.tooltip_format_value || defaultValueFormat,
                            text, i, title, value, name, bgcolor;
                        for (i = 0; i < d.length; i++) {
                            if (! (d[i] && (d[i].value || d[i].value === 0))) { continue; }

                            if (! text) {
                                title = titleFormat ? titleFormat(d[i].x) : d[i].x;
                                text = "<table class='" + $$.CLASS.tooltip + "'>" + (title || title === 0 ? "<tr><th colspan='2'>" + title + "</th></tr>" : "");
                            }

                            name = nameFormat(d[i].name);
                            value = valueFormat(d[i].value, d[i].ratio, d[i].id, d[i].index);
                            bgcolor = $$.levelColor ? $$.levelColor(d[i].value) : color(d[i].id);

                            text += "<tr class='" + $$.CLASS.tooltipName + "-" + d[i].id + "'>";
                            text += "<td class='name'><span style='background-color:" + bgcolor + "'></span>&nbsp;" + name + "</td>";
                            text += "<td class='value'>&nbsp;" + d[i].value+"</td>";
                            text += "</tr>";
                        }
                        return text + "</table>";
                    }
                 },
                 point: {
                     show: false
                 }
            });
    });
});
