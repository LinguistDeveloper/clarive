(function(params){
    var ps = 20;
    var Record = Ext.data.Record.create(
        [ 'event_key', 'event_status', 'event_data', 'description', 'ts',
            'data', 'type', 'id_rule', 'id_rule_log', 'id_event', 
            'mid', 'id', '_id', '_is_leaf', '_parent' ]
    );
     var store_events = new Ext.ux.maximgb.tg.AdjacencyListStore({  
       autoLoad : true,  
       url: '/event/log',
	   //baseParams: { topic_mid: data ? data.topic_mid : obj_topic_mid.getValue() == -1 ? '' : obj_topic_mid.getValue() },
       reader: new Ext.data.JsonReader({ id: '_id', root: 'data', totalProperty: 'totalCount', successProperty: 'success' }, Record )
    });

    Baseliner.event_data = function( id_grid, rownum ) {
        var g = Ext.getCmp( id_grid );
        var rec = g.getStore().getAt( rownum );
        Baseliner.ajaxEval('/event/event_data', { id_event: rec.data.id_event, id_rule_log: rec.data.id_rule_log, type: 'stash' }, function(res){
            var output = new Ext.form.TextArea({ value: res.data, style:'font-family:Consolas, Courier New, Courier' });
            var win = new Baseliner.Window({ layout:'fit', width:800, height: 400, items: output });
            win.show();
        });
    };
    Baseliner.event_dsl = function( id_grid, rownum ) {
        var g = Ext.getCmp( id_grid );
        var rec = g.getStore().getAt( rownum );
        Baseliner.ajaxEval('/event/event_data', { id_rule_log: rec.data.id_rule_log, type:'dsl' }, function(res){
            var dsl = new Ext.form.TextArea({ value: res.data });
            var win = new Baseliner.Window({ layout:'fit', width:800, height: 400, items: dsl });
            win.show();
        });
    };

    Baseliner.event_output = function( id_grid, rownum ) {
        var g = Ext.getCmp( id_grid );
        var rec = g.getStore().getAt( rownum );
        Baseliner.ajaxEval('/event/event_data', { id_rule_log: rec.data.id_rule_log, type:'output' }, function(res){
            var output = new Ext.form.TextArea({ value: res.data, style:'font-family:Consolas, Courier New, Courier' });
            var win = new Baseliner.Window({ layout:'fit', width: 800, height: 400, items: output, maximizable:true });
            win.show();
        });
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
                Baseliner.message( _('Event Status Changed'), res.msg );
                store_events.reload();
            });
        }
    };
    Baseliner.PagingToolbar = Ext.extend( Ext.PagingToolbar, {
        onLoad: function(store,r,o) {
            var p = this.getParams();
            if( o.params && o.params[p.start] ) {
                var st = o.params[p.start];
                var ap = Math.ceil((this.cursor+this.pageSize)/this.pageSize);
                if( ap > this.getPageData().pages ) { 
                    delete o.params[p.start];
                }
            }
            Baseliner.PagingToolbar.superclass.onLoad.call(this,store,r,o);
        }
    });
    var ps_plugin = new Ext.ux.PageSizePlugin({
        editable: false,
        width: 90,
        data: [
            ['5', 5], ['10', 10], ['15', 15], ['20', 20], ['25', 25], ['50', 50],
            ['100', 100], ['200',200], ['500', 500], ['1000', 1000], [_('all rows'), -1 ]
        ],
        beforeText: _('Show'),
        afterText: _('rows/page'),
        value: ps,
        listeners: {
            'select':function(c,rec) {
                ps = rec.data.value;
                if( rec.data.value < 0 ) {
                    ptool.afterTextItem.hide();
                } else {
                    ptool.afterTextItem.show();
                }
            }
        },
        forceSelection: true
    });

    var ptool = new Baseliner.PagingToolbar({            
        store: store_events,
        pageSize: ps,
        plugins:[
            ps_plugin,
            new Ext.ux.ProgressBarPager()
        ],
        displayInfo: true,
        displayMsg: _('Rows {0} - {1} of {2}'),
        emptyMsg: _('There are no rows available')
    });

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
            { header: _('Rule Log ID'), width: 40, hidden: true, dataIndex: 'id_rule_log' },
            { header: _('Event ID'), width: 40, hidden: true, dataIndex: 'id_event' },
            { header: _('Rule ID'), width: 40, hidden: true, dataIndex: 'id_rule' },
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
        bbar: ptool
    });
    return grid;
})
