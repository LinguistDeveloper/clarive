(function(params){
    
    //******************************* FILES
    var file_store = new Baseliner.JsonStore({
	    root: 'data' , 
	    remoteSort: true, totalProperty:"totalCount", id: 'id', url: '/changeman/files',
	    fields: ['id', 'path','jobname','ord', 'app', 'bl', 'date','mdate'] 
    });
    var style_cons = 'background: black; background-image: none; color: #10C000; font-family: "DejaVu Sans Mono", "Courier New", Courier';
    Baseliner.chmView = function(fileid){
        Baseliner.ajaxEval('/changeman/file_retrieve/' + fileid, {}, function(res){
            if( res.success ) {
                var p = new Ext.Panel({
                    layout: 'fit',
                    items: [{ xtype:'textarea', value: res.data, readOnly: true,
                        style: style_cons
                    }]
                });
                Baseliner.addNewTabItem( p,res.filename,  {} ); 
            } else {
                Ext.Msg.alert( _('Error'), res.msg );
            }
        });
    }
    var render_file = function( v,metadata,rec,rowIndex){
        return String.format('<a href="javascript:Baseliner.chmView(\'{1}\')" alt="{2}"><code>{0}</code></a>', v, rec.data.id, _('View file') );
    };
    var check_sm = new Ext.grid.CheckboxSelectionModel({ singleSelect: false, sortable: false, checkOnly: true });
    var file_grid = new Ext.grid.GridPanel({
        store: file_store,
	    stripeRows: true,
	    viewConfig: {forceFit: true	},
	    loadMask: true,
        sm: check_sm,
        delete_url: '/changeman/file_delete',
	    //deferredRender: true,
	    autoScroll: true,
	    autoWidth: true,
        columns: [
            check_sm,
            { dataIndex:'path', header:_('File'), width: 300, sortable: true, renderer: render_file },
            { dataIndex:'app', header:_('Application'), width: 30, sortable: false },
            { dataIndex:'bl', header:_('Baseline'), width: 30, sortable: false },
            { dataIndex:'date', header:_('Date'), width: 50, sortable: true },
            { dataIndex:'mdate', header:_('File Date'), width: 50, sortable: true },
            { dataIndex:'jobname', header:_('JobName'), width: 50, sortable: false },
            { dataIndex:'ord', header:_('Order'), width: 80, sortable: false }
        ]
    });
    var del_row = function(){
        var ids = [];
        var panel = card.getLayout().activeItem;
        var sm = panel.getSelectionModel();
        Ext.each( sm.getSelections(), function(row){
            ids.push( row.data.id );
        });
        if( ids.length > 0 ){
            var url = panel.delete_url; 
            Baseliner.confirm( _('Are you sure you want to delete %1 row(s)?', ids.length ), function(){ 
                Baseliner.ajaxEval( panel.delete_url, { ids: ids }, function(res){
                    if( res.success ) {
                        Baseliner.message( _('Changeman'), _('%1 row(s) deleted.', ids.length ) );
                        panel.getStore().reload();
                    } else {
                        Ext.Msg.alert( _('Error'), res.msg );
                    }
                });
            });
        }
    };
    var search = new Baseliner.SearchField({
			    store: event_store,
			    params: {},
			    emptyText: _('<Enter your search string>')
		    });

    //******************** EVENT LOG
    var event_store = new Baseliner.JsonStore({
	    root: 'data' , 
	    remoteSort: true, totalProperty:"totalCount", id: 'ns', url: '/changeman/events',
	    fields: ['id', 'ns', 'yaml','ts','msg','data','line','file','class'] 
    });
    var render_data = function( v) {
        if( ! v ) return '';
        if( ! typeof v == 'Object' ) return '';
        if( v.length < 1 ) return '';
        return String.format( '<ul><li>{0}</li>', v.join('</li><li>') );
    }
    var render_data2 = function( hash) {
        if( !hash ) return '';
        if( ! typeof hash == 'Object' ) return '';
        var ret = [];
        for( var k in hash ) {
            var v = hash[k];
            if( typeof v == 'object' ) v='';
            ret.push( String.format('<b>{0}</b>: {1}', k, v ) );
        }
        return Baseliner.render_wrap( ret.join(', ') );
    }
    var render_class_line = function( v,meta,rec) {
        if( ! v ) return '';
        return String.format( '{0}:{1}', v, rec.data.line );
    }
    Baseliner.chmLogView= function( ns ){
        Baseliner.ajaxEval('/changeman/ns_view', { ns: ns }, function(res){
            if( res.success ) {
                var p = new Ext.Panel({
                    layout: 'fit',
                    items: [{ xtype:'textarea', value: res.data, readOnly: true,
                        style: style_cons
                    }]
                });
                Baseliner.addNewTabItem( p, _('%1', ns),  {} ); 
            } else {
                Ext.Msg.alert( _('Error'), res.msg );
            }
        });
    }
    var render_message = function( v,meta,rec) {
        if( ! v ) return '';
        return String.format('<a href="javascript:Baseliner.chmLogView(\'{1}\')">{0}</a>', v, rec.data.ns );
    }
    var check_sm2 = new Ext.grid.CheckboxSelectionModel({ singleSelect: false, sortable: false, checkOnly: true });
    var event_grid = new Ext.grid.GridPanel({
        store: event_store,
	    stripeRows: true,
	    viewConfig: {forceFit: true	},
	    loadMask: true,
        sm: check_sm2,
        delete_url: '/changeman/ns_delete',
	    //deferredRender: true,
	    autoScroll: true,
	    autoWidth: true,
        columns: [
            check_sm2,
            { dataIndex:'ts', header:_('Date'), width: 50, sortable: false },
            { dataIndex:'msg', header:_('Message'), width: 200, sortable: false, renderer: render_message },
            { dataIndex:'data', header:_('Data'), width: 200, sortable: false, renderer: render_data },
            { dataIndex:'class', header:_('Where'), width: 40, sortable: false, renderer: render_class_line },
            { dataIndex:'yaml', header:_('YAML'), width: 200, sortable: false, hidden: true, renderer: Baseliner.render_wrap },
            { dataIndex:'ns', header:_('Id'), width: 30, sortable: false }
        ]
    });

    //******************** PACKAGES
    var pkg_store = new Baseliner.JsonStore({
	    root: 'data' , 
	    remoteSort: true, totalProperty:"totalCount", id: 'ns', url: '/changeman/packages',
	    fields: ['data', 'ns','ts','item','user'] 
    });
    var check_sm3 = new Ext.grid.CheckboxSelectionModel({ singleSelect: false, sortable: false, checkOnly: true });
    var render_pkg = function( v,meta,rec) {
        if( ! v ) return '';
        return String.format('<a href="javascript:Baseliner.chmLogView(\'{1}\')"><b>{0}</b></a>', v, rec.data.ns );
    }
    var pkg_grid = new Ext.grid.GridPanel({
        store: pkg_store,
	    stripeRows: true,
	    viewConfig: {forceFit: true	},
	    loadMask: true,
        sm: check_sm3,
        delete_url: '/changeman/ns_delete',
	    //deferredRender: true,
	    autoScroll: true,
	    autoWidth: true,
        columns: [
            check_sm3,
            { dataIndex:'item', header:_('Package'), width: 60, sortable: false, renderer: render_pkg },
            { dataIndex:'ns', header:_('ID'), width: 60, sortable: false },
            { dataIndex:'user', header:_('User'), width: 60, sortable: false },
            { dataIndex:'ts', header:_('Date'), width: 50, sortable: false },
            { dataIndex:'data', header:_('Data'), width: 300, sortable: false, renderer: render_data2 }
        ]
    });

    //******************** MAIN CARD COMP 
    var card = new Ext.Panel({
        layout: 'card',
        activeItem: 0,
        title: _('Changeman'),
        tab_icon: '/changeman/chm.gif',
        tbar: [
            search, 
            { iconCls:'x-btn-icon', icon:'/static/images/icons/refresh.gif', handler: function(){ card.getLayout().activeItem.getStore().reload() } },
            '-',
            _('View'),
            ':',
            { text:_('Log'), iconCls:'x-btn-text-icon', icon:'/static/images/icons/detail.png', pressed: true, toggleGroup: 'chmCard', allowDepress: false,
                handler: function(){ card.getLayout().setActiveItem(0) }
            },
            { text:_('Files'), iconCls:'x-btn-text-icon', icon:'/static/images/icons/files.gif', pressed: false, toggleGroup: 'chmCard', allowDepress: false,
                handler: function(){ card.getLayout().setActiveItem(1) }
            },
            { text:_('Packages'), iconCls:'x-btn-text-icon', icon:'/changeman/package.gif', pressed: false, toggleGroup: 'chmCard', allowDepress: false,
                handler: function(){ card.getLayout().setActiveItem(2) }
            },
            '-',
            { text:_('Delete'), iconCls:'x-btn-text-icon', icon:'/static/images/icons/delete.gif', handler: del_row }
        ],
        items: [
            event_grid, file_grid, pkg_grid
        ]
    });
    card.on( 'afterrender', function(){
        //card.setActiveItem( file_grid );
    });

    // load on first render
    var eflag = true;
    event_grid.on('activate', function(){
        if( eflag ) {
            event_store.load();
            eflag = false;
        }
        search.store = event_store;
    });
    var fflag = true;
    file_grid.on('activate', function(){
        if( fflag ) {
            file_store.load();
            fflag = false;
        }
        search.store = file_store;
    });
    var pflag = true;
    pkg_grid.on('activate', function(){
        if( pflag ) {
            pkg_store.load();
            pflag = false;
        }
        search.store = pkg_store;
    });
    return card;
})
