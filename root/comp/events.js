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
        arr.push( String.format('<a href="javascript:Baseliner.event_data(\'{0}\', {1})"><img src="/static/images/icons/application.svg" /></a>', grid.id, rowIndex ) );
        if( rec.data.type == 'rule' ) {
            arr.push( String.format('<a href="javascript:Baseliner.event_dsl(\'{0}\', {1})"><img src="/static/images/icons/application_go.svg" /></a>', grid.id, rowIndex ) );
            arr.push( String.format('<a href="javascript:Baseliner.event_output(\'{0}\', {1})"><img src="/static/images/icons/application_edit.svg" /></a>', grid.id, rowIndex ) );
        }
        return arr.join(' ');
    };

    var render_status = function(value,metadata,rec,rowIndex,colIndex,store) {
        var icon = value == 'ok' ? '/static/images/icons/active.svg' :
                   value == 'ko' ? '/static/images/icons/error_red.svg' :
                   value == 'new' ? '/static/images/icons/busy.svg' :
                   '/static/images/icons/unknown.svg' ;

        return String.format('<img style="float:left" src="{0}" /><span style="font-weight:bold;">{1}</span>', icon, value );
    };

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

    var ptool = new Baseliner.PagingToolbar({
        store: store_events,
        pageSize: ps,
        plugins: [new Ext.ux.ProgressBarPager()],
        listeners: {
            pagesizechanged: function(pageSize) {
                searchField.setParam('limit', pageSize);
             }
        }
    });

    var searchField = new Baseliner.SearchField({
        store: store_events,
        width: 280,
        params: {start: 0, limit: ptool.pageSize },
        emptyText: _('<Enter your search string>')
    });


    var grid = new Ext.ux.maximgb.tg.GridPanel({
        renderTo: 'main-panel',
        cls:'events_grid',
        store: store_events,
        master_column_id : '_id',
        autoExpandColumn: '_id',
        viewConfig: {
        forceFit: true,
        },
        stripeRows: true,
        columns:[
            { id:'_id', header: _("ID"), width: 60, sortable: false, dataIndex: '_id' },
            { header: _('Timestamp'), width: 80, dataIndex: 'ts', renderer: Cla.render_date },
            { header: _('Event Key'), width: 160, dataIndex: 'event_key' },
            { header: _('Rule Log ID'), width: 40, hidden: true, dataIndex: 'id_rule_log' },
            { header: _('Event ID'), width: 40, hidden: true, dataIndex: 'id_event' },
            { header: _('Rule ID'), width: 40, hidden: true, dataIndex: 'id_rule' },
            { header: _('Description'), width: 160, dataIndex: 'description' },
            { header: _('Status'), width: 40, dataIndex: 'event_status', renderer: render_status },
            { header: _('Actions'), width: 120, dataIndex: 'id', renderer: render_data }
        ],
        tbar: [  _('Search') + ': ', ' ',
            searchField,' ',' ',
            { icon:'/static/images/icons/refresh.svg', handler: function(){ store_events.reload(); }, tooltip:_('Reload') },
            { icon:'/static/images/icons/delete.svg', handler: del_event ,
            text:_('Delete')},
            { icon:'/static/images/icons/restart_new.svg', handler: function(){ event_status_change('new') }, text:_('Reset event status') }
        ],
        bbar: ptool
    });
    return grid;
})
