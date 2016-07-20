(function(){
    var ps = 9999;
    <& /comp/search_field.mas &>
    
    var store_sem=new Baseliner.JsonStore({
        root: 'data' , 
        remoteSort: true,
        totalProperty:"totalCount", 
        id: 'id', 
        url: '/semaphore/sems',
        fields: [ 
            {  name: 'key' },
            {  name: 'active' },
            {  name: 'slots' },
            {  name: 'maxslots' },
            {  name: 'busy' },
            {  name: 'waiting' }
        ]
    });

    var reader_queue = new Ext.data.JsonReader({
            root: 'data', 
            remoteSort: true,
            totalProperty:'totalCount', 
            id: 'id' 
        },
        [ 
            {  name: 'id' },
            {  name: 'key' },
            {  name: 'who' },
            {  name: 'status' },
            {  name: 'active' },
            {  name: 'host' },
            {  name: 'pid' },
            {  name: 'seq' },
            {  name: 'hostname' },
            {  name: 'caller' },
            {  name: 'wait_time' },
            {  name: 'run_time' },
            {  name: 'ts_request' },
            {  name: 'ts_grant' },
            {  name: 'ts_release' }
        ]
    );
    var store_queue = new Baseliner.GroupingStore({
        id: 'id',
        reader: reader_queue,
        remoteGroup: false,
        url: '/semaphore/queue',
        groupField: 'key'
    });


    var button_grant = new Ext.Button({
        text: _('Grant'),
        icon:'/static/images/icons/start.svg',
        cls: 'x-btn-text-icon',
        handler: function() {
            var sm = grid_queue.getSelectionModel();
            if ( sm.hasSelection() ) {
                var row = sm.getSelected();
                Baseliner.ajaxEval( '/semaphore/change_status', { id: row.data.id, status:'granted' }, function(res) {
                    Baseliner.message( _("Semaphore"), res.message ); 
                    store_queue.load();
                });
            }
        }
    });

    var button_cancel = new Ext.Button({
        text: _('Cancel'),
        icon:'/static/images/icons/stop.svg',
        cls: 'x-btn-text-icon',
        handler: function() {
            var sm = grid_queue.getSelectionModel();
            if ( sm.hasSelection() ) {
                var row = sm.getSelected();
                Baseliner.ajaxEval( '/semaphore/change_status', { id: row.data.id, status:'cancelled' }, function(res) {
                    Baseliner.message( _("Semaphore"), res.message ); 
                    store_queue.load();
                });
            }
        }
    });

    var button_purge = new Ext.Button({
        text: _('Purge'),
        icon:'/static/images/icons/error.svg',
        cls: 'x-btn-text-icon',
        handler: function() {
            var sm = grid_queue.getSelectionModel();
            if ( sm.hasSelection() ) {
                var row = sm.getSelected();
                Baseliner.ajaxEval( '/semaphore/purge', { }, function(res) {
                    Baseliner.message( _("Semaphore"), res.message ); 
                    store_queue.load();
                });
            }
        }
    });

    var sem_req_activate = function( active ) {
        var sm = grid_queue.getSelectionModel();
        if ( sm.hasSelection() ) {
            var row = sm.getSelected();
            Baseliner.ajaxEval( '/semaphore/activate', { id: row.data.id, active: active }, function(res) {
                Baseliner.message( _("Semaphore"), res.message ); 
                store_queue.load();
            });
        }
    };

    var button_activate = new Ext.Button({
        text: _('Activate'),
        icon:'/static/images/icons/lightbulb.svg',
        cls: 'x-btn-text-icon',
        handler: function() { sem_req_activate(1); }
    });

    var button_deactivate = new Ext.Button({
        text: _('Deactivate'),
        icon:'/static/images/icons/lightbulb_off.svg',
        cls: 'x-btn-text-icon',
        handler: function() { sem_req_activate(0); }
    });

    Baseliner.sem_mod = function(action, key) {
        Baseliner.ajaxEval( '/semaphore/change_slot', { key: key, action: action }, function(res) {
            Baseliner.message( key, res.message ); 
            store_sem.load();
        });
     };
     var button_add = new Ext.Button({
        icon:'/static/images/icons/add_green.svg',
        cls: 'x-btn-text-icon',
        handler: function() {
            Baseliner.ajaxEval( '/semaphore/change_slot', { key: key, action: action }, function(res) {
                Baseliner.message( key, res.message ); 
                store_sem.load();
            });
        }
    });

    var button_del = new Ext.Button({
        icon:'/static/images/icons/delete_green.svg',
        cls: 'x-btn-text-icon',
        handler: function() {  }
    });

    var button_sem_refresh = new Ext.Button({
        icon:'/static/images/icons/refresh.svg',
         tooltip:_('Refresh'),
        cls: 'x-btn-text-icon',
        handler: function() { store_sem.load(); }
    });

    var button_queue_refresh = new Ext.Button({
        icon:'/static/images/icons/refresh.svg',
         tooltip:_('Refresh'),
        cls: 'x-btn-text-icon',
        handler: function() { store_queue.load(); }
    });

    var render_sem = function(value,metadata,rec,rowIndex,colIndex,store) {
        var key = value;
        var is_infinite = rec.data.slots == -1;
        var is_stopped = rec.data.slots == 0;
        var strike = is_stopped ? 'color:#932;' : is_infinite ? 'color: #293' : ''; 
        return "<div style='font-weight:bold; font-size: 12px; "+strike+"'>" + key + "</div><br />" ;
    };

    var render_sem_data = function(value,metadata,rec,rowIndex,colIndex,store) {
    };

    var render_sem_actions = function(value,metadata,rec,rowIndex,colIndex,store) {
        var slots = rec.data.slots;
        var up = '<a href="#" onclick="javascript:Baseliner.sem_mod(\'add\', \''+ rec.data.key +'\', \''+rec.data.bl+'\' )">'
                + '<img src="/static/images/icons/arrow-up.svg"></img></a>';
        var down = slots > -1 
            ? '<a href="#" onclick="javascript:Baseliner.sem_mod(\'del\', \''+ rec.data.key +'\', \''+rec.data.bl+'\')">'
                + '<img src="/static/images/icons/arrow-down.svg"></img></a>'
            : '';
        return up + down;
    };

    Baseliner.queue_move = function(action,id_from,id_to) {
        Baseliner.ajaxEval( '/semaphore/queue_move', { id_from: id_from, id_to: id_to, action: action }, function(res) {
            Baseliner.message( _("Moved up"), res.message ); 
            store_queue.load();
        });
    };
    var render_actions = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( rec.data.status != 'waiting' ) return '';
        var up = rowIndex == 0
            ? '<img src="/static/images/icons/arrow-up.svg" style="visibility: hidden"></img>'
            : '<a href="#" onclick="javascript:Baseliner.queue_move(\'up\', \''+ rec.data.id +'\',\''+ store_queue.getAt(rowIndex-1).id+'\' )">'
                + '<img src="/static/images/icons/arrow-up.g"></img></a>';
        var down = rowIndex == store_queue.getCount() -1  
            ? ''
            : '<a href="#" onclick="javascript:Baseliner.queue_move(\'down\',\''+ rec.data.id +'\',\''+ store_queue.getAt(rowIndex+1).id +'\')">'
            + '<img src="/static/images/icons/arrow-down.svg"></img></a>';
        return up + down;
    };

    var render_status = function(value,metadata,rec,rowIndex,colIndex,store) {
        var img = value;
        if( value == 'waiting' ) 
            img = '<img src="/static/images/icons/busy.svg" alt="'+value+'"/>';
        else if( value == 'granted' )
            img = '<img src="/static/images/icons/start.svg" alt="'+value+'"/>';
        else if( value == 'busy' ) 
            img = '<img src="/static/images/loading-fast.gif" alt="'+value+'"/>';
        else if( value == 'idle' ) 
            img = '<img src="/static/images/icons/write.svg" alt="'+value+'"/>';
        else if( value == 'done' ) 
            img = '<img src="/static/images/icons/active.svg" alt="'+value+'"/>';
        else if( value == 'cancelled' ) 
            img = '<img src="/static/images/icons/stop.svg" alt="'+value+'"/>';
        else if( value == 'killed' ) 
            img = '<img src="/static/images/icons/error_red.svg" alt="'+value+'"/>';
        return img;
    };


    var grid_sem = new Ext.grid.GridPanel({
        region: 'west',
        title: _('Semaphores'),
        width: 300,
        expanded: true,
        animate : true,          
        hideHeaders: true,
        collapsible: true,
        split: true,
        stripeRows: false,
        autoScroll: true,
        autoWidth: true,
        store: store_sem,
        tbar: [ 
            new Ext.app.SearchField({
                store: store_sem,
                width: 100,
                params: {start: 0, limit: ps},
                emptyText: _('<Search>')
            }), //button_add, button_del,
            '->', button_sem_refresh
        ],
        viewConfig: {
                forceFit: true,
                enableRowBody: true,
                scrollOffset: 2,
                getRowClass : function(rec, index, p, store){
                        // slot squares
                        var slots = rec.data.slots;
                        var maxslots = rec.data.maxslots;
                        var occ = rec.data.busy || 0;
                        var waiting = rec.data.waiting || 0;
                        var is_infinite = rec.data.slots == -1;
                        p.body = String.format( '<div style="margin: 0 0 0 32;"><table><tr>'
                            + '<td style="width: 80px; background-color: #89cd79; padding: 2 4 2 4;"><center>{4}: {0}</td>'
                            + '<td style="width: 80px; background-color: #89cd79; padding: 2 4 2 4;"><center>{5}: {1}</td>'
                            + '<td style="width: 80px; background-color: #e7dc65; padding: 2 4 2 4;"><center>{6}: {2}</td>'
                            + '<td style="width: 80px; background-color: #ed9e9e; padding: 2 4 2 4;"><center>{7}: {3}</td>'
                            + '</tr></table></div>'
                            , slots, (is_infinite ? '\u221E' : maxslots), occ, waiting, _('slots'), _('max'), _('busy'), _('waiting') );
                        var css = '';
                        if( rec.data.active == 0  ) 
                            css = index % 2 > 0 ? 'level-row debug-odd' : 'level-row debug-even' ;
                        else
                            css = index % 2 > 0 ? 'level-row warn-odd' : 'level-row warn-even' ;

                        //p.body = '<p>'+_(rec.data.bl)+'</p>';
                        //return css + ' x-grid3-row-expanded';
                        return ' x-grid3-row-expanded';
                }
        },
        selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
        loadMask: true,
        columns: [
            { width: 20, sortable: false, renderer: function() { return '<img src="/static/images/icons/semaphore.svg" width="16px"/>' } },    
            { header: _('Semaphore'), width: 100, dataIndex: 'key', sortable: true, renderer: render_sem }, 
            { width: 50, dataIndex: 'key', renderer: render_sem_actions  }
        ]
    });
    var tbar_queue = new Ext.Toolbar({
        items: [ _('Search')+': ', ' ',
            new Ext.app.SearchField({
                store: store_queue,
                params: {start: 0, limit: ps},
                emptyText: _('<Enter your search string>')
            }),
            button_grant, button_cancel, 
            //button_activate, button_deactivate,
            '->', button_queue_refresh
        ]
    });
    var grouping = 'key';
    var gview = new Ext.grid.GroupingView({
        forceFit: true,
        enableRowBody: true,
        autoWidth: true,
        autoSizeColumns: true,
        deferredRender: true,
        startCollapsed: false,
        hideGroupedColumn: true,
        groupTextTpl: '{[ values.rs[0].data["' + grouping + '"] ]}'
    });
    var grid_queue = new Ext.grid.GridPanel({
        region: 'center',
        header: false,
        stripeRows: false,
        autoScroll: true,
        autoWidth: true,
        store: store_queue,
        tbar: tbar_queue,
        bbar: [
            _('Legend') + ': ',
            '<img class="icon_standar_size" src="/static/images/icons/busy.svg" />', _('Waiting'),
            '<img class="icon_standar_size" src="/static/images/icons/small_loading_static.svg" />', _('Busy'),
            '<img class="icon_standar_size" src="/static/images/icons/start.svg" />', _('Granted'),
            '<img class="icon_standar_size" src="/static/images/icons/stop.svg" />', _('Cancelled'),
            '<img src="/static/images/icons/active.svg" />', _('Done'),
            '<img class="icon_standar_size" src="/static/images/icons/error_red.svg" />', _('Killed')
        ],
        view: gview,
        viewConfig: {
                scrollOffset: 2,
                forceFit: true
        },
        selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
        loadMask: true,
        columns: [
            { header: _('Semaphore'), width: 200, hidden: true, dataIndex: 'key', sortable: false, menuDisabled: true },    
            { width: 30, dataIndex: 'status', sortable: false, renderer: render_status, menuDisabled: true},
            { header: _('Who'), width: 200, dataIndex: 'who', sortable: false , menuDisabled: true},    
            { header: _('Sequence'), width: 60, dataIndex: 'seq', sortable: false , menuDisabled: true}, 
            { header: _('Process'), width: 60, dataIndex: 'pid', sortable: false , menuDisabled: true}, 
            { header: _('Host'), width: 60, dataIndex: 'hostname', sortable: false , menuDisabled: true}, 
            { header: _('Status Text'), width: 100, dataIndex: 'status', hidden: true, sortable: false , menuDisabled: true},   
            { header: _('Requested On'), width: 100, dataIndex: 'ts_request', sortable: false , menuDisabled: true, renderer: Cla.render_date },    
            { header: _('Granted On'), width: 100, dataIndex: 'ts_grant', sortable: false , menuDisabled: true, renderer: Cla.render_date },    
            { header: _('Released On'), width: 100, dataIndex: 'ts_release', sortable: false, menuDisabled: true, renderer: Cla.render_date  }, 
            { header: _('Wait'), width: 100, dataIndex: 'wait_time', sortable: false, menuDisabled: true }, 
            { header: _('Run'), width: 100, dataIndex: 'run_time', sortable: false, menuDisabled: true }, 
            { header: _('Active'), width: 50, dataIndex: 'active', sortable: false, menuDisabled: true, renderer: Baseliner.render_active},
            { width: 100, renderer: render_actions, menuDisabled: true }
        ]
    });
    store_sem.load();
    store_queue.load();
    var panel = new Ext.Panel({
        layout: 'border',
        items: [
            grid_sem,
            grid_queue
        ]
    });

    var buttons_on_off = function() {
        var sm = grid_queue.getSelectionModel();
        if ( ! sm.hasSelection() ) return;
        var row = sm.getSelected();
        if( row.data.status != 'waiting' && row.data.status != 'idle' ) {
            button_activate.hide();
            button_deactivate.hide();
            return;
        }
        if( row.data.active == 1 ) {
            button_activate.hide();
            button_deactivate.show();
        } else {
            button_activate.show();
            button_deactivate.hide();
        }
        tbar_queue.doLayout();
    };
    grid_queue.on('rowclick', buttons_on_off ); 
    store_queue.on('load', buttons_on_off );
    button_activate.hide();
    button_deactivate.hide();
    return panel;
})()
