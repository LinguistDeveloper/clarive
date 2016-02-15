(function(params){ 
    var id = params.id_div;

    var project_id = params.project_id;
    var topic_mid = params.topic_mid;
    var graph_type = params.data.type || 'donut';
    var categories = params.data.categories || '';
    var statuses = params.data.statuses || '';
    var group_threshold = params.data.group_threshold || '5';
    var not_in_status = params.data.not_in_status;
    var condition = params.data.condition || '';
    var result_type = params.data.result_type || 'count';
    var numberfield_group = params.data.numberfield_group || '';
    var group_by = params.data.group_by || 'category.name';
    var sort_by_labels = params.data.sort_by_labels || 'off';
    var symbol = params.data.symbol || '';
    var number_type = params.data.number_type || 'number';
    var max_legend_length = params.data.max_legend_length || 0;

    var x_axis_label;
    if ( number_type === 'currency' ){
        x_axis_label = numberfield_group + ' ' + symbol + ' ('+ result_type +')';
    } else if ( number_type === 'percentage' ){
        x_axis_label = numberfield_group + '% ('+ result_type +')';
    } else {
        x_axis_label = _('Topics');
    }

    Cla.ajax_json('/dashboard/topics_by_field', { topic_mid: topic_mid, project_id: project_id, group_by: group_by,
                  condition: condition, not_in_status: not_in_status, group_threshold: group_threshold, 
                  categories: categories, statuses: statuses, numberfield_group: numberfield_group, 
                  result_type: result_type, _ignore_conn_errors: true, sort_by_labels: sort_by_labels, 
                  max_legend_length: max_legend_length }, function(res){

            c3.generate({
              bindto: '#'+id,
              data: {
                  columns: res.data,
                  type : graph_type,
                  colors: res.colors,
                  onclick: function (d, i) { 
                     Baseliner.add_tabcomp('/comp/topic/topic_grid.js', d.id , { topic_list: res.topics_list[d.id], 
                                            clear_filter: 1 });
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
                    text: '# ' + x_axis_label,
                    position: 'outer-middle',
                    format: function (value, ratio, id) {
                        return d3.format('')(value);
                    }
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
                     for ( i = 0; i < d.length; i++ ) {
                         if (! (d[i] && (d[i].value || d[i].value === 0))) { continue; }

                         if ( !text ) {
                             title = titleFormat ? titleFormat(d[i].x) : d[i].x;
                             text = "<table class='" + $$.CLASS.tooltip + "'>" + (title || title === 0 ? 
                                    "<tr><th colspan='2'>" + title + "</th></tr>" : "");
                         }

                         name = nameFormat(d[i].name);
                         value = valueFormat(d[i].value, d[i].ratio, d[i].id, d[i].index);
                         bgcolor = $$.levelColor ? $$.levelColor(d[i].value) : color(d[i].id);

                         text += "<tr class='" + $$.CLASS.tooltipName + "-" + d[i].id + "'>";
                         text += "<td class='name'><span style='background-color:" + bgcolor +
                                 "'></span>&nbsp;" + name + "</td>";
                         text += "<td class='value'>&nbsp;"
                         if ( result_type === 'count' ){
                            text += d[i].value;
                         } else {
                            if ( number_type === 'currency' ){
                                text += new NumberFormat(d[i].value ).toFormatted();
                                if (symbol !== ''){
                                  text += " " + symbol;
                                }
                            } else {
                                text += d[i].value;
                                if ( number_type === 'percentage' ){
                                  text += "%";
                                }
                            }
                         }
                         text += "</td>";
                         if ( !(isNaN(d[i].ratio)) ) {
                             text += ' (' + Math.round(d[i].ratio*100) + "%)";
                         }
                         text += "</td></tr>";
                     }
                     return text + "</table>";
                 }
              },
              pie: {
                  label: {
                      format: function (value, ratio, id) {
                        var adaptedValue = value;
                        if ( number_type === 'percentage' && result_type !== 'count' ){
                              adaptedValue += " %";
                        } else if ( number_type === 'currency' && result_type !== 'count' ){
                            adaptedValue = new NumberFormat(value).toFormatted();
                            if ( symbol !== '' ){
                                adaptedValue += " " + symbol;
                            }
                        }
                        return adaptedValue + ' (' + Math.round(ratio*100) + '%)';
                      }
                  }
              },
              donut: {
                  label: {
                      format: function (value, ratio, id) {
                        var adaptedValue = value;
                        if ( number_type === 'percentage' && result_type !== 'count' ){
                              adaptedValue += " %";
                        } else if ( number_type === 'currency' && result_type !== 'count' ){
                            adaptedValue = new NumberFormat(value).toFormatted();
                            if ( symbol !== '' ){
                              adaptedValue += " " + symbol;
                            }
                        }
                        return adaptedValue + ' (' + Math.round(ratio*100) + '%)';
                      }
                  }
              }
        });
    });
});
