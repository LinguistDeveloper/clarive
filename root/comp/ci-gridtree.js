<%args>
    $save
</%args>

(function(params){
    delete params['tab_index'];  // this comes from the tab data
    var can_save = <% $save %>;
    var ps = 30;

    var record = Ext.data.Record.create([ 'mid','_id','bl', '_parent','_is_leaf',
        'type', 'pretty_properties', 
        'name', 'item', 'ci_form', 'active', 'moniker',
        'class',
        'classname', 'versionid','ts','tags','data','properties','icon','collection', 'title' ]);

    var store_ci = new Ext.ux.maximgb.tg.AdjacencyListStore({  
       autoLoad : true,  
       url: '/ci/gridtree',
       remoteSort: true,
       baseParams: Ext.apply( { pretty: true }, params ),
       reader: new Ext.data.JsonReader({ id: '_id', root: 'data', totalProperty: 'totalCount', successProperty: 'success' }, record )
    }); 

    var search_field = new Baseliner.SearchField({
        store: store_ci,
        params: {start: 0, limit: ps },
        emptyText: _('<Enter your search string>')
    });
    
    var show_graph = function(){
        var mids = [];
        Ext.each( check_sm.getSelections(), function(r){
            mids.push( r.data.mid );
        });
        var gr = new Baseliner.CIGraph({ mid: mids });
        gr.window_show();
        /*
        Baseliner.ajaxEval( '/ci/json_tree', { mid: mids, direction:'related', depth:2 }, function(res){
            if( ! res.success ) { Baseliner.message( 'Error', res.msg ); return }
            var rg = new Baseliner.JitRGraph({ json: res.data });
            var graph_win = new Baseliner.Window({ layout:'fit', width: 800, height: 600, items: rg });
            graph_win.show();
        });
        */
    };
    // only globals can be seen from grid
    Baseliner.ci_edit = function( gridid, ix ){
        var g = Ext.getCmp( gridid );
        if( g!= undefined ) 
            ci_edit( g.getStore(), g.getStore().getAt(ix).data );
    };

    var ci_edit = function(store, rec){
        var data = store.baseParams;
        Baseliner.add_tabcomp( '/ci/edit', null, { load: true, mid: rec.mid, action:'edit', bl: data.bl } );
        /* DEPRECATED:
        //var classname = data.class ;
        var classname = data["class"] ;
        Baseliner.ajaxEval( '/ci/load', { mid: rec.mid }, function(res) {
            if( res.success ) {
                var rec = res.rec;
                    {
                        _parent_grid: ci_grid.id,
                        collection: rec.collection,
                        item: rec.collection,
                        has_bl: data.has_bl,
                        has_description: data.has_description,
                        bl: data.bl,
                        //class: rec.class,
                        "class": rec["class"],
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
        */
    };

    // only globals can be seen from grid
    Baseliner.ci_add = function( gridid, ix ){
        var g = Ext.getCmp( gridid );
        if( g!= undefined ) 
            ci_add( g.getStore().getAt(ix).data );
    };

    var get_valid_selections = function(){
        var arr = [];
        if (check_sm.hasSelection()) {
           Ext.each( check_sm.getSelections(), function(r){
              if( r.data.type == 'object' ) {
                arr.push( r );
              }
           });
        }
        return arr;
    };

    var ci_add = function(){
        var data = store_ci.baseParams;
        //var classname = data.class ;
        var classname = data["class"] ;
        var rec = {};
        if (check_sm.hasSelection()) {
           var sel = get_valid_selections();
           rec = sel[0].data;
           rec.name = _('Copy of %1', rec.name );
        } 
        Baseliner.add_tabcomp( '/ci/edit', _('New: %1' , params.item ), {
                _parent_grid: ci_grid.id,
                ci_form: data.ci_form,
                item: data.collection,
                collection: data.collection,
                has_bl: data.has_bl,
                has_description: data.has_description,
                rec: rec,
                data: data,
                //class: data.class,
                "class": data["class"],
                tab_icon: data.icon,
                action: 'add'
        });
    };

    // Usage:   var checked = multi_check_data( check_sm, 'mid' );
    var multi_check_data = function(obj, field){
       if (obj.hasSelection()) {
           var sel = get_valid_selections();
           var data = [];
           for( var i=0; i<sel.length; i++ ) {
               data.push( sel[i].data[field] );
           }
           return { count: data.length, data: data };
       }
       return { count: 0, data:[] };
    };

    var ci_delete = function(){
        var checked = multi_check_data( check_sm, 'mid' );
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

    var ci_ping = function(){
        var checked = multi_check_data( check_sm, 'mid' );
        if ( checked.count > 0 ) {
            Baseliner.ajaxEval( '/ci/ping', { mids: checked.data }, function(res) {
                if( res.success ) {
                    alert(res.msg);
                } else {
                    Ext.Msg.alert( _('CI'), res.msg );
                }
            });
        }
    };

    var ci_import = function(format, ci_type){
       new Baseliner.ImportWindow({ url:'/ci/import', format: format, ci_type: ci_type }).show();
    };

    var ci_export = function(format, mode){
        var checked = multi_check_data( check_sm, 'mid' );
        if ( checked.count > 0 && format != 'csv') {
            if( format == 'html' ) {
                window.open('/ci/export_html?mids=' + checked.data.join('&mids=') + '&mode=' + mode );
            } else {
                Baseliner.ajaxEval( '/ci/export', { mids: checked.data, format: format}, function(res) {
                    if( res.success ) {
                        var win = new Ext.Window({ height: 400, width: 800, items: new Baseliner.MonoTextArea({ value: res.data }), layout:'fit', maximizable: true });       
                        win.show();
                    } else {
                        Baseliner.error( _('CI'), res.msg );
                    }
                });
            }
        } else if(format == 'csv') {
            Baseliner.ajaxEval( '/ci/export', { mids: checked.data, format: format, ci_type: mode }, function(res) {
                if( res.success ) {
                    var win = new Ext.Window({ height: 400, width: 800, items: new Baseliner.MonoTextArea({ value: res.data }), layout:'fit', maximizable: true });       
                    win.show();
                } else {
                    Baseliner.error( _('CI'), res.msg );
                }
            });
        } else {
            Baseliner.message( _('Error'), _('Select rows first') );
        }
    };

    var ci_export_file = function(url, format, ci_type, target) {
        var checked = multi_check_data( check_sm, 'mid' );
       
        var form = form_report.getForm(); 
        form.findField('mids').setValue( checked.data );
        form.findField('format').setValue( format );
        form.findField('ci_type').setValue( ci_type );
        var el = form.getEl().dom;
        var targetD = document.createAttribute("target");
        targetD.nodeValue = target || "_blank";
        el.setAttributeNode(targetD);
        el.action = url;
        el.submit(); 
    };

    var form_report = new Ext.form.FormPanel({
        url: '/ci/export_file', renderTo:'run-panel', style:{ display: 'none'},
        items: [
            { xtype:'hidden', name:'mids'},
            { xtype:'hidden', name:'format'},
            { xtype:'hidden', name:'ci_type'}
        ]
    });

    /*  Renderers */
    var render_tags = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( typeof value == 'object' ) {
            var va = value.slice(0); // copy array
            return Baseliner.render_tags( va, metadata, rec );
        } else {
            return Baseliner.render_tags( value, metadata, rec );
        }
    };
    var render_moniker = function(value,metadata,rec,rowIndex,colIndex,store) {
        return value ? String.format('<div class="bali-moniker">{0}</div>', value ) : '';
    };
    var render_item = function(value,metadata,rec,rowIndex,colIndex,store) {
        var active = rec.data.type=='object' && !rec.data._parent ? rec.data.active : true;
        if( rec.data.type == 'class' ) {
            // we create objects
            value = String.format('<a href="javascript:Baseliner.ci_add(\'{0}\',{1})">{2}</a>', ci_grid.id, rowIndex, value );
        } 
        else if( rec.data.type == 'topic' ) {
            var d = rec.data.data;
            return Baseliner.topic_name({
                mid: rec.data.mid, 
                mini: false,
                size: '11',
                category_name: d.name,
                category_color:  d.color,
                category_icon: d.icon,
                is_changeset: d.is_changeset,
                is_release: d.is_release
            }) + ' ' + rec.data.title;
        }
        var ed = String.format('Baseliner.ci_edit(\'{0}\',{1})', ci_grid.id, rowIndex, value );
        var ret = '<table><tr><td width="1">';
        ret += '<img style="margin-top:-2px" '+( active ? '':'class="gris"')+' src="' + rec.data.icon + '" alt="edit" />';
        //ret += '</td><td><b><a href="javascript:'+ed+'" style="'+(active?'':'text-decoration: line-through;')+'" onmouseover="this.style.cursor=\'pointer\'">' + value + '</a></b></td></tr></table>';
        ret += '</td><td><b><a href="#" onclick="'+ed+'; return false" style="'+(active?'':'color: #aaa;')
            +'" onmouseover="this.style.cursor=\'pointer\'">' + value + '</a></b></td></tr></table>';
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
        sortable: true,
        checkOnly: true
    });
    check_sm.on('selectionchange', function(){
        if ( can_save ) {        
            if ( check_sm.hasSelection() ) {
                btn_delete.enable();
                //btn_create.enable();
            } else {
                btn_delete.disable();
                //btn_create.disable();

            }
        }
    });

    var id_auto = Ext.id();
    
    var bbar = new Ext.ux.maximgb.tg.PagingToolbar({
            store: store_ci,
            pageSize: ps,
            plugins:[
                new Ext.ux.PageSizePlugin({
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
                                bbar.afterTextItem.hide();
                            } else {
                                bbar.afterTextItem.show();
                            }
                        }
                    },
                    forceSelection: true
                })
            ],
            displayInfo: true,
            displayMsg: _('Rows {0} - {1} of {2}'),
            emptyMsg: _('There are no rows available')
        });
