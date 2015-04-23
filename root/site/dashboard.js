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
            <div class="row">
            <div class="span[%= dashlet.colspan || 24 %]" style="clear:left;" >
                <h2>[%= dashlet.name %]</h2>
                <div id="[%= id_div %]" 
                    style="width: 95%; height: 250px; float: left; " 
                    onmouseout="document.body.style.cursor='default';"><img src="/static/images/loading.gif" /></div>
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

            Ext.each( res.dashlets, function(dashlet){
                var id_div = Ext.id();
                var html = dashlet_tpl.tmpl({ dashlet: dashlet, id_div: id_div });
                $('.'+id_class).append(html);
                //$('.'+id_class).load(dashlet.html);
                Cla.ajaxEval(dashlet.js_file, { id_div: id_div, data: dashlet.data }, function(comp){ });
            });
        });
    },
    refresh_tab : function(){
        return new Cla.Dashboard(this);
    }
});

// dashlets common fields

Cla.dashlet_common = [
    new Cla.ComboSingle({ fieldLabel: _('Colspan'), name: 'colpan', value:'6', data:[1,2,3,4,5,6,7,8,9,10,11,12] })
];
