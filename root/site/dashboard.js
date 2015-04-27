Cla.Dashboard = Ext.extend( Ext.Panel, {
    title : _('Dashboard'),
    closable: false, 
    cls: 'tab-style', 
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
        var id_class = 'dashboard-' + self.body.id;
        var dashlet_tpl=function(){/*            
            <div class="span[%= dashlet.data.columns || 24 %]" style='padding-top:5px'>
                <div style='width: 100%;padding:3px;background-color:#F7F7F7;font-weight:bold;margin-bottom:5px;'>
                    <table width='100%'>
                        <tr>
                            <td style='font-weight:bold;'>
                                [%= dashlet.data.title %]
                            </td>
                            <td id="[%= id_div %]_icons" style='text-align:right;'>
                            </td>
                        </tr>
                    </table>
                </div>
                <div id="[%= id_div %]" 
                    style="width: 100%; height: 250px;" 
                    onmouseout="document.body.style.cursor='default';"><img src="/static/images/loading.gif" />
                </div>
            </div>
        */};
        Cla.ajax_json('/dashboard/init', {}, function(res){

            self.body.update(function(){/*
                 <div id="boot" class="[%= id_class %]" style="width: 100%">
                    <div class="btn-group" style="float:right;margin-right:10px;">
                      <button class="btn btn-primary dropdown-toggle" data-toggle="dropdown">Dashboards <span class="caret"></span></button>
                      <ul class="dropdown-menu">
                        [% for(var i=0; i<dashboards.length; i++){ %]
                            <li><a href="javascript:Baseliner.addNewTabItem( new Cla.Dashboard({ dashboard_id: [%= dashboards[i].id %] }), _('[%= dashboards[i].name %]'), { tab_icon:'/static/images/icons/dashboard.png' });">[%= dashboards[i].name %]</a></li>
                        [% } %]
                      </ul>
                    </div>
                 </div>
            */}.tmpl({ id_class: id_class, dashboards: res.dashboards }));

            var html="<div class='row-fluid' style='padding-top:32px;width:95%;'>";
            var cont=0;
            Ext.each( res.dashlets, function(dashlet){
                var id_div = Ext.id();
                cont = cont + parseInt(dashlet.data.columns);
                if ( cont > 12 ){
                    html +="</div><div class='row-fluid' style='padding-top:10px;width:95%;'>";
                    cont=parseInt(dashlet.data.columns);
                }
                //$('.'+id_class).load(dashlet.html);
                html += dashlet_tpl.tmpl({ dashlet: dashlet, id_div: id_div });
                Cla.ajaxEval(dashlet.js_file, { id_div: id_div, data: dashlet.data }, function(reload){
                    if ( reload ) {
                        // reload_dashlet = reload;
                        function reload_dashlet() {
                            reload();
                        }
                        var icons = document.getElementById(id_div + "_icons");
                        icons.innerHTML = "<img src='/static/images/icons/refresh.gif' onClick='reload_dashlet();'>";
                    }
                });
            });
            $('.'+id_class).append(html+"</div>");
        });
    },
    refresh_tab : function(){
        return new Cla.Dashboard(this);
    }
});

// dashlets common fields

Cla.dashlet_common = (function(params){
    var data = params.data || {};
    return [
        { xtype:'textfield', fieldLabel: _('Title'), name: 'title', value: data.title?data.title:params.name, allowBlank: false },
        new Cla.ComboSingle({ fieldLabel: _('Columns'), name: 'columns', value:data.columns?data.columns:'1', data:[2,4,6,8,10,12] }),
        new Cla.ComboSingle({ fieldLabel: _('Rows'), name: 'rows', value:data.rows?data.rows:'1', data:[1,2,3,4,5,6] })
    ];
});

