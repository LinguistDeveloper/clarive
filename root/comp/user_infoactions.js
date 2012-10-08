(function(params){
    var role = '<% $c->stash->{role} %>' ;

    var action_store=new Baseliner.JsonStore({
    root: 'data' , 
    remoteSort: true,
    totalProperty:"totalCount", 
    id: 'id', 
    url: '/user/infodetailactions',
    fields: [ 
        {name: 'action' },
        {name: 'description' },
        {name: 'bl' }			
        ]
    });
    
    var render_descriptions = function (val){
    if( val == null || val == undefined ) return '';
    var str = '';
    str = _(val);
    return str;
    }
    
    var ps = 100; //page_size
    action_store.load({ params: {role: role} }); 
    
    var cm = new Ext.grid.ColumnModel({
    defaults: {
            sortable: true // columns are not sortable by default           
            },
    columns: [
            { header: _('Action'), width: 150, dataIndex: 'action', sortable: false },	
            { header: _('Description'), width: 350, dataIndex: 'description', sortable: false, renderer: render_descriptions },
            { header: _('Baseline'), width: 50, dataIndex: 'bl', sortable: false}
        ]
    });
        
     var grid = new Ext.grid.GridPanel({
        title: _('Role Actions'),
        stripeRows: true,
        autoScroll: true,
        store: action_store,
        split: true,
        viewConfig: {
            forceFit: true
        },
    cm: cm,
        width: 350,
        height: 200
    });
 

    var win = new Ext.Window({ layout: 'fit', 
        autoScroll: true,
        title: role,
        height: 300,
        width: 675, 
        items: grid
    });
    return win;
});

