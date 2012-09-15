(function(params){
    var ps = 30;
    var Record = Ext.data.Record.create(
        [ 'event_key', 'event_status', 'event_data', 'description', 'ts',
            'data', 'type', 'dsl',
            'mid', 'id', '_id', '_is_leaf', '_parent' ]
    );
     var store_events = new Ext.ux.maximgb.tg.AdjacencyListStore({  
       autoLoad : true,  
       url: '/event/log',
	   //baseParams: { topic_mid: data ? data.topic_mid : obj_topic_mid.getValue() == -1 ? '' : obj_topic_mid.getValue() },
       reader: new Ext.data.JsonReader({ id: '_id', root: 'data', totalProperty: 'total', successProperty: 'success' }, Record )
    });

    Baseliner.event_data = function( id_grid, rownum ) {
        var g = Ext.getCmp( id_grid );
        var rec = g.getStore().getAt( rownum );
        var dataedit = new Baseliner.DataEditor({ data: rec.data.data });
        var win = new Ext.Window({ layout:'fit', width:800, height: 400, items:dataedit });
        win.show();
    };
    Baseliner.event_dsl = function( id_grid, rownum ) {
        var g = Ext.getCmp( id_grid );
        var rec = g.getStore().getAt( rownum );
        var dataedit = new Ext.form.TextArea({ value: rec.data.dsl });
        var win = new Ext.Window({ layout:'fit', width:800, height: 400, items:dataedit });
        win.show();
    };

    var render_data = function(value,metadata,rec,rowIndex,colIndex,store) {
        var arr = [];
        arr.push( String.format('<a href="javascript:Baseliner.event_data(\'{0}\', {1})"><img src="/static/images/icons/application.png" /></a>', grid.id, rowIndex ) );
        if( rec.data.type == 'rule' ) 
            arr.push( String.format('<a href="javascript:Baseliner.event_dsl(\'{0}\', {1})"><img src="/static/images/icons/application.png" /></a>', grid.id, rowIndex ) );
        return arr.join(' ');
    };
    
    var search_field = new Baseliner.SearchField({
        store: store_events,
        width: 280,
        params: {start: 0, limit: ps }
    });

    var del_event = function(){
        var sm = grid.getSelectionModel();
        if( sm.hasSelection() ) {
            var sel = sm.getSelected();
            Baseliner.ajaxEval('/event/del', { id: sel.data.id }, function( res ){
                Baseliner.message( _('Event Delete'), res.msg );
                store_events.reload();
            });
        }
    };
    var grid = new Ext.ux.maximgb.tg.GridPanel({ 
        store: store_events,
        master_column_id : '_id',
        autoExpandColumn: '_id',
        stripeRows: true,
        viewConfig: {
            forceFit: true,
        //enableRowBody : true
        },
        columns:[
            { id:'_id', header: _("ID"), width: 60, sortable: false, dataIndex: '_id' },
            { header: _('Timestamp'), width: 80, dataIndex: 'ts' },
            { header: _('Event Key'), width: 160, dataIndex: 'event_key' },
            { header: _('Description'), width: 160, dataIndex: 'description' },
            { header: _('Status'), width: 40, dataIndex: 'event_status' },
            { header: _('Status'), width: 120, dataIndex: 'id', renderer: render_data }
        ],
        tbar: [ 
            search_field,
            { icon:'/static/images/icons/refresh.gif', handler: function(){ store_events.reload(); } },
            { icon:'/static/images/icons/delete.gif', handler: del_event }
        ]
    });
    return grid;
})
