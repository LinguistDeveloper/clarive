(function(params){
    delete params['tab_index'];  // this comes from the tab data
    var ps = 30;

    var record = Ext.data.Record.create([ 'mid','_id','bl', '_parent','_is_leaf',
        'type', 'pretty_properties', 'name', 'item', 'ci_form',
        'class','versionid','ts','tags','data','properties','icon','collection']);

    var store_ci = new Ext.ux.maximgb.tg.AdjacencyListStore({  
       autoLoad : true,  
       url: '/ci/gridtree',
       baseParams: params,
       reader: new Ext.data.JsonReader({ id: '_id', root: 'data', totalProperty: 'total', successProperty: 'success' }, record )
    }); 

    var search_field = new Baseliner.SearchField({
        store: store_ci,
        params: {start: 0, limit: ps },
        emptyText: _('<Enter your search string>')
    });
    
    // only globals can be seen from grid
    Baseliner.ci_edit = function( gridid, ix ){
        var g = Ext.getCmp( gridid );
        if( g!= undefined ) 
            ci_edit( g.getStore().getAt(ix).data );
    };

    var ci_edit = function(rec){
        var data = store_ci.baseParams;
        var classname = data.class ;
        Baseliner.ajaxEval( '/ci/load', { mid: rec.mid }, function(res) {
            if( res.success ) {
                var rec = res.rec;
                console.log( rec );
                Baseliner.add_tabcomp( '/comp/ci-editor.js', _('CI %1' , rec.name ), 
                    {
                        _parent_grid: ci_grid,
                        collection: data.collection,
                        data: data,
                        has_bl: data.has_bl,
                        class: data.class,
                        ci_form: rec.ci_form,
                        mid: rec.mid,
                        rec: rec,
                        tab_icon: rec.icon,
                        action: 'edit'
                    }
                );
            } else {
                Ext.Msg.alert( _('Error'), _(res.msg) );
            }
        });
    };

    // only globals can be seen from grid
    Baseliner.ci_add = function( gridid, ix ){
        var g = Ext.getCmp( gridid );
        if( g!= undefined ) 
            ci_add( g.getStore().getAt(ix).data );
    };

    var ci_add = function(){
        var data = store_ci.baseParams;
        var classname = data.class ;
        var rec = {};
        if (check_sm.hasSelection()) {
           var sel = check_sm.getSelections();
           rec = sel[0].data;
           rec.name = _('Copy of %1', rec.name );
        } 
        Baseliner.add_tabcomp( '/comp/ci-editor.js', _('New: %1' , params.item ), {
                _parent_grid: ci_grid,
                ci_form: data.ci_form,
                collection: data.collection,
                has_bl: data.has_bl,
                rec: rec,
                data: data,
                class: data.class,
                tab_icon: data.icon,
                action: 'add'
        });
    };

    // Usage:   var checked = Baseliner.multi_check_data( check_sm, 'mid' );
    Baseliner.multi_check_data = function(obj, field){
       if (obj.hasSelection()) {
           var sel = obj.getSelections();
           var data = [];
           for( var i=0; i<sel.length; i++ ) {
               data.push( sel[i].data[field] );
           }
           return { count: data.length, data: data };
       }
       return { count: 0, data:[] };
    };

    var ci_delete = function(){
        var checked = Baseliner.multi_check_data( check_sm, 'mid' );
        if ( checked.count > 0 ) {
            Baseliner.ajaxEval( '/ci/delete', { mids: checked.data }, function(res) {
                if( res.success ) {
                    Baseliner.message(_('CI'), res.msg );
                    check_sm.clearSelections();  // otherwise it refreshes current selected nodes
                    ci_grid.getStore().reload();
                } else {
                    Ext.Msg.alert( _('CI'), res.msg );
                }
            });
        }
    };

    /*  Renderers */
    var render_tags = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( typeof value == 'object' ) {
            var va = value.slice(0); // copy array
            return Baseliner.render_tags( va, metadata, rec );
        } else {
            return Baseliner.render_tags( value, metadata, rec );
        }
    };
    var render_item = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( rec.data.type == 'class' ) {
            // we create objects
            value = String.format('<a href="javascript:Baseliner.ci_add(\'{0}\',{1})">{2}</a>', ci_grid.id, rowIndex, value );
        }
        var ed = String.format('Baseliner.ci_edit(\'{0}\',{1})', ci_grid.id, rowIndex, value );
        var ret = '<table><tr><td width="1">';
        ret += '<img style="margin-top:-2px" src="' + rec.data.icon + '" alt="edit" />';
        ret += '</td><td><b><a href="javascript:'+ed+'" onmouseover="this.style.cursor=\'pointer\'">' + value + '</a></b></td></tr></table>';
        return ret;
    };
    var render_properties = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( value == undefined ) return '';
        return '<pre style="font-size:9px">' + value + '</pre>';
    };
    var render_datadiv = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( value == undefined ) return '';
        return '<code>' + value + '</code>'; //<img src="/static/images/icons/expandall.gif" onclick="Baseliner.ci_data_win(' + rec.data.mid + ')" />';
    };
    var render_mapping_long = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( value == undefined ) return '';
        if( typeof value == 'string' ) return '';
        var ret = '';
        var k = 0;
        var ary =[];
        for( var k in value ) {
            if( value[k]==undefined ) value[k]='';
            if( value[k]=='' ) continue;
            ary.push( String.format('<b>{0}</b>: <code>{1}</code>',  _(k), value[k] ) );
        }
        return ary.join(', ');
    };
    var render_mapping = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( value == undefined ) return '';
        if( typeof value == 'string' ) return '';
        var ret = '<table>';
        ret += '<tr>'; 
        var k = 0;
        for( var k in value ) {
            if( value[k]==undefined ) value[k]='';
            ret += '<td style="font-size: 10px;font-weight: bold;padding: 1px 3px 1px 3px;">' + _(k) + '</td>'
            ret += '<td width="80px" style="font-size: 10px; background: #f5f5f5;padding: 1px 3px 1px 3px;"><code>' + value[k] + '</code></td>'
            if( k % 2 ) {
                ret += '</tr>'; 
                ret += '<tr>'; 
            }
        }
        ret += '</table>';
        return ret;
    };

    var check_sm = new Ext.grid.CheckboxSelectionModel({
        singleSelect: false,
        sortable: false,
        checkOnly: true
    });

    var id_auto = Ext.id();

    var ci_grid = new Ext.ux.maximgb.tg.GridPanel({
        title: _('CI Class: %1', params.item),
        stripeRows: false,
        autoScroll: true,
        autoWidth: true,
        sortable: false,
        //header: false,
        //hideHeaders: true,
        store: store_ci,
        sm: check_sm,

        //enableSort: false,
        //lines: true,
        //enableDD: true,

        tbar: [ 
            //{ xtype: 'checkbox', handler: function(){ if( this.getValue() ) check_sm.selectAll(); else check_sm.clearSelections() } },
            search_field,
            { xtype:'button', text: _('Create'), icon: '/static/images/icons/edit.gif', cls: 'x-btn-text-icon', handler: ci_add },
            { xtype:'button', text: _('Delete'), icon: '/static/images/icons/delete.gif', cls: 'x-btn-text-icon', handler: ci_delete },
            { xtype:'button', text: _('Tag This'), icon: '/static/images/icons/tag.gif', cls: 'x-btn-text-icon' },
            { xtype:'button', text: _('Export'), icon: '/static/images/icons/downloads_favicon.png', cls: 'x-btn-text-icon' },
        ],
        viewConfig: {
            //headersDisabled: true,
            enableRowBody: true,
            scrollOffset: 2,
            forceFit: true
        },
        master_column_id : id_auto,
        autoExpandColumn: id_auto,
        columns:[
            check_sm,
            { width: 16, hidden: true, dataIndex: 'icon', renderer: Baseliner.render_icon },
            { id: id_auto, header: _('Item'), dataIndex: 'item', width: 230, renderer: render_item },
            { id:'mid', header: _('ID'), width: 65, dataIndex: 'mid' },
            { header: _('Collection'), width: 160, dataIndex: 'collection' },
            { header: _('Class'), hidden: true, width: 160, dataIndex: 'class' },
            { header: _('Baseline'), width: 160, dataIndex: 'bl', renderer: Baseliner.render_bl },
            { header: _('Version'), width: 50, dataIndex: 'versionid' },
            { header: _('Timestamp'), width: 80, dataIndex: 'ts' },
            { header: _('Tags'), width: 140, dataIndex: 'tags', renderer: render_tags },
            { header: _('Properties'), hidden: true, width: 250, dataIndex: 'properties', renderer: render_properties },
            { header: _('Data'), hidden: false, width: 250, dataIndex: 'pretty_properties', renderer: render_datadiv }
        ],
        bbar: new Ext.ux.maximgb.tg.PagingToolbar({
            store: store_ci,
            pageSize: ps,
            displayInfo: true,
            displayMsg: _('Rows {0} - {1} of {2}'),
            emptyMsg: _('There are no rows available')
        })
    });

    ci_grid.on('rowdblclick', function(grid, rowIndex, columnIndex, e) {
        ci_edit( grid.getStore().getAt(rowIndex).data );
    });

    // Lifecycle tree node listener on click
    /*  TODO needs to setTimeout on dblclick
    var click_foo = function(n, ev){ 
        if( ! ci_grid.isVisible() ) return;
        var data = n.attributes.data;
        if( data.class == undefined ) return;  // make sure this is a ci node
        if( data.type != 'class' ) return;  // only classes on grid
        ci_grid.setTitle(_('CI: %1', data.item ) );
        store_ci.additional_params = true;
        store_ci.baseParams = data;
        if( search_field.hasSearch ) store_ci.baseParams.query = search_field.getRawValue();
        store_ci.load(); 
    };
    var ev = Baseliner.lifecycle.on('click', click_foo );
    ci_grid.on('destroy', function(){
        Baseliner.lifecycle.removeListener('click', click_foo );
    });
    */

    store_ci.on('beforeload', function(s,obj) {
        if( store_ci.additional_params ) {
            //obj.params = store_ci.additional_params;
            store_ci.additional_params = false;
        }
        else if( obj.params.anode!= undefined ) {
            var row = store_ci.getById( obj.params.anode );
            obj.params.mid = row.data.mid;
            obj.params.item = row.data.item;
            obj.params.type = row.data.type;
            obj.params.class = row.data.class;
        }
    });
    return ci_grid;
})