//{ xtype:'button', text: _('Create'), icon: '/static/images/icons/add.gif', cls: 'x-btn-text-icon', handler: ci_add },
    var btn_create = new Baseliner.Grid.Buttons.Add({
        //disabled: false,
        handler: ci_add,
        hidden: !can_save
    })

//{ xtype:'button', text: _('Delete'), icon: '/static/images/icons/delete.gif', cls: 'x-btn-text-icon', handler: ci_delete },
    var btn_delete = new Baseliner.Grid.Buttons.Delete({
        disabled: true,
        handler: ci_delete,
        hidden: !can_save
    })

    /*var hbl;
    if(!store_ci.baseParams.has_bl){
        hbl = true;
    }
    else{
        hbl = false;
    }*/

    var ci_grid = new Ext.ux.maximgb.tg.GridPanel({
        title: _('CI Class: %1', params.item),
        stripeRows: true,
        autoScroll: true,
        autoWidth: true,
        sortable: true,
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
            btn_create,
            btn_delete,
            //{ xtype:'button', text: _('Tag This'), icon: '/static/images/icons/tag.gif', cls: 'x-btn-text-icon' },
            //{ xtype:'button', text: _('Scan'), icon: '/static/images/icons/play.png', cls: 'x-btn-text-icon' },
            //{ xtype:'button', text: _('Ping'), icon: '/static/images/icons/play.png', cls: 'x-btn-text-icon', handler: ci_ping },
            { xtype:'button', text: _('Export'), icon: '/static/images/icons/export.png', cls: 'x-btn-text-icon', 
                menu:[
                    { text:_('YAML'), icon: '/static/images/icons/yaml.png', handler:function(){ ci_export('yaml') } },
                    { text:_('JSON'), icon: '/static/images/icons/json.png', handler:function(){ ci_export('json') } },
                    { text:_('HTML'), icon: '/static/images/icons/html.png', handler:function(){ ci_export('html', 'shallow') } },
                    { text:_('HTML (Long)'), icon: '/static/images/icons/html.png', handler:function(){ ci_export('html', 'deep') } },
                    { text:_('CSV'), icon: '/static/images/icons/csv.png', handler:function(){ ci_export('csv', params.item) } },
                    { text: _('CSV File'), icon: '/static/images/icons/csv.png', handler: function() {
                        ci_export_file('/ci/export_file', 'csv', params.item, 'FrameDownload')} }
                ]
            },
            { xtype:'button', text: _('Import'), icon: '/static/images/icons/import.png', cls: 'x-btn-text-icon', 
                menu:[
                    { text:_('YAML'), icon: '/static/images/icons/yaml.png', handler:function(){ ci_import('yaml') } },
                    { text:_('CSV'), icon: '/static/images/icons/csv.png', handler:function(){ ci_import('csv', params.item) } }
                ]
            },
	       '->',
            { icon:'/static/images/ci/ci-grey.png', cls: 'x-btn-icon', handler: show_graph }
        ],
        viewConfig: {
            //headersDisabled: true,
            enableRowBody: true,
            scrollOffset: 2,
            forceFit: true
            /*,
            getRowClass: function(record, index, p, store){
                var css='';
                p.body='';
                var title = record.data.title;
                if( title && title.length > 0  ) {
                    p.body +='<div style="color: #333; font-weight: normal; padding-left: 100px; margin: 0 0 5 150;">';
                    //p.body += '<img style="vertical-align:middle" src="/static/images/icons/post.gif">';
                    p.body += '&nbsp;' + title + '</div>';
                    css += ' x-grid3-row-expanded '; 
                }
                //css += index % 2 > 0 ? ' level-row info-odd ' : ' level-row info-even ' ;
                return css;
            } */
        },
        master_column_id : id_auto,
        autoExpandColumn: id_auto,
        columns:[
            check_sm,
            //{ width: 16, hidden: true, dataIndex: 'icon', renderer: Baseliner.render_icon },
            { id: id_auto, header: _('Item'), dataIndex: 'item', width: 300, renderer: render_item, sortable: true },
            { id:'mid', header: _('ID'), width: 65, dataIndex: 'mid' , sortable: true},
            { header: _('Collection'), width: 50, dataIndex: 'collection' , sortable: true},
            { header: _('Moniker'), width: 160, dataIndex: 'moniker', renderer: render_moniker, sortable: true },
            { header: _('Class'),  width: 160, dataIndex: 'classname', sortable: true },
            { header: _('Baseline'), hidden: true, width: 160, dataIndex: 'bl', renderer: Baseliner.render_bl, sortable: true },
            { header: _('Version'), width: 50, dataIndex: 'versionid', sortable: true },
            { header: _('Timestamp'), width: 100, dataIndex: 'ts', sortable: true },
            { header: _('Tags'), width: 140, hidden: true, dataIndex: 'tags', renderer: render_tags, sortable: true },
            { header: _('Properties'), hidden: true, width: 250, dataIndex: 'properties', renderer: render_properties, sortable: true },
            //{ header: _('Data'), hidden: false, width: 250, dataIndex: 'pretty_properties', renderer: render_datadiv }
        ],
        bbar: bbar
    });

    ci_grid.on('rowdblclick', function(grid, rowIndex, columnIndex, e) {
        ci_edit( grid.getStore(), grid.getStore().getAt(rowIndex).data );
    });

    ci_grid.on('cellclick', function(grid, rowIndex, columnIndex, e) {
    });
    // Explorer tree node listener on click
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
    Baseliner.explorer.on('click', click_foo );
    ci_grid.on('destroy', function(){
        Baseliner.explorer.removeListener('click', click_foo );
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
            //obj.params.class = row.data.class;
            obj.params["class"] = row.data["class"];
        }
    });
    return ci_grid;
})
