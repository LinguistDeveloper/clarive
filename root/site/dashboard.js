Cla.Dashboard = Ext.extend( Ext.Panel, {
    title : _('Dashboard'),
    closable: true,
    cls: 'tab-style',
    style: 'background-color: #FFF; padding: 0;',
    tab_icon: '/static/images/icons/dashboard.png',
    initComponent : function(){
        var self = this;
        Cla.Dashboard.superclass.initComponent.call(this);
        self.on('afterrender', function(){
            self.init();
        });
    },
    init : function(){
        var self = this;
        self.dashlets = {};
        var id_class = 'dashboard-' + self.body.id;
        var dashlet_tpl=function(){/*            
            <td id="[%= id_div %]_td" rowspan=[%= rowspan %] colspan=[%= colspan%] style='padding:10px;text-align:top;vertical-align:top;'>
              <div style='width: 100%;background-color: #FFF;border-radius: 25px;'>
                <div id="boot" style='width: 100%;padding:3px;background-color:#F7F7F7;font-weight:bold;margin-bottom:5px;'>
                    <table width='100%'>
                        <tr>
                            <td style='font-weight:bold;'>
                                [%= dashlet.title %]
                            </td>
                            <td style='font-weight:bold;'>
                                <div class='update-time' id="[%= id_div %]_update" style='font-size: 75%;'>
                                        [%= last_update %]
                                </div>
                            </td>
                            <td id="[%= id_div %]_icons" style='text-align:-moz-right;'>
                            </td>
                        </tr>
                    </table>
                </div>
                <div id="[%= no_boot=="1" ? 'no-' : '' %]boot">
                    <div id="[%= id_div %]" style="width: 100%; height: [%= dashlet.data.rows * 300 %]px;" onmouseout="document.body.style.cursor='default';">
                       <center><div style="width: 100%; margin-top: [%= dashlet.data.rows * 150 %]px"> <img style ='height:40px;width:40px;' src="/static/images/loading.gif" /></div></center>
                    </div>
                </div>
              </div>
            </td>
            <script>
                if ( "[%= autorefresh %]" != "0" ) {
                    setInterval(function () {
                        var obj = Ext.getCmp("[%= id_cmp %]");
                        if( obj ) obj.refresh_dashlet("[%= id_dashlet %]", true);
                    }, [%= autorefresh %]);
                };
            </script>

        */};
        Cla.ajax_json('/dashboard/init', {project_id: self.project_id, dashboard_id: self.dashboard_id, topic_mid: self.topic_mid }, function(res){
            self.body.update(function(){/*
                <style>
                    img:hover {
                        opacity: 1.0;
                        filter: alpha(opacity=100);
                    }
                </style>
                 <div id="no-boot" class="[%= id_class %]" style="width: 100%">
                 </div>
            */}.tmpl({ id_class: id_class, dashboards: res.dashboards }));

            var html_bootstrap="<div class='row-fluid' style='padding:2px;width:100%;'>";
            var html="<table style='border:1px;padding:2px;width:100%;table-layout:fixed;'><tr>";
            for (var i = 0; i < 12; i++) {
                html += "<td style='width:8.33%;'></td>"
            };
            html += "</tr><tr style='padding:10px;width:100%;'>";
            var cont=0;
            var rows = new Array();
            var form_report = new Ext.form.FormPanel({
                url: '/topic/report_html', renderTo:'run-panel', style:{ display: 'none'},
                items: [
                   { xtype:'hidden', name:'data_json'},
                   { xtype:'hidden', name:'title' },
                   { xtype:'hidden', name:'rows' },
                   { xtype:'hidden', name:'total_rows' },
                   { xtype:'hidden', name:'params' }
                ]
            });

            Ext.each( res.dashlets, function(dashlet){

                var export_data = function(dashlet, args){
                    var self = this;
                    var i;
                    var data = { rows:[], columns:[] };
                    var div = document.getElementById(dashlet.id_div);
                    console.log(div);
                    var columns_html = div.getElementsByTagName("table")[0].getElementsByTagName("th");
                    Ext.each( columns_html, function(column) {
                        data.columns.push({id: column.getAttribute("id"), name: column.getAttribute("used_name") })
                    });
                    var rows_html = div.getElementsByTagName("table")[1].getElementsByTagName("tbody")[0].getElementsByTagName("tr");
                    Ext.each( rows_html, function(row) {
                        var d = {};
                        var columns_rows = row.getElementsByTagName("td");
                        for ( i = 0; i< data.columns.length; i++ ){
                            d[ data.columns[i].id ] = columns_rows[i].innerHTML;
                        };
                        data.rows.push( d );
                    });
                    var form = form_report.getForm();
                    var rows_array = div.getElementsByClassName("dataTables_info")[0].innerHTML.split(" ");
                    form.findField('data_json').setValue( Ext.util.JSON.encode( data ) );
                    form.findField('title').setValue( dashlet.title );
                    form.findField('rows').setValue( rows_html.length );
                    form.findField('total_rows').setValue( rows_array[rows_array.length - 2] );
                    var el = form.getEl().dom;
                    var target = document.createAttribute("target");
                    target.nodeValue = args.target || "_blank";
                    el.setAttributeNode(target);
                    el.action = args.url;
                    el.submit();
                };

                if ( !rows[cont] ) rows.push(0);
                var buttons_tpl = new Ext.XTemplate(
                    '<table><tr>',
                    '<td><span id="{id_export_menu}" class="dashboard-buttons"></span></td>',
                    '<td><img class="dashboard-buttons"',
                       'src="/static/images/icons/config.gif"',
                       'onClick="javascript:var obj=Ext.getCmp(\'{id_cmp}\'); if(obj) obj.show_config(\'{id_dashlet}\')"',
                    '/>',
                    '<img class="dashboard-buttons"',
                        'src="/static/images/icons/refresh.gif"',
                        'onClick="javascript:var obj=Ext.getCmp(\'{id_cmp}\'); if(obj) obj.refresh_dashlet(\'{id_dashlet}\')"',
                    '/></td></tr></table>'
                );
                var id_div = Ext.id();
                var dashlet_columns = dashlet.data.columns ? parseInt(dashlet.data.columns): 6;
                if ( rows[cont] + dashlet_columns > 12 ){
                    html +="</tr><tr style='padding:10px;width:100%;'>";
                    if ( !rows[cont+1] ) {
                        rows.push(dashlet_columns);
                    } else {
                        rows[cont+1] += dashlet_columns;
                    }
                    cont++;
                } else {
                    rows[cont] = rows[cont] + dashlet_columns;
                }

                if ( parseInt(dashlet.data.rows) > 1 ) {
                    for (var i = 1; i < parseInt(dashlet.data.rows); i++) {
                        if ( !rows[cont+i] ) {
                            rows.push(dashlet_columns);
                        } else {
                            rows[cont+i] += dashlet_columns;
                        }
                    };
                }
                var now = new moment();
                var last_update = now.format("YYYY-MM-DD HH:mm:ss");
                dashlet.id_div = id_div;
                var dh = dashlet_tpl.tmpl({ id_cmp: self.id, autorefresh: dashlet.data.autorefresh || 0, last_update: last_update, 
                    id_dashlet: dashlet.id, js_file: dashlet.js_file, rowspan: dashlet.data.rows, 
                    no_boot: dashlet.no_boot,
                    colspan: dashlet.data.columns, 
                    dashlet: dashlet, id_div: id_div });
                html += dh;
                Cla.ajaxEval(dashlet.js_file, { id_div: id_div, project_id: self.project_id, topic_mid: self.topic_mid, data: dashlet.data }, function(){
                    var icons = document.getElementById(id_div + "_icons");
                    var exp_dashlet = dashlet.form === "/dashlets/list_topics_config.js";
                    var id_export_menu = dashlet.id + '-export';
                    if(icons) icons.innerHTML =  buttons_tpl.apply({
                        id_dashlet : dashlet.id,
                        id_cmp     : self.id,
                        exp_dashlet : exp_dashlet,
                        id_export_menu : id_export_menu
                    });
                    var btn_html = {
                        icon: '/static/images/icons/html.png',
                        current_dashlet: dashlet.id,
                        text: _('HTML'),
                        handler: function() {
                            var dashlet = self.dashlets[this.current_dashlet];
                            export_data(dashlet, { url: '/topic/report_html' });
                        }
                    };
                    var btn_yaml = {
                        icon: '/static/images/icons/yaml.png',
                        current_dashlet: dashlet.id,
                        text: _('YAML'),
                        handler: function() {
                            var dashlet = self.dashlets[this.current_dashlet];
                            export_data(dashlet, { no_html: true, url: '/topic/report_yaml' });
                        }
                    };
                    var btn_csv = {
                        icon: '/static/images/icons/csv.png',
                        current_dashlet: dashlet.id,
                        text: _('CSV'),
                        handler: function() {
                            var dashlet = self.dashlets[this.current_dashlet];
                            export_data(dashlet, { no_html: true, url: '/topic/report_csv', target: 'FrameDownload' });
                        }
                    };
                    if( exp_dashlet ){
                        var btn_reports = new Ext.Button({
                            icon: '/static/images/icons/exports.png',
                            renderTo: id_export_menu,
                            menu: [ btn_html, btn_csv, btn_yaml ]
                        });
                    };

                });
                self.dashlets[ dashlet.id ] = dashlet; 
            });
            $('.'+id_class).append(html+"</div>");
        });
        self.on('resize', function(){
            for(var id_dashlet in self.dashlets) {
                self.refresh_dashlet(id_dashlet);
            };
        });
    },
    refresh_tab : function(){
        return new Cla.Dashboard(this);
    },
    refresh_dashlet : function(id_dashlet, check_visible) {
        var self = this;
        var dashlet = self.dashlets[ id_dashlet ];
        var div = document.getElementById(dashlet.id_div);
        if( check_visible && ( !div || div.offsetWidth <= 0 || div.offsetHeight <= 0 ) ) return;  // if not visible, get out
        if(div) div.innerHTML= "<center><div style='width: 100%;height: 100%;padding-top:40%'><img style='height:40px;width:40px;' src=/static/images/loading.gif /></center></center>";
        Cla.ajaxEval(dashlet.js_file, { id_div: dashlet.id_div, project_id: self.project_id, topic_mid: self.topic_mid, data: dashlet.data }, function(){
            var update = document.getElementById(dashlet.id_div + "_update");
            var now = new moment();
            var last_update = now.format("YYYY-MM-DD HH:mm:ss");                            
            if(update) update.innerHTML=last_update;
        });
    },
    show_config : function(id_dashlet){
        var self = this;
        var dashlet = self.dashlets[ id_dashlet ];
        Baseliner.ajaxEval( dashlet.form, { data: dashlet.data }, function(comp){

            var save_form = function(){
                if( ! form.getForm().isValid() ) return;
                form.data = form.getValues();

                Baseliner.ci_call('user', 'save_dashlet_config', { data: form.data, id_dashlet:id_dashlet}, function(res){
                    Baseliner.message( _('Dashlet config'), res.msg ); 
                    win.close();
                    self.dashlets[ id_dashlet ].data = res.data;
                    self.refresh_dashlet(id_dashlet);
                });

                win.destroy();
            };

            var restore_originals = function(){
                Baseliner.ci_call('user', 'remove_dashlet_config', {id_dashlet:id_dashlet}, function(res){
                    Baseliner.message( _('Dashlet config'), res.msg ); 
                    win.close();
                    self.dashlets[ id_dashlet ].data = dashlet.data_orig;
                    self.refresh_dashlet(id_dashlet);
                });

                win.destroy();
            };

            var form = new Baseliner.FormPanel({ 
                frame: false, 
                forceFit: true, 
                defaults: { msgTarget: "under", anchor:"100%" },
                labelWidth: 150,
                width: 800, height: 600,
                labelAlign: "right",
                autoScroll: true,
                tbar: [
                    "->",
                    { xtype:"button", text:_("Restore originals"), icon:IC ('left'), handler: function(){ restore_originals() } },
                    { xtype:"button", text:_("Cancel"), icon:IC('cancel'), handler: function(){ win.destroy() } },
                    { xtype:"button", text:_("Save"), icon: IC('save'), handler: function(){ save_form() } }
                ],
                bodyStyle: { padding: "4px", "background-color": "#eee" },
                items: comp
            });

            var win = new Baseliner.Window(Ext.apply({
                layout: "fit",
                title: _("Configure"),
                items: form
            }));
            win.show();
        });
    }
});

