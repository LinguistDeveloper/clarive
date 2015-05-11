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
                         colors: {'FINISHED':'#5cb85c','ERROR':'#d9534f'}
                     },
                     axis: {
                       x : {
                         tick: {
                             format: function (x) { return ''; }
                         }
                       },
                       y: {
                         label: {
                           text: '# ' + _('Jobs'),
                           position: 'outer-middle'
                         }
                       }
                     },
                     pie: {
                         label: {
                             format: function (value, ratio, id) {
                                if ( isNaN(ratio) ) {
                                  return value;
                                } else {
                                  return value + ' (' + Math.round(ratio*100) + '%)';
                                }
                             }
                         }
                     },
                     donut: {
                         label: {
                             format: function (value, ratio, id) {
                                if ( isNaN(ratio) ) {
                                  return value;
                                } else {
                                  return value + ' (' + Math.round(ratio*100) + '%)';
                                }
                             }
                         },
                         title: title
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
                                text += "<td class='value'>&nbsp;" + d[i].value + ' (' + Math.round(d[i].ratio*100) + "%)</td>";
                                text += "</tr>";
                            }
                            return text + "</table>";
                        }
                     }
                });
            });
        });
    };

    $(function () {
        reload_dashlet( graph_period,graph_title );
    });
});
