<%perl>
my $iid = Util->_md5;
</%perl>
(function(params){ 
    var id = params.id_div;

    var project_id = params.project_id;
    var topic_mid = params.topic_mid;
    var graph;
    var categories = params.data.categories || [];
    var assigned_to = params.data.assigned_to || '';
    var statuses = params.data.statuses || [];
    var not_in_status = params.data.not_in_status;
    var condition = params.data.condition || '';
    var limit = params.data.limit || 100;
    var sort = params.data.sort;
    var dir = params.data.dir;
    var rows = params.data.rows;
    var column_list = params.data.fields || '';
    var names = { name: 'ID', title: 'Title', assignee: 'Assignee', name_status: 'Status', created_by: 'Created By', created_on: 'Created On', modified_by: 'Modified By', modified_on: 'Modified On' };
    var columns = [{name:'name'}, {name:'title'}, {name:'name_status'}, {name:'created_by'}, {name:'created_on'}];//, {name:'modified_by'}, {name:'modified_on'}];
    var show_totals = params.data.show_totals || '';

    if ( column_list ) {
       var columns = [{name:'name'}];
       var all_columns = column_list.split(';');
       Ext.each( all_columns, function(column) {
          var col_tokens = column.split(',');
          var column = {};

          var col_name = col_tokens[0];
          column['name'] = col_name;

          if ( col_tokens[1] ) {
              names[col_name] = col_tokens[1];
          }
          if ( col_tokens[2] ) {
              column['type'] = col_tokens[2];
          }
          if ( col_tokens[3] ) {
              column['width'] = col_tokens[3];
          }
          if ( col_tokens[4] ) {
              column['total'] = col_tokens[4];
          }
          if ( col_tokens[5] ) {
              column['type_number'] = col_tokens[5];
          }
          if ( col_tokens[6] ) {
              column['symbol'] = col_tokens[6];
          }

          columns.push(column);
       })
    }

    Cla.ajax_json('/dashboard/list_topics', {
        topic_mid: topic_mid,
        project_id: project_id,
        limit: limit,
        sort: sort,
        dir: dir,
        assigned_to: assigned_to,
        condition: condition,
        not_in_status: not_in_status,
        categories: categories,
        statuses: statuses,
        show_totals: show_totals,
        _ignore_conn_errors: true
    }, function(res){
        var html = '<style>#boot .pagination a {line-height: 22px;} #boot .table td {padding: 3px} #boot .table th {padding: 3px}  #boot select {width: 60px;  height: 20px;line-height: 20px;} #boot input {width: 100px;height: 20px;padding:0px} #boot .pagination a {float: left;padding: 0 5px;}</style>';
        var div = document.getElementById(id);
        var totals = {};

        html = html + '<table class="table display stripe order-column compact" style="font-size: 85%;width: 100%" id="<% $iid %>"><thead><tr>';

        Ext.each( columns, function(col) {
          if ( col.width ) {
            html = html + '<th style="white-space:nowrap;width:' + col.width + 'px;">'+ _(names[col.name] || col.name) +'</th>';
          } else {
            html = html + '<th style="white-space:nowrap;">'+ _(names[col.name] || col.name) +'</th>';
          }
        });

        html = html + '</tr></thead>';
        html = html + '<tbody>';
        Ext.each( res.data, function(topic) {
          html = html + '<tr>';
          
          Ext.each( columns, function(col) {
            html = html + '<td>';
            if ( col.name == 'name' ) {
              html = html + '<span id="topic_'+topic.mid+'_<% $iid %>" class="label" onclick="javascript:Baseliner.show_topic_colored('+topic.mid+', \''+topic.category_name+'\', \''+topic.category_color+'\')" style="cursor:pointer;background:'+topic.category_color+'">'
              html = html + Baseliner.topic_title(topic.mid,topic.category_name,topic.category_color,true);
              html = html +'</span>';
            } else if ( col.name == 'title' ) {
              var title = topic.title;
              html = html + '<span style="display:block;width:100%;" title="'+title+'">'+title+'</span>'
            } else if ( col.name == 'projects' ) {
                var proj_names = new Array();
                Ext.each(topic.projects, function(proj){
                  var tokens = proj.split(';');
                  proj_names.push(tokens[1]);
                }
              )
              if ( proj_names.length > 1 ) {
                html = html + '<li>' +  proj_names.join('</li><li>') + '</li>';
              } else {
                html = html + proj_names.join('');
              }
            } else {
              if ( !col.type || col.type == 'text') {
                html = html + (topic[col.name] || '');
              } else if ( col.type == 'ci') {
                if ( topic[col.name] ) {
                    var value_list = [];
                    Ext.each(topic[col.name], function(value){
                      value_list.push(res.cis[value]);
                    })
                    if ( value_list.length > 1 ) {
                      html = html + '<li>' + value_list.join('</li><li>') + '</li>';
                    } else {
                      html = html + value_list.join('');
                    }
                }
              } else if ( col.type == 'checkbox') {
                if (!topic[col.name] || topic[col.name] == 0 || topic[col.name] == false ) {
                  html = html + '<div style="text-align:center;"><img src="/static/images/icons/topic_one.png"></div>';
                } else {
                  html = html + '<div style="text-align:center;"><img src="/static/images/icons/checkbox.png"></div>'
                }
              } else if ( col.type.match(/^number/) ) {
                var precision = 0;
                if ( topic[col.name] ) {
                  var regExp = /^number\((.*?)\)/;
                  var match = regExp.exec(col.type);
                  if ( match ) {
                    precision = match[1];
                  }

                  var colNameFixedPrecision = parseFloat(topic[col.name]).toFixed(precision);
                  if(col.type_number && col.type_number === 'currency'){
                    html = html + new NumberFormat(colNameFixedPrecision).toFormatted();
                  }else{
                    html = html + colNameFixedPrecision;
                  }

                  if(col.symbol){
                    html = html + " <b>" + col.symbol +"</b>"
                  }
                } else {
                  html = html + '';
                }
                if ( col.total && topic[col.name] && !jQuery.isArray( topic[col.name] ) && ( parseFloat( topic[col.name] ) - parseFloat( topic[col.name] ) + 1) >= 0) {
                  if ( totals[col.name] ) {
                    totals[col.name].sum = (parseFloat(totals[col.name].sum) + parseFloat(topic[col.name])).toFixed(precision);
                    totals[col.name].count = parseFloat(totals[col.name].count) + 1;
                    if(col.symbol){
                      totals[col.name].symbol = col.symbol;
                    }
                    if ( parseFloat(topic[col.name]).toFixed(precision) < totals[col.name].min) totals[col.name].min = parseFloat(topic[col.name]).toFixed(precision);
                    if ( parseFloat(topic[col.name]).toFixed(precision) > totals[col.name].max) totals[col.name].max = parseFloat(topic[col.name]).toFixed(precision);
                    totals[col.name].precision = precision;
                  } else {
                    totals[col.name] = { precision: precision, sum: parseFloat(topic[col.name]).toFixed(precision), count: 1, min: parseFloat(topic[col.name]).toFixed(precision), max: parseFloat(topic[col.name]).toFixed(precision) };
                  }
                } else if (col.total && !topic[col.name]) {
                  if ( totals[col.name] ) {
                    totals[col.name].count = parseFloat(totals[col.name].count) + 1;
                  } else {
                    totals[col.name] = { sum: 0, count: 1, min: 0, max: 0 };
                  }
                }
              }
            }
            html = html + '</td>';
          });
          html = html + '</tr>';
        });
        if ( show_totals ) {
          html = html + '<tfoot><tr>';
          var cont = 0;
          Ext.each( columns, function(col) {
            if ( cont++ == 0 ) {
              html = html + '<th>' + _('Totals') + '</th>';
            } else {
                if ( !totals[col.name] ) {
                  html = html + '<th></th>';
                } else {
                  var dataShown = totals[col.name][col.total];
                  if ( col.total == 'avg' ) {
                    dataShown = (parseFloat(totals[col.name].sum) / parseFloat(totals[col.name].count)).toFixed(totals[col.name].precision);
                  }
                  if(col.type_number && col.type_number === 'currency'){
                    html = html + '<th style="white-space:nowrap;">' + new NumberFormat(dataShown).toFormatted();
                  }else{
                    html = html + '<th style="white-space:nowrap;">'+ dataShown;
                  }
                  if(col.symbol){
                    html = html + " "+ col.symbol;
                  }
                   html = html + '</th>'
                }
            } 
          });
          html = html + '</tr></tfoot>';
        }

        html = html + '</tbody>';

        if(div) div.innerHTML = html;
        Baseliner.datatable("#<% $iid %>",{
          "scrollY": (parseInt(rows)*260),
          "dom": '<lf<t>ip>',
          "scrollX": true
        });
    });

});
