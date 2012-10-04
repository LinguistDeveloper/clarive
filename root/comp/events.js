(function(params){
    var ps = 30;
    var Record = Ext.data.Record.create(
        [ 'event_key', 'event_status', 'event_data', 'description', 'ts',
            'data', 'type', 'dsl', 'output',
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

    Baseliner.event_output = function( id_grid, rownum ) {
        var g = Ext.getCmp( id_grid );
        var rec = g.getStore().getAt( rownum );
        var dataedit = new Ext.form.TextArea({ value: rec.data.output, style:'font-family:Consolas, Courier New, Courier' });
        var win = new Ext.Window({ layout:'fit', width:800, height: 400, items: dataedit, maximizable:true });
        win.show();
    };

    var render_data = function(value,metadata,rec,rowIndex,colIndex,store) {
        var arr = [];
        arr.push( String.format('<a href="javascript:Baseliner.event_data(\'{0}\', {1})"><img src="/static/images/icons/application.png" /></a>', grid.id, rowIndex ) );
        if( rec.data.type == 'rule' ) {
            arr.push( String.format('<a href="javascript:Baseliner.event_dsl(\'{0}\', {1})"><img src="/static/images/icons/application_go.png" /></a>', grid.id, rowIndex ) );
            arr.push( String.format('<a href="javascript:Baseliner.event_output(\'{0}\', {1})"><img src="/static/images/icons/application_edit.png" /></a>', grid.id, rowIndex ) );
        }
        return arr.join(' ');
    };
    
    var render_status = function(value,metadata,rec,rowIndex,colIndex,store) {
        var icon = value == 'ok' ? '/static/images/yes.png' :
                   value == 'ko' ? '/static/images/icons/delete.gif' :
                   value == 'new' ? '/static/images/icons/hourglass.png' : 
                   '/static/images/unknown.gif' ;

        return String.format('<img style="float:left" src="{0}" /><span style="font-weight:bold;">{1}</span>', icon, value );
    };
    
    var search_field = new Baseliner.SearchField({
        store: store_events,
        width: 280,
        params: {start: 0, limit: ps }
    });

    var del_event = function(){
        var sm = grid.getSelectionModel();
        if( sm.hasSelection() ) {
            var sels = sm.getSelections();
            var ids = [];
            Ext.each( sels, function(sel) {
                ids.push( sel.data.id ); 
            });
            Baseliner.ajaxEval('/event/del', { ids: ids }, function( res ){
                Baseliner.message( _('Event Delete'), res.msg );
                store_events.reload();
            });
        }
    };
    var event_status_change = function(event_status){
        if( ! event_status ) event_status = 'new';
        var sm = grid.getSelectionModel();
        if( sm.hasSelection() ) {
            var sels = sm.getSelections();
            var ids = [];
            Ext.each( sels, function(sel) {
                ids.push( sel.data.id ); 
            });
            Baseliner.ajaxEval('/event/status', { ids: ids, event_status: event_status }, function( res ){
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
            { header: _('Status'), width: 40, dataIndex: 'event_status', renderer: render_status },
            { header: _('Actions'), width: 120, dataIndex: 'id', renderer: render_data }
        ],
        tbar: [ 
            search_field,
            { icon:'/static/images/icons/refresh.gif', handler: function(){ store_events.reload(); }, tooltip:_('Reload') },
            { icon:'/static/images/icons/delete.gif', handler: del_event , tooltip:_('Delete event')},
            { icon:'/static/images/icons/hourglass.png', handler: function(){ event_status_change('new') }, tooltip:_('Reset event status') }
        ],
        bbar: new Ext.ux.maximgb.tg.PagingToolbar({
            store: store_events,
            pageSize: ps,
            displayInfo: true,
            displayMsg: _('Rows {0} - {1} of {2}'),
            emptyMsg: _('There are no rows available')
        })
    });
    return grid;
})
