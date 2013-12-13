(function(d) {
    var win;
    var lc_node = d.node;
    var is_new = d.is_new;
    var data = lc_node.attributes.data;
    var report_mid = lc_node.attributes.mid;
    var fields = data.fields;
    var ds_fields = [];
    var title = is_new ? _('New Search') : lc_node.text;
    var lc_tree = lc_node.ownerTree;
    

    
    var tree_all_loader = new Baseliner.TreeLoader({
        dataUrl: '/ci/report/all_fields'
        //baseParams: { id_rule: id_rule },
        //requestMethod:'GET',
        //uiProviders: { 'col': Ext.tree.ColumnNodeUI }
    });
    
    var tree_all = new Ext.tree.TreePanel({
        dataUrl: '/ci/report/all_fields',
        flex: 1,
        closable: true,
        autoScroll: true,
        style: { 'padding':'10px 10px 10px 10px' },
        useArrows: true,
        animate: true,
        lines: true,
        enableSort: true,
        enableDrag: true,
        ddScroll: true,
        //loader: tree_all_loader,
        //listeners: { beforenodedrop: { fn: drop_handler }, contextmenu: menu_click },
        root: { text: 'xx', name: 'xx', draggable: false, id: 'root' }, 
        rootVisible: false
    });
    
    tree_all.getLoader().on("beforeload", function(treeLoader, node) {
        var baseParams = {};
        if (node.attributes.data && node.attributes.data.id_category) baseParams.id_category = node.attributes.data.id_category;
        if (node.attributes.data && node.attributes.data.name_category) baseParams.name_category = node.attributes.data.name_category;
        treeLoader.baseParams = baseParams ;
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
    
    var sort_direction = function(dir, node){
        var attr = node.attributes;
        attr.sort_direction = dir;
        var icon = dir > 0 ? 'up' : 'down';
        attr.icon = '/static/images/icons/arrow-'+icon+'.gif';
        node.setIcon( attr.icon );
    }
    
    var edit_value = function(node){
        var attr = node.attributes;
        var pn = node.parentNode; // should be where_field
        
        var oper_all = [ ['','='], ['$ne','<>'],['$lt','<'],['$lte','<='],['$gt','>'],['$gte','>='] ];
        var oper_in = [ ['$in','IN'], ['$nin','NOT IN'] ];
        var oper_string = [ ['','='], ['$ne','<>'],['like','LIKE'], ['not_like','NOT LIKE'] ];
        var oper_by_type = oper_all;
        var field = { xtype:'textarea', name:'value', fieldLabel: pn.text, height:60, value:attr.value==undefined?'':attr.value };
        var ftype = attr.field || attr.where;
        switch( ftype ) {
            case 'string':
                oper_by_type = oper_string;
                break;
            case 'number': 
                field={ xtype:'textfield', name:'value', maskRe:/[0-9]/, fieldLabel: pn.text, value: attr.value==undefined ? 0 :  parseFloat(attr.value) };
                break;
            case 'date': 
                field={ xtype:'datefield', dateFormat:'Y-m-d', name:'value', fieldLabel: pn.text, value: attr.value==undefined ? '' : attr.value };
                break;
            case 'status': 
                field=new Baseliner.SuperBox({ fieldLabel:_('Status'), name:'value', 
                    valueField:'id', value: attr.value, singleMode: false, store: new Baseliner.Topic.StoreStatus() });
                //field=Baseliner.ci_box({ value: attr.value, isa:'status', force_set_value:true });
                oper_by_type = oper_in;
                break;
            case 'ci':
                var ci_class = pn.attributes.collection || pn.attributes.ci_class;
                field=new Baseliner.ci_box({value: attr.value, name:'value', singleMode: false, force_set_value:true, 'class': ci_class, security: true });
                oper_by_type = oper_in;
                var store;
                store = field.getStore();
                store.on('load',function(){
                    var arr_options = [];
                    var arr_values = [];
                    this.each( function(r) {
                        arr_options.push( r.data.name );
                        arr_values.push( r.data.mid );
                    });
                    attr.options = arr_options;
                });
                break;
        }
        form_value.removeAll();
        var oper = new Baseliner.ComboDouble({
            value: attr.oper || '', 
            fieldLabel: _('Operator'), data: oper_by_type });
        form_value.add(oper);
        var fcomp = form_value.add(field);
        var set_value = function(){
            attr.oper = oper.get_save_data();
            var val = fcomp.get_save_data ? fcomp.get_save_data() : fcomp.getValue();
            var label;
            switch( ftype ) {
                case 'string': val = val.toString(); break;
                case 'number': val = parseFloat(val); break;
                case 'date': val = val.format('Y-m-d').trim(); break;
                case 'ci':
                case 'status': 
                    label = fcomp.get_labels().join(',');
                    attr.options = fcomp.get_labels();
                    if(attr.options.length == 0){
                        var arr_options = [];
                        var arr_values = [];
                        var store;
                        store = field.getStore();                        
                        store.each( function(r) {
                            arr_options.push( r.data.name );
                            arr_values.push( r.data.mid );
                        });
                        arr_options.push(_('Undefined'));
                        arr_values.push( '' );
                        label = arr_options.join(',');
                        attr.options = arr_options;
                        val = arr_values;
                    }
            }
            attr.value = val;
            node.setText( String.format('{0} {1}', oper.getRawValue(), label || attr.value) );
        };
        oper.on('blur', function(f){ set_value() });
        fcomp.on('blur', function(f){ set_value() });
        fcomp.on('change', function(f){ set_value() });
        oper.on('change', function(f){ set_value() });
        form_value.setTitle( String.format('{0} - {1}', node.text, pn.text ) );
        if( form_value.collapsed ) form_value.toggleCollapse(true);
        form_value.doLayout();
    };
    
    // selected fields editor
    var edit_select = function(node){
        var attr = node.attributes;
        var header = { xtype:'textfield', name:'header', fieldLabel: _('Header'), value: attr.header||node.text };
        var width = { xtype:'textfield', name:'width', fieldLabel: _('Width'), value: attr.width||'' };
        var data_key = new Ext.form.TextField({ name:'data_key', fieldLabel: _('Data Key'), value: attr.data_key||attr.id_field, hidden: attr.meta_type!='custom_data' });
        var gridlet = { xtype:'textfield', name:'gridlet', fieldLabel: _('Gridlet'), value: attr.gridlet||'' };
        var meta_type = new Baseliner.ComboDouble({
            value: attr.meta_type || '', 
            name: 'meta_type',
            fieldLabel: _('Meta Type'), data: [
             ['',_('Default')], ['custom_data',_('Custom Data')], ['topic',_('Topic')], ['ci',_('CI')], 
                ['date',_('Date')], ['bool', _('Boolean')],
                ['calendar',_('Calendar')], ['project',_('Project')], 
                ['release',_('Release')], ['revision',_('Revision')], ['user',_('Usuario')]
        ]});
        meta_type.on('change', function(){  
            var mt=meta_type.get_save_data();
            mt =='custom_data' ? data_key.show() : date_key.hide();
        });
        
        var set_select = function(){
            var vals = form_value.getValues();
            Ext.apply( node.attributes, vals );
            node.setText( String.format('{0}', vals.header ) );
        };
    
        form_value.removeAll();
        form_value.add([ header, width, gridlet, meta_type, data_key ]);
        form_value.items.each(function(fi){
            fi.on('blur', function(){ set_select() });
            fi.on('change', function(){ set_select() });
        });
        form_value.setTitle( String.format('{0}', node.text) );
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
        if( type =='select_field' ) 
            its.push({ text: _('Edit'), handler: function(item){ edit_select(node) }, icon:'/static/images/icons/edit.gif' });
        if( type =='value' ) 
            its.push({ text: _('Edit'), handler: function(item){ edit_value(node) }, icon:'/static/images/icons/edit.gif' });
        if( type =='sort_field' ) {
            its.push({ text: _('Ascending'), handler: function(item){ sort_direction(1,node) }, icon:'/static/images/icons/arrow-up.gif' });
            its.push({ text: _('Descending'), handler: function(item){ sort_direction(-1,node) }, icon:'/static/images/icons/arrow-down.gif' });
        }
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
        listeners: { contextmenu: tree_menu_click, click: function(n){ 
                if(n.attributes.type=='value') edit_value(n); 
                else if( n.attributes.type=='select_field') edit_select(n);
            } 
        },
        root: { text: '', expanded: true, draggable: false }, 
        rootVisible: false
    });
    
    tree_selected.on('beforenodedrop',function(ev){
        var flag = true;
        var target = ev.target;
        var ttype = target.attributes.type; // || target.attributes.where_field ? 'where_field' : target.attributes.category ? 'select_field' : null;
        //Baseliner.message( 'Target Type', ttype );
        if( ttype!='select_field' && ev.point!='append' ) { 
            //alert('yikes!' + [ttype,ev.point].join(',') ); 
            return false; 
        }
        Ext.each( ev.dropNode, function(n){
            var type = n.attributes.type;
            //console.log(n);
            //Baseliner.message( 'Type', type );
            if( !type=='where_field' && ev.point=='append' ) {
                flag = false; //alert('no no'); 
                return; 
            }
            if( ttype=='select' || ttype=='select_field' ) {
                n.attributes.icon = '/static/images/icons/field.png',
                n.expanded = true;
                if( n.attributes.category ) {
                    n.setText( String.format('{0}: {1}', n.attributes.category, n.attributes.text ) );
                }
            } else {
                var nn = Ext.apply({ id: Ext.id(), expanded: ttype=='where' }, n.attributes);
                if( type!='value' ) nn.type = ttype+'_field';
                var icon = type=='value' ? '/static/images/icons/search.png' 
                    : type=='sort' ? '/static/images/icons/arrow-down.gif' 
                    : '/static/images/icons/field.png';
                nn.leaf = ttype=='where' ? false : true;
                var copy = new Ext.tree.TreeNode(nn);
                
                if( ttype=='where_field' ) {
                } else {
                    if( n.attributes.category ){
                        copy.setText( String.format('{0}: {1}', n.attributes.category, n.attributes.text ) );    
                    }else{
                        copy.setText( String.format('{0}', n.attributes.text ) );       
                    }
                    //console.dir(copy);
                    var meta_type = n.attributes.meta_type ? n.attributes.meta_type : 'string' ;
                    switch (meta_type){
                        case 'string':
                        case 'number':
                        case 'date':
                        case 'status':break;
                        default: {
                            meta_type = 'ci';
                        }
                    }
                    copy.appendChild({
                        id: Ext.id()
                        ,text: _(meta_type)
                        ,icon: '/static/images/icons/where.png'
                        ,type: 'value'
                        ,leaf:true
                        ,where: meta_type
                        ,field: meta_type
                        ,value: 'default'
                    });                    
                    
                }
                //copy.setIcon( icon );
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
            { fieldLabel: _('Name'), name: 'name', xtype: 'textfield', anchor:'50%', allowBlank: false, value: is_new ? _('New search') : lc_node.text },
            { fieldLabel: _('Rows'), name: 'rows', xtype: 'textfield', anchor:'50%', allowBlank: false, value: lc_node.attributes.rows || 50 },
            new Baseliner.ComboDouble({
                value: lc_node.attributes.permissions || 'private', name:'permissions', 
                fieldLabel: _('Permissions'), data: [ ['private',_('Private')],['public',_('Public')] ] })
        ]
    });
    
    var initialize_folders = function(){
        tree_selected.root.appendChild([ 
            { text:_('Categories'), expanded: true, type:'categories', leaf: false, children:[], icon:'/static/images/icons/folder_database.png' },
            { text:_('Fields'), expanded: true, type:'select', leaf: false, children:[], icon:'/static/images/icons/folder_magnify.png' },
            { text:_('Filters'), expanded: true, type:'where', leaf: false, children:[], icon:'/static/images/icons/folder_find.png' },
            { text:_('Sort'), expanded: true, type:'sort', leaf: false, children:[], icon:'/static/images/icons/folder_go.png' }
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
    //var sql = new Baseliner.AceEditor({ title: _('SQL'), value: lc_node.attributes.sql });
    
    var tabs = new Ext.TabPanel({ height: 600,activeTab: 0, items:[ options, seltab ]});
    
    var tbar = [ '->',
        { text: _('Close'), icon:'/static/images/icons/close.png', handler: function(){ win.close() } },
        { text: _('Save'),icon:'/static/images/icons/save.png', 
          handler: function(){
                var dd = options.getValues();
                if( tree_selected_is_loaded ) dd.selected = Baseliner.encode_tree( tree_selected.root );
                //if( sql.editor ) dd.sql = sql.getValue();
                //console.dir(dd);
                var action = report_mid > 0 ? 'update':'add';
                var data = { action:action, data:dd };
                if( report_mid > 0 ) data.mid = report_mid;
                Baseliner.ci_call( 'report', 'report_update', data, function(res){
                    if( res.success ) {
                        Baseliner.message(_('Success'), res.msg );
                        report_mid = res.mid;
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
