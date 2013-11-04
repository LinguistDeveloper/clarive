(function(d) {
    var win;
    var lc_node = d.node;
    var data = lc_node.attributes.data;
    var report_mid = lc_node.attributes.mid;
    var fields = data.fields;
    var ds_fields = [];
    var title = _('New search folder');
    var lc_tree = lc_node.ownerTree;
    var tree_all_loader = new Baseliner.TreeLoader({
        dataUrl: '/ci/report/all_fields',
        //baseParams: { id_rule: id_rule },
        //requestMethod:'GET',
        //uiProviders: { 'col': Ext.tree.ColumnNodeUI }
    });
    
    var tree_all = new Ext.tree.TreePanel({
        flex: 1,
        closable: true,
        autoScroll: true,
        style: { 'padding':'10px 10px 10px 10px' },
        useArrows: true,
        animate: true,
        lines: true,
        //stripeRows: true,
        enableSort: true,
        enableDrag: true,
        ddScroll: true,
        loader: tree_all_loader,
        //listeners: { beforenodedrop: { fn: drop_handler }, contextmenu: menu_click },
        root: { text: 'xx', name: 'xx', draggable: false, id: 'root' }, 
        rootVisible: false
    });
    
    var tree_selected_loader = new Baseliner.TreeLoader({
        dataUrl: '/ci/'+report_mid+'/field_tree',
        baseParams: { id_report: data.id }
    });
    var tree_selected_is_loaded = false;
    tree_selected_loader.on('load',function(){
        tree_selected_is_loaded = true;
        if( ! tree_selected.root.hasChildNodes() ) 
            initialize_folders();
    });
    
    var edit_value = function(node){
        var pn = node.parentNode; // should be where_field
        //console.log( pn );
        //form_value.show();
        //console.log( node );
        form_value.removeAll();
        form_value.add({ xtype:'textarea', fieldLabel: pn.text, height:60, value:'nnnnna' });
        if( form_value.collapsed ) form_value.toggleCollapse(true);
        form_value.doLayout();
    };
    
    var node_properties = function(n){
        var attr = n.attributes;
        // XXX max stack size error ?
        new Baseliner.Window({ layout:'fit', width:800, height:400, items:
            new Baseliner.DataEditor({ data: Ext.apply({},attr), hide_cancel: true, hide_save: true })
        }).show();
    }
    var tree_menu_click = function(node,event){
        node.select();
        var its = [];
        var type = node.attributes.type;
        if( type =='value' ) 
            its.push({ text: _('Edit'), handler: function(item){ edit_value(node) }, icon:'/static/images/icons/edit.gif' });
        if( !/^(select|where|sort)$/.test(type) ) 
            its.push({ text: _('Delete'), handler: function(item){ node.remove() }, icon:'/static/images/icons/delete.gif' });
        var stmts_menu = new Ext.menu.Menu({
            items: its 
        });
        stmts_menu.showAt(event.xy);
    };
    var tree_selected = new Ext.tree.TreePanel({
        flex: 1,
        closable: true,
        autoScroll: true,
        style: { 'padding':'10px 10px 10px 10px' },
        useArrows: true,
        animate: true,
        lines: true,
        //stripeRows: true,
        enableSort: true,
        enableDD: true,
        ddScroll: true,
        loader: tree_selected_loader,
        listeners: { contextmenu: tree_menu_click },
        root: { text: '', expanded: true, draggable: false }, 
        rootVisible: false
    });
    
    tree_selected.on('beforenodedrop',function(ev){
        var flag = true;
        var target = ev.target;
        var ttype = target.attributes.type; // || target.attributes.where_field ? 'where_field' : target.attributes.category ? 'select_field' : null;
        Baseliner.message( 'Target Type', ttype );
        if( ttype!='select_field' && ev.point!='append' ) { alert('yikes!' + [ttype,ev.point].join(',') ); return false; }
        Ext.each( ev.dropNode, function(n){
            var type = n.attributes.type;
            Baseliner.message( 'Type', type );
            if( !type=='where_field' && ev.point=='append' ) {
                flag = false; alert('no no'); 
                return; 
            }
            if( ttype=='select' || ttype=='select_field' ) {
                n.attributes.icon = '/static/images/icons/field.png',
                n.expanded = true;
                if( n.attributes.category ) {
                    n.setText( String.format('{0}: {1}', n.attributes.category.name, n.attributes.name_field ) );
                }
            } else {
                var nn = Ext.apply({ id: Ext.id(), expanded: ttype=='where' }, n.attributes);
                if( type!='value' ) nn.type = ttype+'_field';
                nn.icon = type=='value' ? '/static/images/icons/search.png' : '/static/images/icons/field.png';
                nn.leaf = ttype=='where' ? false : true;
                var copy = new Ext.tree.TreeNode(nn);
                if( ttype=='where_field' ) {
                } else if( n.attributes.category ) {
                    copy.setText( String.format('{0}: {1}', n.attributes.category.name, n.attributes.name_field ) );
                }
                //console.log( copy );
                ev.dropNode = copy;
            }
        });
        return flag;
    });
    
    var options = new Baseliner.FormPanel({
        title: _('Options'),
        bodyStyle: { 'padding':'10px 10px 10px 10px' },
        items : [
            { fieldLabel: _('Name'), name: 'name', xtype: 'textfield', anchor:'50%', allowBlank: false, value: lc_node.text },
            { fieldLabel: _('Rows'), name: 'rows', xtype: 'textfield', anchor:'50%', allowBlank: false, value: lc_node.attributes.rows || 100 }
        ]
    });
    
    var initialize_folders = function(){
        tree_selected.root.appendChild([ 
            { text:_('Fields'), expanded: true, type:'select', leaf: false, children:[] },
            { text:_('Filters'), expanded: true, type:'where', leaf: false, children:[] },
            { text:_('Sort'), expanded: true, type:'sort', leaf: false, children:[] }
        ]);
    };
    var reload_all = new Ext.Button({ icon:'/static/images/icons/refresh.gif', handler: function(){ 
        tree_all.getLoader().load( tree_all.root );
        tree_all.root.expand();
    }});
    var btn_clean_all = new Ext.Button({ text: _('Clear'), icon:'/static/images/icons/asterisk_orange.png', handler: function(){ 
        var n;
        while (n = tree_selected.root.childNodes[0])
            tree_selected.root.removeChild(n);
        initialize_folders();
    } });
    
    var form_value = new Baseliner.FormPanel({
        region:'south',
        labelAlign: 'right',
        defaults: { anchor:'100%' },
        bodyStyle: { 'padding':'10px 10px 10px 10px' },
        height: 200,
        collapsible: true,
        collapsed: true,
        hidden: false
    });
    var selector = new Ext.Panel({ layout:'hbox', layoutConfig:{ align:'stretch' },
        region:'center',
        tbar: [ reload_all, '->', btn_clean_all ],
        items: [ tree_all, tree_selected ]
    });
    var seltab = new Ext.Panel({ layout:'border', items:[ form_value, selector ], title: _('Query') });
    var sql = new Baseliner.AceEditor({ title: _('SQL'), value: lc_node.attributes.sql });

    var tabs = new Ext.TabPanel({ height: 600,activeTab: 0, items:[ options, seltab, sql ]});
    var tbar = [ '->',
        { text: _('Close'), icon:'/static/images/icons/close.png', handler: function(){ win.close() } },
        { text: _('Save'),icon:'/static/images/icons/save.png', 
          handler: function(){
                var dd = options.getValues();
                if( tree_selected_is_loaded ) dd.selected = Baseliner.encode_tree( tree_selected.root );
                if( sql.editor ) dd.sql = sql.getValue();
                var action = report_mid > 0 ? 'update':'add';
                var data = { action:action, data:dd };
                if( report_mid>0 ) data.mid = report_mid;
                Baseliner.ci_call( 'report', 'report_update', data, function(res){
                    if( res.success ) {
                        Baseliner.message(_('Success'), res.msg );
                        lc_tree.refresh_all();
                        lc_tree.root.expand();
                        win.setTitle( dd.name );
                    } else {
                        Ext.Msg.show({  
                            title: _('Information'), 
                            msg: res.msg , 
                            buttons: Ext.Msg.OK, 
                            icon: Ext.Msg.INFO
                        });  
                    }
                });
            }
        }
    ];
    win = new Baseliner.Window({
        title: title,
        autoHeight: true,
        width: 800,
        height: 600,
        layout:'fit',
        closeAction: 'close',
        tbar: tbar,
        items: tabs
    });
    
    win.show();
})