// dashlets common fields

Cla.dashlet_common = (function(params){
    var data = params.data || {};
    return [
        {
            xtype: 'label',
            id: 'myFieldId',
            text: _('General dashlet'),
            bodyStyle: 'margin: 10px;',
            style: {
                // 'margin': '10px',
                'font-size': '12px',
                'font-weight': 'bold'
            }
        },
        { xtype:'panel', 
          hideBorders: true, 
          layout:'column', 
          bodyStyle: 'margin: 5px; padding: 5px 3px;background:transparent;',
          items:[
                {layout:'form', 
                 columnWidth: .48, 
                 bodyStyle: 'background:transparent;',
                 items: [
                    new Cla.ComboSingle({ anchor: '100%',fieldLabel: _('Height in canvas rows'), name: 'rows', value:data.rows?data.rows:'1', data:[1,2,3,4] }),
                    new Cla.ComboSingle({ anchor: '100%',fieldLabel: _('Width in canvas columns'), name: 'columns', value:data.columns?data.columns:'6', data:[2,3,4,6,8,10,12] })
                  ]
                },
                {layout:'form', 
                 columnWidth: .48, 
                 bodyStyle: 'background:transparent;',
                 items:
                    new Baseliner.ComboDouble({ anchor: '100%',fieldLabel: _('Autorefresh frequency in minutes (0 disabled)'), name: 'autorefresh', value:data.autorefresh?data.autorefresh:'0', data: [
                        [0, 0],
                        [60000, 1],
                        [300000, 5],
                        [600000, 10],
                        [900000, 15],
                        [1800000, 30],
                        [3600000, 60],
                        [7200000, 120],
                      ] 
                    })
                }
            ]
        }
    ];
});
