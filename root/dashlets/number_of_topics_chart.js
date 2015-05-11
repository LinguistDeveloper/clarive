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
        document.getElementsByTagName('head')[0].appendChild(styleNode);            
        require(['d3','c3'], function(d3,c3){
            var styleNode = document.createElement('style');
            styleNode.type = "text/css";
            // browser detection (based on prototype.js)
            if(!!(window.attachEvent && !window.opera)) {
                styleNode.styleSheet.cssText = '.c3-chart-arc text { font-size: 10px; }';
            } else {
                var styleText = document.createTextNode('.c3-chart-arc text { font-size: 10px; }');
                styleNode.appendChild(styleText);
            }
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
                },
                pie: {
                    label: {
                        format: function (value, ratio, id) {
                            return '<span style="font-size: 11px;">'+value + ' (' + Math.round(ratio*100) + '%)'+'</span>';
                        }
                    }
                },
                donut: {
                    label: {
                        format: function (value, ratio, id) {
                            return value + ' (' + Math.round(ratio*100) + '%)';
                        }
                    }
                },

            });
        });
    });

});
