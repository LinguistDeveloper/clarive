Cla.Dashboard = Ext.extend( Ext.Panel, {
    title : _('Dashboard'),
    closable: true,
    cls: 'tab-style',
    style: 'background-color: #FFF;',
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
        var dashlet_tpl_bootstrap=function(){/*            
            <div class="span[%= dashlet.data.columns || 24 %]" style='padding-top:5px'>
                <div style='width: 100%;padding:3px;background-color:#F7F7F7;font-weight:bold;margin-bottom:5px;'>
                    <table width='100%'>
                        <tr>
                            <td style='font-weight:bold;'>
                                [%= dashlet.title %]
                            </td>
                            <td id="[%= id_div %]_icons" style='text-align:right;'>
                            </td>
                        </tr>
                    </table>
                </div>
                <div style='width: 100%;padding:1px;background-color:#FFF;margin-bottom:5px;text-align:center;font-size: 75%;'>
                        [%= last_update %]
                </div>
                <div id="[%= id_div %]" 
                    style="width: 100%; height: [%= dashlet.data.rows * 300 %]px;" 
                    onmouseout="document.body.style.cursor='default';"><img src="/static/images/loading.gif" />
                </div>
            </div>
        */};
        var dashlet_tpl=function(){/*            
            <td id="[%= id_div %]_td" rowspan=[%= rowspan %] colspan=[%= colspan%] style='padding:10px;'>
              <div style='width: 100%;background-color: #FFF;border-radius: 25px;'>
                <div style='width: 100%;padding:3px;background-color:#F7F7F7;font-weight:bold;margin-bottom:5px;'>
                    <table width='100%'>
                        <tr>
                            <td style='font-weight:bold;'>
                                [%= dashlet.title %]
                            </td>
                            <td style='font-weight:bold;'>
                                <div id="[%= id_div %]_update" style='color:#BBB;width: 100%;padding:3px;text-align:center;font-size: 75%;'>
                                        [%= last_update %]
                                </div>
                            </td>
                            <td id="[%= id_div %]_icons" style='text-align:right;'>
                            </td>
                        </tr>
                    </table>
                </div>
                <div id="[%= id_div %]" 
                    style="width: 100%; height: [%= dashlet.data.rows * 300 %]px;text-align:center;vertical-align:middle;" 
                    onmouseout="document.body.style.cursor='default';"><img src="/static/images/loading.gif" />
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
        Cla.ajax_json('/dashboard/init', {dashboard_id: self.dashboard_id}, function(res){
            self.body.update(function(){/*
                <style>
                    img:hover {
                        opacity: 1.0;
                        filter: alpha(opacity=100);
                    }
                </style>
                 <div id="boot" class="[%= id_class %]" style="width: 100%">
                 </div>
            */}.tmpl({ id_class: id_class, dashboards: res.dashboards }));

            var html_bootstrap="<div class='row-fluid' style='padding:32px;width:100%;'>";
            var html="<table style='border:1px;padding:32px;width:100%;table-layout:fixed;'><tr>";
            for (var i = 0; i < 12; i++) {
                html += "<td style='width:8.33%;'></td>"
            };
            html += "</tr><tr style='padding:10px;width:100%;'>";
            var cont=0;
            var rows = new Array();
            Ext.each( res.dashlets, function(dashlet){
                if ( !rows[cont] ) rows.push(0);
                var buttons_tpl = function(){/*
                    <img style='cursor:pointer;opacity: 0.4;' 
                        src='/static/images/icons/config.gif' 
                        onClick='javascript:var obj=Ext.getCmp("[%= id_cmp %]"); if(obj) obj.show_config("[%= id_dashlet %]")'
                    />
                    <img style='cursor:pointer;opacity: 0.4;'
                         on 
                         src='/static/images/icons/refresh.gif' 
                         onClick='javascript:var obj=Ext.getCmp("[%= id_cmp %]"); if(obj) obj.refresh_dashlet("[%= id_dashlet %]")' />
                */};
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
                    colspan: dashlet.data.columns, 
                    dashlet: dashlet, id_div: id_div });
                html += dh;
                Cla.ajaxEval(dashlet.js_file, { id_div: id_div, data: dashlet.data }, function(){
                    var icons = document.getElementById(id_div + "_icons");
                    if(icons) icons.innerHTML = buttons_tpl.tmpl({
                        id_dashlet : dashlet.id,
                        id_cmp     : self.id
                    });
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
        if(div) div.innerHTML= "<img src=/static/images/loading.gif />";
        Cla.ajaxEval(dashlet.js_file, { id_div: dashlet.id_div, data: dashlet.data }, function(){
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
                frame: false, forceFit: true, defaults: { msgTarget: "under", anchor:"100%" },
                labelWidth: 150,
                width: 800, height: 600,
                labelAlign: "right",
                autoScroll: true,
                tbar: [
                    "->",
                    { xtype:"button", text:_("Restore originals"), icon:"/static/images/icons/left.png", handler: function(){ restore_originals() } },
                    { xtype:"button", text:_("Cancel"), icon:"/static/images/icons/delete.gif", handler: function(){ win.destroy() } },
                    { xtype:"button", text:_("Save"), icon:"/static/images/icons/save.png", handler: function(){ save_form() } }
                ],
                bodyStyle: { padding: "4px", "background-color": "#fff" },
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
        new Cla.ComboSingle({ fieldLabel: _('Height of dashlet (rows)'), name: 'rows', value:data.rows?data.rows:'1', data:[1,2] }),
        new Cla.ComboSingle({ fieldLabel: _('Width of dashlet (columns)'), name: 'columns', value:data.columns?data.columns:'6', data:[2,3,4,6,8,10,12] }),
        new Baseliner.ComboDouble({ fieldLabel: _('Autorefresh frequency in minutes (0 disabled)'), name: 'autorefresh', value:data.autorefresh?data.autorefresh:'0', data: [
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

    ];
});
