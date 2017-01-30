(function(params){
    var ps = 30;
    var rules_store = new Baseliner.JsonStore({
        url: '/rule/grid',
        root: 'data',
        id: 'id',
        totalProperty: 'totalCount',
        remoteSort: true,
        fields: ['rule_name', 'rule_type', 'rule_when', 'rule_event', 'rule_active', 'event_name', 'id', 'ts', 'icon']
    });

    var reload_tree = function(query, ids){
        var t = query ? query : '';
        var lo = rules_tree.getLoader();
        lo.baseParams = { query: t };
        if(ids) lo.baseParams.ids = ids;
        lo.load(rules_tree.root);
    };

    var on_click_rule_action = function(node){
        var params = {
            rule_id: node.attributes.rule_id,
            rule_name: node.attributes.rule_name,
            rule_type: node.attributes.rule_type,
            event_name: node.attributes.event_name ? node.attributes.event_name : node.attributes.rule_name,
            rule_event: node.attributes.rule_event ? node.attributes.rule_event : node.attributes.rule_name,
            icon: node.attributes.icon
        };
        show_rules(params);
    };

    var do_search = function(from){
        var t = searchField.getValue();
        var condition = left_panel.getLayout().activeItem.id == rules_grid.id;
        if(from){
            condition = !condition;
        }
        if( condition && t) {
            // Search in grid mode and toggle to grid mode
            rules_store.baseParams.query = t;
            rules_store.reload();
        } else if(t) {
            // Search in tree mode and toggle to tree mode
            var ids = [];
            rules_store.each(function(row){
                ids.push(row.data.id);
            });
            reload_tree(t, ids);
        }else if(!from && toggle_button.pressed){
            // For empty search in tree mode
            reload_tree(t);
        } else {
            // Empty search for grid and toggle with empty search to grid mode
            rules_store.baseParams.query = t;
            rules_store.reload();
        }
    };

    var searchField = new Baseliner.SearchSimple({
        name: 'rule_search',
        width: 140,
        handler: function(){
            do_search();
        }
    });

    var rule_del = function(){
        var rule_id;
        var rule_name;
        var call_del = function(){
            Baseliner.confirm( _('Delete rule %1?', rule_name ), function(){
                Baseliner.ajaxEval( '/rule/delete', { id_rule: rule_id }, function(res){
                    if( res.success ) {
                        rules_store.reload();
                        Baseliner.message( _('Rule'), res.msg );
                        // remove tab if any
                        var tab_arr = tabpanel.find( 'id_rule', rule_id );
                        if( tab_arr.length > 0 ) {
                            tabpanel.remove( tab_arr[0] );
                        }
                    } else {
                        Baseliner.error( _('Error'), res.msg );
                    }
                    if(toggle_button.pressed){
                        rules_tree.getSelectionModel().selNode.remove();
                    }else{
                        reload_tree();
                    }
                });
            });
        };
        if(toggle_button.pressed){
            rule_id = rules_tree.getSelectionModel().selNode.attributes.rule_id;
            rule_name = rules_tree.getSelectionModel().selNode.attributes.rule_name;
            call_del();
        } else {
            var sm = rules_grid.getSelectionModel();
            rule_name = sm.getSelected().data.rule_name;
            rule_id = sm.getSelected().data.id;
            if( sm.hasSelection() ) {
                call_del();
            }
        }
    };

    var rule_export = function(){
        var rule_id;
        var call_rule_export = function(){
            Baseliner.ajaxEval( '/rule/export', { id_rule: rule_id }, function(res){
                if( res.success ) {
                    var win = new Baseliner.Window({ height: 400, width: 800, items: new Baseliner.MonoTextArea({ value: res.yaml }),
                         layout:'fit' });
                    win.show();
                } else {
                    Baseliner.error( _('Rule Export'), res.msg );
                }
            });
        };
        if(toggle_button.pressed){
            if(rules_tree.getSelectionModel().selNode){
                rule_id = rules_tree.getSelectionModel().selNode.attributes.rule_id;
                call_rule_export();
            }else{
                Baseliner.message( _('Error'), _('Select rule to export first') );
            }
        } else {
            var sm = rules_grid.getSelectionModel();
            rule_id = sm.getSelected().data.id;
            if( sm.hasSelection() ) {
                var activate = sm.getSelected().data.rule_active > 0 ? 0 : 1;
                call_rule_export();
            } else {
                Baseliner.message( _('Error'), _('Select rows first') );
            }
        }
    };


    // use a form so file can download
    var form_export_file = new Ext.form.FormPanel({
        url: '/rule/export_file', renderTo:'run-panel', style:{ display: 'none'},
        items: [
            { xtype:'hidden', name:'id_rule'},
            { xtype:'hidden', name:'format'}
        ]
    });
    var rule_export_file = function(){
        var rule_id;
        var call_rule_export_file = function() {
            var form = form_export_file.getForm();
            form.findField('id_rule').setValue( rule_id );
            form.findField('format').setValue( 'yaml' );
            var el = form.getEl().dom;
            var targetD = document.createAttribute("target");
            targetD.nodeValue = 'FrameDownload';
            el.setAttributeNode(targetD);
            el.action = '/rule/export_file';
            el.submit();
        };
        if(toggle_button.pressed){
            if(rules_tree.getSelectionModel().selNode){
                rule_id = rules_tree.getSelectionModel().selNode.attributes.rule_id;
                call_rule_export_file();
            }else{
                Baseliner.message( _('Error'), _('Select rule to export first') );
            }
        } else {
            var sm = rules_grid.getSelectionModel();
            if( sm.hasSelection() ) {
                rule_id = sm.getSelected().data.id;
                call_rule_export_file();
            }else{
                Baseliner.message( _('Error'), _('Select rows first') );
            }
        }
    };

    var rule_import = function(){
        var yaml = new Baseliner.MonoTextArea({ fieldLabel:_('YAML'), value:'' });
        var btn_imp = new Ext.Button({ text: _('Import YAML'), handler: function(){
            Baseliner.ajaxEval('/rule/import_yaml', { data: yaml.getValue(), type:'yaml' }, function(res){
                if( res.success ) {
                    rules_store.reload();
                    reload_tree();
                    Baseliner.message( _('Import'), _('Imported rule: %1', res.name) );
                    win.close();
                }
            },function(res){
                Baseliner.error( _('Rule Export'), res.msg );
            });
        }});
        var win = new Baseliner.Window({ title:_('Import'), layout:'fit', width: 800, height: 600, tbar:[btn_imp], items:yaml });
        win.show();
    };

    var rule_import_file = function(){
        var up = new Baseliner.UploadPanel({
            title: _('Drag and Drop Files Here'),
            url: '/rule/import_file',
            height: 300
        });
        up.on('complete', function(){
            reload_tree();
            rules_store.reload();
            win.hide();
        });
        var win = new Baseliner.Window({ title:_('Import'), layout:'form',
            width: 600, height: 300, tbar:[_('Select or Drag and Drop Rule Files Here')], items:up });
        win.show();
    };

    var rule_activate = function(){
        var rule_id;
        var rule_active;
        var change_active = function(node){
            node.attributes.rule_active = rule_active.toString();
            var temp_text = node.text;
            if(!rule_active){
                temp_text = '<span style="text-decoration: line-through; color:#bbb">'+temp_text+'</span>';
            } else {
                temp_text = temp_text.replace(/<span style="text-decoration: line-through; color:#bbb">/, '');
                temp_text = temp_text.replace(/\<\/span\>$/,'');
            }
            node.setText(temp_text);

        };
        var call_active = function(){
            Baseliner.ajaxEval( '/rule/activate', { id_rule: rule_id, activate: rule_active }, function(res){
                if( res.success ) {
                    rules_store.reload();
                    Baseliner.message( _('Rule'), res.msg );
                    // Modify active for the appropriate nodes
                    rules_tree.root.eachChild(function(child){
                        var node_found = child.findChild('rule_id', rule_id);
                        if(node_found){
                            change_active(node_found);
                        }
                        if(child.attributes.is_custom_folders_node){
                            child.eachChild(function(child_folder){
                                node_found = child_folder.findChild('rule_id', rule_id);
                                if(node_found){
                                    change_active(node_found);
                                }
                            });
                        }
                    });
                } else {
                    Baseliner.error( _('Error'), res.msg );
                }
            });
        };
        if(toggle_button.pressed){
            rule_id = rules_tree.getSelectionModel().selNode.attributes.rule_id;
            rule_active = parseInt(rules_tree.getSelectionModel().selNode.attributes.rule_active) > 0 ? 0 : 1;
            call_active();
        }else{
            var sm = rules_grid.getSelectionModel();
            rule_id = sm.getSelected().data.id;
            rule_active = sm.getSelected().data.rule_active > 0 ? 0 : 1;
            if( sm.hasSelection() ) {
                call_active();
            }
        }
    };

    var rule_edit = function(){
        var rule_id;
        var call_edit = function(){
            Baseliner.ajaxEval( '/rule/get', { id_rule: rule_id }, function(res){
                if( res.success ) {
                    rule_editor( res.rec );
                } else {
                    Baseliner.error( _('Error'), res.msg );
                }
            });
        };
        if(toggle_button.pressed){
            rule_id = rules_tree.getSelectionModel().selNode.attributes.rule_id;
            call_edit();
        } else {
            var sm = rules_grid.getSelectionModel();
            rule_id = sm.getSelected().data.id;
            if( sm.hasSelection() ) {
                call_edit();
            }
        }
    };

    var rule_add = function(){
        rule_editor({ origin: 'rule_add'});
    };
    var rule_editor = function(rec) {
        Baseliner.ajaxEval('/comp/rule_new.js', {
            rec: rec
        }, function(comp) {
            if (comp) {
                var win = new Baseliner.Window({
                    title: _('Edit Rule'),
                    cls: 'edit_rule_window',
                    bodyCssClass: 'edit_rule_window_body',
                    autoScroll: true,
                    items: [comp]
                });
                comp.on('destroy', function() {
                    win.close()
                    rules_store.reload();
                    reload_tree();
                });
                win.show();
            }
        });
    };
    var render_actions = function(value,row){
        return '';
    };
    var tree_load = function(){
        var loader = tree.getLoader();
        loader.load(tree.root);
        tree.root.expand();
    };

    var render_rule_ts = function( v,metadata,rec ) {
        return String.format('<span style="color:#888; font-size:.8em">{0}</span>', Cla.moment(v).fromNow() );
    }

    var render_rule = function( v,metadata,rec ) {
        if( rec.data.rule_active == 0 )
            v = String.format('<span style="text-decoration: line-through">{0}</span>', v );
        var type = rec.data.rule_type;

        return String.format(
            '<div style="float:left"><img src="{0}" /></div>&nbsp;'
            + '<b>{2}: {1}</b>',
            rec.data.icon,
            v, rec.data.id
        );
    };

    var activate_tree_view = function(btn) {
        left_panel.getLayout().setActiveItem( btn.pressed ? rules_tree : rules_grid );
    };

    var add_custom_folder = function(node){
        Ext.Msg.prompt(_('Add new custom folder'), _('New folder:'), function(btn, text){
            if( btn == 'ok' ) {
                Baseliner.ajaxEval('/rule/add_custom_folder', { folder_name: text }, function(response){
                    var rule_info = response.data;
                    var new_node = new Ext.tree.TreeNode({
                        leaf: false,
                        text: rule_info.name,
                        rule_folder_id: rule_info.id,
                        is_folder: true,
                        expandable: true,
                        iconCls: rule_info.iconCls,
                        allowDrop:true
                    });
                    node.appendChild(new_node);
                    node.expand();
                });
            }
        }, this, false );
    };

    var rename_rule_folder = function(node){
        Ext.Msg.prompt(_('Rename folder'), _('New name:'), function(btn, text){
            if( btn == 'ok' ) {
                Baseliner.ajaxEval('/rule/rename_rule_folder', { folder_name: text, rule_folder_id: node.attributes.rule_folder_id }, function(response){
                    node.setText(text);
                });
            }
        }, this, false );
    };

    var delete_rule_folder = function(node){
        Baseliner.confirm(_('Are you sure you want delete the folder?'), function(){
            Baseliner.ajaxEval('/rule/delete_rule_folder', { rule_folder_id: node.attributes.rule_folder_id }, function(response){
                node.remove();
            });
        }, function(){  });
    };

    var deal_rule_drop = function(dropEvent){
        Baseliner.ajaxEval('/rule/added_rule_to_folder', { rule_folder_id: dropEvent.target.attributes.rule_folder_id, rule_id: dropEvent.dropNode.attributes.rule_id }, function(response){
        });
    };

    var delete_rule_from_folder = function(node){
        var rule_id = node.attributes.rule_id;
        var rule_folder_id = node.parentNode.attributes.rule_folder_id;
        Baseliner.ajaxEval('/rule/delete_rule_from_folder', { rule_folder_id: rule_folder_id, rule_id: rule_id }, function(response){
            node.remove();
        });
    };

    var menu_custom_folder = function(node,event){
        if(node.attributes.is_custom_folders_node){
            node.select();
            var stmts_menu = new Ext.menu.Menu({
                items: [
                    { text: _('Add new custom folder'), handler: function(){ add_custom_folder( node ) }, icon:'/static/images/icons/folder-new.svg' }
                ]
            });
            stmts_menu.showAt(event.xy);
        } else if(node.attributes.is_folder){
            node.select();
            var stmts_menu = new Ext.menu.Menu({
                items: [
                    { text: _('Rename'), handler: function(){ rename_rule_folder( node ) }, icon:'/static/images/icons/item-rename.svg' },
                    { text: _('Delete'), handler: function(item){ delete_rule_folder(node);  }, icon:'/static/images/icons/folder-delete.svg' }
                ]
            });
            stmts_menu.showAt(event.xy);
        } else if(node.parentNode.attributes.is_folder){
            node.select();
            var stmts_menu = new Ext.menu.Menu({
                items: [
                    { text: _('Remove from folder'), handler: function(item){ delete_rule_from_folder(node);  }, icon:'/static/images/icons/delete.svg' }
                ]
            });
            stmts_menu.showAt(event.xy);
        }
    };

    var rules_tree = new Ext.tree.TreePanel({
        cls: 'ui-comp-rules-tree',
        useArrows: true,
        expanded: true,
        animate : true,
        stateful:true,
        hidden: true,
        enableDD: true,
        rootVisible: false,
        dataUrl: '/rule/tree_structure',
        autoScroll : true,
        containerScroll : true,
        root: {
            nodeType: 'async',
            text: '/',
            draggable:true,
            id: '/'
        },
        dropConfig : { appendOnly : true },
        listeners: {
            contextmenu: menu_custom_folder,
            nodedrop: deal_rule_drop
        }
    });

    rules_tree.on('beforenodedrop', function(e){
        var existing_node = e.target.findChild( 'rule_id', e.data.node.attributes.rule_id);
        var n = e.dropNode;
        var copy = new Ext.tree.TreeNode( Ext.apply({}, n.attributes) );
        e.dropNode = copy;
        e.dropNode.on('click', function(){ on_click_rule_action(e.dropNode); });
        n.on('click', function(){ on_click_rule_action(n); });
        if(existing_node){
            existing_node.remove();
        }
    });

    var get_icon_category = function(rule_category) {
        var icon = rule_category == 'dashboard' ? IC('dashboard') :
            rule_category == 'form' ? IC('form') :
            rule_category == 'event' ? IC('event') :
            rule_category == 'report' ? IC('report') :
            rule_category == 'pipeline' ? IC('job') :
            rule_category == 'webservice' ? IC('rule-webservice') :
            rule_category == 'workflow' ? IC('workflow') :
            IC('rule');
        return icon;
    };
    rules_tree.on('beforechildrenrendered', function(params){
        var root = params;
        root.eachChild(function(node){
            var type = node.attributes.rule_type;
            if(node.parentNode.id != '/'){
                //Children
                if(!(node.attributes.is_folder || node.attributes.is_custom_folders_node)){
                    node.on('click', function() { on_click_rule_action(node); });
                }
                var rule_when = '';
                var inactive_rule = '';
                if(node.attributes.rule_type == 'pipeline' || node.attributes.rule_type == 'event'){
                    rule_when = node.attributes.rule_when ? String.format('<span style="font-weight: bold; color: #48b010">{0}</span>', node.attributes.rule_when) : '';
                }
                var rule_text = node.attributes.text;
                if(!node.attributes.is_folder){
                    rule_text = rule_text + String.format('<span style="font-family:Helvetica Neue,Helvetica,Arial,sans-serif;font-size: xx-small; font-weight:bolder;padding:1px 2px;margin-left:4px;-webkit-border-radius: 3px;-moz-border-radius: 3px;border-radius: 3px;color: #000;background-color:#eee">{0}</span>',node.attributes.rule_id) +
                    rule_when +
                    String.format('<span style="padding-left: 5px;color:#bbb">{0}</span>', Cla.moment(node.attributes.rule_ts).fromNow()) +
                    String.format('<span style="padding-left: 5px;color:#bbb">by {0}</span>', node.attributes.username);
                    if(node.attributes.rule_active == "0"){
                        rule_text = String.format('<span style="text-decoration: line-through; color:#bbb">{0}</span>', rule_text);
                    }
                }
                node.setText(rule_text);
            }
            if(!(node.attributes.is_folder || node.attributes.is_custom_folders_node)){
                var icon = get_icon_category(type);
                node.setIcon(icon);
            }
        });
    });



    var rules_grid = new Ext.grid.GridPanel({
        selModel: new Ext.grid.RowSelectionModel({ singleSelect : true }),
        viewConfig: {
            enableRowBody: true,
            forceFit: true,
            getRowClass : function(rec, index, p, store){
                var caption = '';
                if( rec.data.rule_type == 'event' ) {
                    caption =  _("%1 for event '%2'", _(rec.data.rule_when), rec.data.rule_event );
                } else if( rec.data.rule_type == 'pipeline' ) {
                    var default_pipeline = rec.data.rule_when || '-';
                    caption =  _('pipeline: %1', '<span style="font-weight: bold; color: #48b010">'+default_pipeline+'</span>' );
                } else {
                    caption =  _(rec.data.rule_type);
                }
                p.body = String.format( '<div style="margin: 0 0 0 32px;color: #777">{0}</div>', caption );
                return ' x-grid3-row-expanded';
            }
        },
        header: false,
        store: rules_store,
        cls: 'ui-comp-rules-grid',
        stripeRows: true,
        columns:[
            { header: _('Rule'), width: 160, dataIndex: 'rule_name', sortable: true, renderer: render_rule },
            { header: _('Type'), hidden: true, width: 40, dataIndex: 'rule_type' },
            { header: _('When'), width: 60, dataIndex: 'ts', sortable: true, renderer: render_rule_ts }
        ]
    });
    rules_store.load();


    var show_rules = function(params){
        var get_rule_ts = Baseliner.ajaxEval('/rule/get_rule_ts', { id_rule: params.rule_id }, function(response){
            if (response.success){
                Ext.getCmp('x-btn-edit')['enable']();
                Ext.getCmp('x-btn-del')['enable']();
                Ext.getCmp('x-btn-act')['enable']();
                var old_ts = response.ts;
                if( params ) {
                    var tab_arr = tabpanel.find( 'id_rule', params.rule_id );
                    if( tab_arr.length > 0 ) {
                        tabpanel.setActiveTab( tab_arr[0] );
                    } else {
                        rule_flow_show( params.rule_id, params.rule_name, params.event_name, params.rule_event, params.rule_type, old_ts, params.icon);
                    }
                }
            }
        });
    };

    rules_grid.on('rowclick', function(grid, ix){
        var rec = rules_store.getAt( ix );
        var params = {  rule_id: rec.data.id,
                        rule_name: rec.data.rule_name,
                        rule_type: rec.data.rule_type,
                        event_name: rec.data.event_name,
                        rule_event: rec.data.rule_event,
                        icon: rec.icon
        };
        show_rules(params);
    });

    var encode_tree = function( root, include ){
        var stmts = [];
        if( include ) {
            var attr = Baseliner.clone( root.attributes );
            delete attr.loader;
            if ( !attr.id.indexOf('rule-') === 0 ) attr.id = Cla.id('rule');
            delete attr.children;
            stmts.push({ attributes: attr, children: encode_tree( root ) });
        } else {
            root.eachChild( function(n){
                var attr = Baseliner.clone( n.attributes );
                delete attr.loader;
                if ( !attr.id.indexOf('rule-') === 0 ) attr.id = Cla.id('rule');
                delete attr.children;
                stmts.push({ attributes: attr, children: encode_tree( n ) });
            });
        }
        return stmts;
    };

    var show_win = function(node, item, opts, foo) {
        var id_rule = node.getOwnerTree().id_rule;
        var key = node.attributes.key || 'none';
        var win = new Baseliner.Window(Ext.apply({
            layout: 'fit',
            stateful: true,
            stateId: 'rule-config-'+key+'-'+id_rule,  // state unique for node key for a given rule
            title: _('Edit: %1', node.text),
            items: item
        }, opts));
        win.on('destroy', function() {
            var rule_card = tabpanel.activeTab;
            if (rule_card) rule_card.focus();
        });
        item.on('destroy', function(){
            if( !Ext.isFunction(foo) ) foo = function(d){
                node.getOwnerTree().is_dirty=true;
                node.attributes.data = d;
                node.attributes.ts = new Date();
                node.attributes.who = Prefs.username;
                node.getOwnerTree().search_clear();
                node.getOwnerTree().search_nodes();
            };
            if( item.data ) foo(item.data); // item.data is only set if modified
            win.close();
        });
        win.show();
        return win;
    };

    var clipboard;
    var clone_node = function(node){
        var nn = jQuery.extend(true,{},node.attributes);
        nn.id = Cla.id('rule');
        var copy = new Ext.tree.TreeNode( nn );
        node.eachChild( function( chi ){
            copy.appendChild( clone_node( chi ) );
        });
        return copy;
    };
    var dsl_node = function( node ) {
        node.getOwnerTree().rule_dsl(node,true);
    };
    var copy_node = function( node ) {
        clipboard = { node: node, mode:'copy' };
    };
    var cut_node = function( node ) {
        clipboard = { node: node, mode:'cut' };
    };
    var new_id_for_task = function(text){
        return (Baseliner.name_to_id(text || 'LABEL') + '_' + new Date().format('Ymdhis')).toUpperCase();
    }
    var copy_shortcut = function( node ) {
        clipboard = { mode:'shortcut', node: node };
    }
    var paste_node = function( node ) {
        if( clipboard && clipboard.mode=='shortcut' ) {
            // paste as a shortcut
            if( clipboard.node.attributes ) {
                // maybe a declared sub group
                if( !clipboard.node.attributes.sub_name )
                    clipboard.node.attributes.sub_name = new_id_for_task(clipboard.node.text);
            } else {
                Baseliner.error( _('Shortcut'), _('Could not find source node for shortcut') );
                return;
            }
            clipboard.node.attributes.has_shortcut = true;
            node.appendChild({
                text: clipboard.node.text,
                data: { call_shortcut: clipboard.node.attributes.sub_name, source_key: clipboard.node.attributes.key },
                key: 'statement.shortcut',
                leaf: true,
                icon: '/static/images/icons/shortcut.svg',
                id: Cla.id('rule')
            });
        } else if( clipboard ) {
            // paste normal
            var copy = clipboard.mode=='copy' ? clone_node( clipboard.node ) : clipboard.node;
            var field_name_is_ok = true;
            if (/fieldlet./.test(copy.attributes.key) && clipboard.mode=='copy'){
                delete copy.attributes.data.id_field;
                var root = node.getOwnerTree().getRootNode();
                configureTextField(root, copy, {
                    name_field: copy.attributes.data.name_field
                });
            }
            if( field_name_is_ok == true ) {
                if( clipboard.mode=='copy' ) {
                    if( copy.attributes.sub_name ) copy.attributes.sub_name = new_id_for_task( copy.text );
                    delete copy.attributes.has_shortcut;
                    copy.cascade(function(n_chi){
                        n_chi.attributes.id = Cla.id('rule');
                        if( clipboard.mode=='copy' ) {
                            if( n_chi.attributes.sub_name ) n_chi.attributes.sub_name = new_id_for_task( n_chi.text );
                            delete n_chi.attributes.has_shortcut;
                        }
                    });
                    node.getOwnerTree().is_dirty = true;
                    node.appendChild(copy);
                }
                else if( clipboard.mode=='cut' ) {
                    node.getOwnerTree().is_dirty = true;
                    node.appendChild(copy);
                }
            }
        } else {
            Baseliner.message( _('Paste'), _('Nothing in clipboard to paste') );
        }
    };
    var export_node = function( node ) {
        var stmts = encode_tree( node,true );
        var json = Ext.util.JSON.encode( stmts[0] );
        var editor = new Baseliner.MonoTextArea({ value: json });
        var btn_beau = new Ext.Button({ text:_('Beautify'), handler: function(){
            Cla.use('/static/jsbeautifier/beautify.js',function(){
                json = js_beautify(json,{});
                editor.setValue( json );
            });
        }});
        var btn_root = new Ext.Button({ text:_('Remove Root'), handler: function(){
            json = Ext.util.JSON.encode( stmts[0].children );
            editor.setValue( json );
        }});

        var win = new Baseliner.Window({ height: 400, width: 800,
            tbar: [btn_beau,'-', (stmts[0] && stmts[0].children ? btn_root : null) ],
            items: editor, layout:'fit' });
        win.show();
    };
    var import_node = function( node_parent ) {
        if( node_parent.leaf ) {
            Baseliner.error(_('Import'), _('Cannot import into leaf node') );
            return;
        }
        var impbox = new Baseliner.MonoTextArea({ value: '' });
        var importer = function(){
            var json = impbox.getValue();
            var ndata = Ext.util.JSON.decode( json );
            var processnode = function(n){
                var at = n.attributes;
                delete at.loader;
                at.id = Cla.id('rule');
                return Ext.apply({
                    children: n.children.map(function(chi){ return processnode(chi) }),
                }, at );
            }
            if( Ext.isArray(ndata) ) {
                Ext.each(ndata, function(nn){
                    var node = processnode(nn);
                    node_parent.appendChild( node );
                });
            } else {
                var node = processnode(ndata);
                node_parent.appendChild( node );
            }
            win.close();
        }
        var btn_beau = new Ext.Button({ text:_('Beautify'), handler: function(){
            Cla.use('/static/jsbeautifier/beautify.js',function(){
                var json = js_beautify(impbox.getValue(),{});
                impbox.setValue( json );
            });
        }});
        var win = new Baseliner.Window({
            height: 400, width: 800,
            tbar: [btn_beau, '->', { xtype:'button', text:_('Import'), icon: '/static/images/icons/import.svg', handler: importer }],
            items: impbox, layout:'fit' });
        win.show();
    };
    var toggle_node = function( node ) {
        node.disabled ? node.enable() : node.disable();
        node.attributes.active = node.disabled ? 0 : 1;
        if( node.ui && node.ui.textNode ) node.ui.textNode.style.textDecoration = node.disabled ? 'line-through' : '';
    };
    var rename_node = function( node ) {
        Ext.Msg.prompt(_('Rename'), _('New name:'), function(btn, text){
            if( btn == 'ok' ) {
                node.setText( text );
            }
        }, this, false, node.text );
    };
    // Properties window:
    var meta_node = function( node, goto_tab ) {
        var attr = node.attributes;
        var data = attr.data || {};
        var de = new Baseliner.DataEditor({ title:_('Metadata'), data: attr, hide_save: true, hide_cancel: true  });
        var note = new Baseliner.MonoTextArea({ title:_('Note'), value: attr.note || '' });
        var data_key = new Ext.form.TextField({ fieldLabel:_('Return Key'), name:'data_key', value: node.attributes.data_key || '' });
        var needs_rollback_mode = new Baseliner.ComboDouble({
            fieldLabel: _('Needs Rollback?'), name:'needs_rollback_mode', value: attr.needs_rollback_mode || 'none',
            data: [ ['nb_after',_('Rollback Needed After')], ['nb_before',_('Rollback Needed Before')],
                    ['nb_always',_('Rollback Needed Always')], ['none',_('No Rollback Necessary')] ]
        });
        needs_rollback_mode.on('select', function(){
            if (needs_rollback_mode.getValue()!='none'){
                needs_rollback_key.setValue(Baseliner.name_to_id(node.text));
                // needs_rollback_key.show();
            }else{
                // needs_rollback_key.hide();
                needs_rollback_key.setValue('<always>');
            }
        });
        var needs_rollback_key = new Ext.form.TextField({
            name: 'needs_rollback_key', fieldLabel:_('Needs Rollback Key'),
            value: data.needs_rollback_key || '<always>' //Baseliner.name_to_id(node.text)
        });
        if (needs_rollback_mode.getValue()!='none'){
            needs_rollback_key.setValue(Baseliner.name_to_id(node.text));
        }else{
            needs_rollback_key.setValue('<always>');
        }
        var enabled = new Ext.form.Checkbox({ fieldLabel:_('Enabled'), checked: node.disabled===true?false:true });
        var run_forward = new Ext.form.Checkbox({ fieldLabel:_('Run Forward'), checked: _bool(attr.run_forward,true) });
        var run_rollback = new Ext.form.Checkbox({ fieldLabel:_('Run Rollback'), checked: _bool(attr.run_rollback,true) });
        var error_trap = new Baseliner.ComboDouble({
            fieldLabel: _('Error Trap'), name:'error_trap', value: attr.error_trap || 'none',
            data: [ ['none',_('No Trap')], ['trap',_('Trap Errors')], ['ignore',_('Ignore Errors')] ]
        });
        var trapTimeout = new Ext.ux.form.SpinnerField({
            fieldLabel: _('Trap timeout (seconds)'),
            minValue: 0,
            allowDecimals: true,
            incrementValue: 0.5,
            name: 'trap_timeout',
            value: attr.trap_timeout || 0
        });
        var trap_timeout_action = new Baseliner.ComboDouble({
            fieldLabel: _('Trap timeout action'), name:'trap_timeout_action', value: attr.trap_timeout_action || 'abort',
            data: [ ['abort',_('Abort')], ['skip',_('Skip')], ['retry',_('Retry')] ]
        });
        var trapMaxRetry = new Ext.ux.form.SpinnerField({
            fieldLabel: _('Trap max retry (0 means unlimited)'),
            minValue: 0,
            allowDecimals: false,
            incrementValue: 1,
            name: 'trap_max_retry',
            value: attr.trap_max_retry || 0
        });
        var trap_rollback = new Ext.form.Checkbox({ fieldLabel:_('Trap in Rollback?'), checked: _bool(attr.trap_rollback,true) });

        var debug_mode = new Baseliner.ComboDouble({
            fieldLabel: _('Debug Mode'), name:'debug_mode', value: attr.debug_mode || 'none',
            data: [ ['none',_('No Debug')], ['op',_('Op Trace')], ['stash',_('Op Trace + Stash Dump')] ]
        });
        var parallel_mode = new Baseliner.ComboDouble({
            fieldLabel: _('Parallel Mode'), name:'parallel_mode', value: attr.parallel_mode || 'none',
            data: [ ['none',_('No Parallel')], ['fork',_('Fork and Wait')], ['nohup', _('Fork and Leave')] ]
        });
        var semaphore_key = new Ext.form.TextField({ fieldLabel:_('Semaphore Key'), name:'semaphore_key', value: attr.semaphore_key });
        var sub_name = new Ext.form.TextField({ fieldLabel:_('Sub Name'), name:'sub_name', readOnly: true, value: attr.sub_name });
        var timeout = new Ext.form.TextField({ fieldLabel:_('Timeout'), name:'timeout', value: attr.timeout });
        var opts = new Baseliner.FormPanel({ title:_('Options'), labelWidth: 150, style:{ padding:'5px 5px 5px 5px'}, defaults:{ anchor:'100%' }, items:[
            enabled, data_key, needs_rollback_mode, needs_rollback_key, run_forward, run_rollback, timeout, semaphore_key, parallel_mode, debug_mode,
            error_trap, trapTimeout, trap_timeout_action, trapMaxRetry, trap_rollback, sub_name
        ]});
        var btn_save_meta = new Ext.Button({ text:_('Save'), icon:'/static/images/icons/save.svg', handler:function(){
            node.attributes = de.getData();
            if( !node.attributes.data ) node.attributes.data={};
            var dk = data_key.getValue();
            if( dk!=undefined ) {
                node.attributes.data_key = dk.trim();
                node.attributes.data.data_key=dk.trim();
            }
            // attribute save
            node.attributes.active = enabled.checked ? 1 : 0;
            node.attributes.disabled = enabled.checked ? false : true;
            enabled.checked ? node.enable() : node.disable();
            node.attributes.needs_rollback_mode = needs_rollback_mode.getValue();
            node.attributes.run_forward = run_forward.checked;
            node.attributes.run_rollback = run_rollback.checked;
            node.attributes.debug_mode = debug_mode.getValue();
            node.attributes.parallel_mode = parallel_mode.getValue();
            node.attributes.error_trap = error_trap.getValue();
            node.attributes.trap_timeout = trapTimeout.getValue();
            node.attributes.trap_timeout_action = trap_timeout_action.getValue();
            node.attributes.trap_max_retry = trapMaxRetry.getValue();
            node.attributes.trap_rollback = trap_rollback.checked;
            node.attributes.semaphore_key = semaphore_key.getValue().trim();
            node.attributes.timeout = timeout.getValue();
            node.attributes.note = note.getValue();
            node.attributes.ts = new Date();
            node.attributes.who = Prefs.username;
            node.setText( node.attributes.text );
            node.getOwnerTree().node_decorate( node );  // change the node's look
            // data save
            if( !node.attributes.data ) node.attributes.data={};
            Ext.apply(node.attributes.data, opts.getValues() ); // TODO this is not needed and gets overwritten everytime config is saved
            win.close();
        }});
        var tbar = [ '->',
            { xtype:'button', text:_('Cancel'), icon:'/static/images/icons/close.svg', handler: function(){ win.close() } },
            btn_save_meta ];
        opts.doLayout();
        de.doLayout();
        var tabs = new Ext.TabPanel({ activeTab: goto_tab==undefined?0:goto_tab,  plugins: [ new Ext.ux.panel.DraggableTabs()], items:[ opts,de,note ] });
        var win = show_win( node, tabs, { width: 800, height: 600, tbar:tbar }, function(d){
        });
    };
    var edit_node = function( node ) {
        var key = node.attributes.key;
        if( ! key ) {
            Baseliner.error( _('Missing key'),
                _("Service '%1' does not contain edit information", node.text) );
            return;
        }
        Baseliner.ajaxEval( '/rule/edit_key', { key: key }, function(res){
            if( res.success ) {
                if( res.form ) {
                    var reg_params = res.params;
                    var data = node.attributes.data;
                    data.config = res.config;
                    var is_dashlet = /^dashlet\./.test(key);
                    var is_fieldlet = /^fieldlet\./.test(key);
                    var common_options = undefined;
                    if (is_dashlet && node.getOwnerTree().rule_type == 'form') {
                        common_options = [{
                            xtype: 'fieldset',
                            collapsible: true,
                            title: _('Common Dashlet as a Field Options'),
                            items: [{
                                xtype: 'textfield',
                                fieldLabel: _('Width'),
                                name: 'field_width',
                                value: data.field_width || reg_params.field_width || '100%'
                            }, {
                                xtype: 'textfield',
                                fieldLabel: _('Height'),
                                name: 'field_height',
                                value: data.field_height || reg_params.field_height || '220px'
                            }]
                        }];
                    } else if (is_fieldlet) {
                        common_options = [{
                            id_rule: node.id_rule
                        }];
                    }
                    Baseliner.ajaxEval( res.form, { common_options: common_options, data: data || {}, attributes: node.attributes }, function(comp){
                        var params = {};
                        var save_form = function(){
                            if(form.is_valid()){
                                form.data = form.getValues();
                                form.destroy();
                            }
                        };
                        var form = new Baseliner.FormPanel({
                            frame: false, forceFit: true, defaults: { msgTarget: 'under', anchor:'100%' },
                            labelWidth: 150,
                            width: 800, height: 600,
                            labelAlign: 'right',
                            labelSeparator: '',
                            autoScroll: true,
                            tbar: [
                                '->',
                                { xtype:'button', text:_('Cancel'), icon:'/static/images/icons/close.svg', handler: function(){ form.destroy() } },
                                { xtype:'button', text:_('Save'), icon:'/static/images/icons/save.svg', handler: function(){ save_form() } }
                            ],
                            bodyCssClass: 'rule-op-edit-form',
                            items: comp
                        });
                        show_win( node, form );
                    });
                } else {
                    var node_data = Ext.apply( res.config, node.attributes.data );
                    var comp = new Baseliner.DataEditor({ data: node_data });
                    show_win( node, comp, { width: 800, height: 400 } );
                }
            } else {
                Baseliner.error( _('Error'), res.msg );
            }
        });
    };

    function configureTextField(root, node, defaults) {
        if (!defaults) {
            defaults = {};
        }

        var submitted = false;
        var name_field_form;
        name_field_form = new Baseliner.FormPanel({
            frame: true,
            bodyCssClass:'login_form',
            buttons: [{
                text: _('OK'),
                handler: function() {
                    var form = name_field_form.getForm();

                    var ok = true;
                    form.items.each(function() {
                        var valid = this.validate();

                        if (ok && !valid) {
                            ok = false;
                        }
                    });

                    if (ok) {
                        var name_field = form.findField('name_field').getValue();
                        var id_field = form.findField('id_field').getValue();

                        if (!id_field) {
                            id_field = Baseliner.name_to_id(name_field);
                        }

                        node.attributes.data = {
                            "id_field": id_field,
                            "bd_field": id_field,
                            "fieldletType": node.attributes.key,
                            "editable": "1",
                            "hidden": "0",
                            "active": "1"
                        };
                        node.setText(name_field);

                        submitted = true;
                        win.close();
                    }
                }
            }, {
                text: _('Cancel'),
                handler: function() {
                    node.remove(true);
                    win.close();
                }
            }],
            defaults: {
                msgTarget: 'under'
            },
            items: [{
                xtype: 'textfield',
                allowBlank: false,
                fieldLabel: _('Name'),
                name: 'name_field',
                value: defaults.name_field,
                anchor: '95%',
                listeners: {
                    change: function(field, newVal, oldVal) {
                        var id = Baseliner.name_to_id(newVal);

                        var id_field = name_field_form.getForm().findField('id_field');
                        id_field.setValue(id);
                    }
                },
            }, {
                xtype: 'textfield',
                allowBlank: false,
                fieldLabel: _('ID'),
                name: 'id_field',
                anchor: '95%',
                vtype:'fieldletId',
                validator: function(val) {
                    var exists = false;
                    root.eachChild(function(node) {
                        var data = node.attributes.data;
                        if (data.id_field == val) {
                            exists = true;
                        };
                    });

                    if (!exists) {
                        return true;
                    }

                    return _loc('Field with this id already exists');
                }
            }, ]
        });

        var win = new Ext.Window({
            title: _("Name assignment"),
            width: 350,
            modal: true,
            maximizable: false,
            resizable: false,
            colapsible: false,
            minimizable: false,
            items: [name_field_form]
        });

        win.on('close', function() {
            if (!submitted) {
                node.remove(true);
            }
        });
        win.show();
    };

    var rule_flow_show = function( id_rule, name, event_name, rule_event, rule_type, old_ts, icon ) {
        var drop_handler = function(e) {
            var n1 = e.source.dragData.node;
            var n2 = e.target;
            var attr1 = n1.attributes;
            var attr2 = n2.attributes;
            if( n1 == undefined || n2 == undefined ) return false;
            if( attr1.palette ) {
                if( attr1.holds_children ) {
                    attr1.leaf = false;
                }
                var copy = new Ext.tree.TreeNode( Ext.apply({}, attr1) );
                copy.attributes.id = Cla.id('rule');
                copy.attributes.palette = false;
                if (/fieldlet./.test(n1.attributes.key) && n1.attributes.loader.dataUrl == '/rule/palette'){
                    var root = n2.getOwnerTree().getRootNode();
                    configureTextField(root, copy);
                } else if (/dashlet.swarm/.test(n1.attributes.key) && n1.attributes.loader.dataUrl == '/rule/palette'){
                    copy.attributes.data = { 'autorefresh':"0", 'background_color':'#FFFFFF', 'columns':"6",'rows':"1",'start_mode':'auto',limit:'' };
                    copy.setText( copy.attributes.name );  // keep original node text name
                } else {
                    copy.setText( copy.attributes.name );  // keep original node text name
                }
                if( !copy.attributes.data ) copy.attributes.data={};
                if( copy.attributes.on_drop_js ) {
                    try {
                        eval("var foo = function(node,rule_tree){"+ copy.attributes.on_drop_js +"}");
                        foo(copy);
                    } catch(err) {
                        Baseliner.error(_('Node Error'), _('Error loading node: %1', err ) );
                        return false;
                    }
                }
                e.dropNode = copy;
            }
            return true;
        };

        var rule_tree_loader = new Ext.tree.TreeLoader({
            dataUrl: '/rule/stmts_load',
            baseParams: { id_rule: id_rule }
        });

        var rule_save = function(opt){
            var root = rule_tree.root;
            rule_tree.expandAll();
            root.cascade(function(nc){
                nc.attributes.expanded = nc.isExpanded();
            });
            var stmts = encode_tree( root );
            Baseliner.message( _('Rules'), _('Validating and saving rule...') );
            var json = Ext.util.JSON.encode( stmts );
            btn_save_tree.disable();
            btn_refresh_tree.disable();
            var save_action = function(opts){
                if( !opts ) opts={};
                var args = { id_rule: id_rule, stmts: json, old_ts: old_ts, timeout: 600000 };
                Ext.apply(args, opts);
                var rt_id = rule_tree.id;
                Baseliner.ajaxEval( '/rule/stmts_save', args, function(res) {
                    old_ts = res.old_ts;
                    if ( old_ts == ''){
                        Baseliner.confirm( _("User %1 has changed rule at %2. Are you sure you want to overwrite it?", res.username, res.actual_ts ), function(){
                            old_ts = res.actual_ts;
                            save_action({ ignore_dsl_errors: 1 });
                        });
                    }

                    if( btn_save_tree ) btn_save_tree.enable();
                    if( btn_refresh_tree ) btn_refresh_tree.enable();

                    if( res.success ) {
                        var msgcfg = {};
                        if( res.detected_errors ) msgcfg.image = IC('baseliner-message-warning');
                        Baseliner.message( _('Rule'), res.msg, msgcfg );
                        if( !Ext.getCmp(rt_id) ) return;  // in case the save is too long and the tree is gone
                        rule_tree.is_dirty = false;
                        if( opt.callback ) {
                            opt.callback( res );
                        }
                    }
                },function(res){
                    if( btn_save_tree ) btn_save_tree.enable();
                    if( btn_refresh_tree ) btn_refresh_tree.enable();
                    if( res.error_checking_dsl ) {
                        // show a decent window where to follow all errors that may come
                        var errwin = new Baseliner.Window({
                            title:_('Rule error'),
                            layout:'vbox', width: 800, height: 600, modal: true,
                            bodyStyle: 'background-color: #ccc',
                            layoutConfig: { align : 'stretch', pack  : 'start' },
                            items:[
                                { html:  String.format(
                                    '<div id="boot"><h2><span class="error-title" style="">{0}</span></h2></div>',
                                    _('DSL validation failed')
                                    ), flex:1 },
                                new Baseliner.MonoTextArea({ value: res.msg, flex:10 }),
                            ],
                            bbar: [
                                '->',
                                { xtype:'button', icon: '/static/images/icons/left.svg', text: _('Go Back'), handler: function(){ errwin.close() } },
                                { xtype:'button', icon: '/static/images/icons/save.svg', text: _('Always Ignore for this Rule and Save'), handler: function(){
                                    save_action({ ignore_dsl_errors: 1, ignore_error_always: 1 }); // repeat
                                    errwin.close();
                                }},
                                { xtype:'button', icon: '/static/images/icons/save.svg', text: _('Ignore and Save'), handler: function(){
                                    save_action({ ignore_dsl_errors: 1 }); // repeat
                                    errwin.close();
                                }}
                            ]
                        });
                        errwin.show();
                    } else {
                        Baseliner.error( _('Error saving rule'), res.msg );
                    }
                });
            };
            // ignore dsl errors if the rule is independent
            save_action({ ignore_dsl_errors: 0 });
        };
        var rule_load_do = function(btn,load_versions){
            if(btn) btn.disable();
            Ext.apply(rule_tree_loader.baseParams, { load_versions: load_versions ? 1 : 0 });
            rule_tree_loader.load( rule_tree.root );
            rule_tree.root.expand();
            rule_tree.is_dirty = false;
            if(btn) btn.enable();
        };
        var rule_load = function(btn,load_versions){
            rule_tree.search_clear();
            if( rule_tree.is_dirty ) {
                if( rule_tree.close_me() ) {
                    rule_load_do(btn,load_versions);
                } else {
                    return false;
                }
            } else {
                rule_load_do(btn,load_versions);
            }
        };
        var rollback_version = function( btn, node ) {
            Baseliner.ajaxEval('/rule/rollback_version', { version_id: node.attributes.version_id }, function(res){
                rule_load( null, true );
                Baseliner.message( _('Rollback Rule'), res.msg );
            });
            return;
        }
        var tag_version = function( btn, node ) {
            var tag_form = new Baseliner.FormPanel({
                url: '/rule/tag_version',
                frame: true,
                defaults: {
                    msgTarget: 'under'
                },
                items: [{
                    xtype: 'hidden',
                    name: 'version_id',
                    value: node.attributes.version_id
                }, {
                    xtype: 'textfield',
                    allowBlank: false,
                    fieldLabel: _('Tag'),
                    name: 'tag',
                    value: node.attributes.version_tag,
                    anchor: '95%'
                }],
                buttons: [{
                    text: _('Save'),
                    handler: function() {
                        var fp = this.ownerCt.ownerCt,
                            form = fp.getForm();

                        if (form.isValid()) {
                            form.submit({
                                success: function(form, action) {
                                    win.close();
                                    rule_load( null, true );
                                }
                            });
                        }
                    }
                }, {
                    text: _('Cancel'),
                    handler: function() {
                        win.close();
                    }
                }]
            });

            var win = new Ext.Window({
                title: _("Tag"),
                width: 350,
                modal: true,
                maximizable: false,
                resizable: false,
                colapsible: false,
                minimizable: false,
                items: [tag_form]
            });

            win.show();
            tag_form.getForm().findField('tag').focus('', 100);

            return;
        }
        var untag_version = function( btn, node ) {
            Baseliner.ajax_json('/rule/untag_version', {
                version_id: node.attributes.version_id
            }, function(res) {
                rule_load( null, true );
            }, function() {
            });

            return;
        }
        var short_name = name.length > 10 ? name.substring(0,20) : name;
        var node_dbl_click = function(node, event) {
            var attributes = node.attributes;
            if (attributes.id_rule) {
                var params = {
                    rule_id: attributes.id_rule,
                    rule_name: attributes.name,
                    rule_type: attributes.rule_type,
                    event_name: attributes.event_name ? attributes.event_name : attributes.rule_name,
                    rule_event: attributes.rule_event ? attributes.rule_event : attributes.rule_name,
                    icon: attributes.icon
                };
                show_rules(params);
            } else {
                node.id_rule = id_rule;
                edit_node(node);
            }
        };
        var menu_click = function(node,event){
            if (node.attributes.is_current) return false;
            if (node.attributes.is_version) {
                node.select();
                var has_version_tag = node.attributes.hasOwnProperty('version_tag') && node.attributes.version_tag;
                var items = [{
                    text: _('Rollback'),
                    handler: function() {
                        rollback_version(btn_refresh_tree, node)
                    },
                    icon: IC('arrow-undo-color')
                }, {
                    text: has_version_tag ? _('Change tag') : _('Add tag'),
                    handler: function() {
                        tag_version(btn_refresh_tree, node)
                    },
                    icon: IC('arrow-undo-color')
                }];
                if (has_version_tag) {
                    items.push({
                        text: _('Delete tag'),
                        handler: function() {
                            untag_version(btn_refresh_tree, node)
                        },
                        icon: IC('arrow-undo-color')
                    });
                }
                var stmts_menu = new Ext.menu.Menu({
                    items: items
                });

                stmts_menu.showAt(event.xy);
                return;
            }
            if (node.attributes.is_custom_folders_node) {
                node.select();
                var stmts_menu = new Ext.menu.Menu({
                    items: [{
                        text: _('Add new custom folder'),
                        handler: function() {
                            add_custom_folder(node)
                        },
                        icon: IC('folder_new')
                    }]
                });
                stmts_menu.showAt(event.xy);
            }

            var items = [{
                text: _('Configuration'),
                handler: function() {
                    edit_node(node)
                },
                icon: IC('edit')
            }, {
                text: _('Rename'),
                handler: function() {
                    rename_node(node)
                },
                icon:  IC('item-rename')
            }, {
                text: _('Properties'),
                handler: function() {
                    meta_node(node)
                },
                icon: IC('properties')
            }, {
                text: _('Note'),
                handler: function() {
                    meta_node(node, 2)
                },
                icon:  IC('field')
            }, {
                text: _('Copy'),
                handler: function(item) {
                    copy_node(node)
                },
                icon:  IC('copy')
            }, {
                text: _('Cut'),
                handler: function(item) {
                    cut_node(node)
                },
                icon:  IC('cut-edit')
            }, {
                text: _('Copy Shortcut'),
                handler: function(item) {
                    copy_shortcut(node)
                },
                icon:  IC('shortcut-add')
            }, {
                text: _('Paste'),
                handler: function(item) {
                    paste_node(node)
                },
                icon: IC('paste')
            }, {
                text: _('Run'),
                handler: function(item) {
                    dsl_node(node)
                },
                icon: IC('play')
            }, {
                text: _('Export'),
                handler: function(item) {
                    export_node(node)
                },
                icon: IC('export')
            }, {
                text: _('Import Here'),
                handler: function(item) {
                    import_node(node)
                },
                icon: IC('import')
            }, {
                text: _('Toggle'),
                handler: function(item) {
                    toggle_node(node)
                },
                icon: IC('restart-new')
            }];

            var parentNode = node.parentNode;
            var nodeKey = node.attributes.key;
            var mandatoryNode = (nodeKey == 'fieldlet.system.title'|| nodeKey == 'fieldlet.system.status_new') ? true : false;

            if (!mandatoryNode) {
                node.select();
                items.push({
                    text: _('Delete'),
                    handler: function(item) {
                        delete parentNode.attributes.children;
                        parentNode.removeChild(node, true);
                    },
                    icon: IC('delete')
                });
            }
            var stmts_menu = new Ext.menu.Menu({
                items: items
            });

            stmts_menu.showAt(event.xy);
        };
        var btn_save_tree = new Ext.Button({ cls: 'ui-comp-rule-view-save', text: _('Save'), icon:'/static/images/icons/save.svg', handler: rule_save });
        var btn_refresh_tree = new Ext.Button({ tooltip: _('Refresh'), icon:'/static/images/icons/refresh.svg', handler: function(){ rule_load(btn_refresh_tree) } });
        var btn_dsl = new Ext.Button({ text: _('Run'), icon:'/static/images/icons/play.svg', handler: function() { rule_tree.rule_dsl() } });
        var blame_now = function(){
            if( this.checked ) {
                rule_tree.blame_time = this.tdiff;
                rule_tree.redecorate();
            }
        }
        var menu_blame_time = new Ext.menu.Menu({ items:[
              { text:_('Off'), checked: true, group:'blame-time', tdiff: null, hideOnClick:false, checkHandler: blame_now },
              { text:'1H', checked: true, group:'blame-time', tdiff: 3600000, hideOnClick:false, checkHandler: blame_now },
              { text:'12H', checked: false, group:'blame-time', tdiff: 43200000, hideOnClick:false, checkHandler: blame_now },
              { text:'1D', checked: false, group:'blame-time', tdiff: 86400000, hideOnClick:false, checkHandler: blame_now },
              { text:'7D', checked: false, group:'blame-time', tdiff: 86400000, hideOnClick:false, checkHandler: blame_now },
              { text:'30D', checked: false, group:'blame-time', tdiff: 2592000000, hideOnClick:false, checkHandler: blame_now },
              { text:_('All'), checked: false, group:'blame-time', tdiff: -1, hideOnClick:false, checkHandler: blame_now }
            ] });

        // node search system
        var btn_search = new Ext.Button({ icon: IC('wrench'), menu:[
            { text: _('Search'), icon:'/static/images/icons/search-small.svg',  hideOnClick: false, handler: function(){ rule_tree.search_nodes(search_box.getValue()) } },
            { text: _('Clear'), icon:'/static/images/icons/wipe-cache.svg', hideOnClick: false, handler: function(){ rule_tree.search_clear() } },
            { text: _('Regular Expression'), hideOnClick: false, checked: (Prefs.search_box_re==undefined?true:Prefs.search_box_re), handler:function(){ Prefs.search_box_re=!this.checked; } },
            { text: _('Ignore Case'), hideOnClick: false, checked: (Prefs.search_box_icase==undefined?false:Prefs.search_box_icase), handler:function(){ Prefs.search_box_icase=!this.checked; } },
            '-',
            { text:_('Blame By Time'), menu: menu_blame_time }
        ]});
        var search_box = new Baseliner.SearchSimple({
            width: 140,
            handler: function(){
                var t = this.getValue();
                if( t && t.length>0 ) {
                    rule_tree.search_nodes(t);
                } else {
                    rule_tree.search_clear();
                }
            }
        });

        var btn_version_tree = new Ext.Button({ enableToggle: true, pressed: false, tooltip: _('History'), icon:'/static/images/icons/slot.svg',
            handler: function() {
                if( btn_version_tree.pressed ) {
                    var ok = rule_load( btn_refresh_tree, true );
                    if( ok === false ) {  // maybe user hit cancel
                        btn_version_tree.toggle(false);
                    } else {
                        btn_save_tree.disable();
                        btn_dsl.disable();
                        btn_refresh_tree.disable();
                    }
                } else {
                    btn_save_tree.enable();
                    btn_refresh_tree.enable();
                    btn_dsl.enable();
                    rule_load_do( btn_refresh_tree, false );
                }
            }
        });

        var rule_tree = new Ext.tree.TreePanel({
            region: 'center',
            id_rule: id_rule,
            title: name,
            rule_type: rule_type,
            closable: true,
            autoScroll: true,
            useArrows: true,
            animate: true,
            lines: true,
            enableSort: true,
            enableDD: true,
            ddScroll: true,
            loader: rule_tree_loader,
            listeners: {
                beforenodedrop: { fn: drop_handler },
                contextmenu: menu_click,
                dblClick: node_dbl_click
            },
            rootVisible: true,
            tbar: [
                search_box,
                btn_refresh_tree,
                btn_save_tree,
                btn_dsl,
                btn_search,
                '->',
                { xtype:'button', icon:'/static/images/icons/expandall.svg', tooltip:_('Expand All'), handler: function() { rule_tree.expandAll() } },
                { xtype:'button', icon:'/static/images/icons/collapseall.svg',tooltip:_('Collapse All'),  handler: function() { rule_tree.collapseAll() } },
                btn_version_tree,
                {
                    xtype: 'button',
                    icon: IC('views.svg'),
                    text: _('View'),
                    menu: [{
                        icon: '/static/images/icons/workflow.svg',
                        text: _('Flowchart'),
                        handler: function() {
                            rule_tree.flowchart()
                        }
                    }, {
                        icon: IC('logo-html'),
                        text: _('HTML'),
                        handler: function() {
                            rule_tree.view_docs()
                        }
                    }]
                }
            ],
            root: {
                text: String.format('<strong>{0}</strong>', _('Start: %1', event_name || short_name) ),
                cls: 'ui-comp-rules-tree-start',
                name: _('Start: %1', event_name || short_name),
                draggable: false,
                id: 'root',
                icon: get_icon_category(rule_type),
                expanded: true
            }
        });

        rule_tree.make_dirty = function(){ rule_tree.is_dirty = true };
        rule_tree.on('movenode', rule_tree.make_dirty );
        rule_tree.on('nodedrop', rule_tree.make_dirty );
        rule_tree.on('remove', rule_tree.make_dirty );
        // best place to decorate
        rule_tree.on('append', function(t,p,n){
            setTimeout( function(){ rule_tree.node_decorate(n) }, 500 ) ;
        });
        rule_tree.on('afterrender', function(){
            new Ext.KeyMap( rule_tree.body, {
                key: 'scpr', scope: rule_tree.body,
                stopEvent: true,
                fn: function(key){
                    var node = rule_tree.getSelectionModel().selNode;
                    if( node ) {
                        if( key=='R'.charCodeAt() ) rename_node(node);
                        else if( key=='C'.charCodeAt() ) edit_node(node);
                        else if( key=='P'.charCodeAt() ) meta_node(node);
                        else if( key=='N'.charCodeAt() ) meta_node(node,2);
                        else if( key=='T'.charCodeAt() ) toggle_node(node);
                    }

                    return false;
                }
            });
        });
        rule_tree.close_me = function() {
            return confirm(_("Rule '%1' has changed, but has not been saved. Leave without saving?", rule_tree.title));
        };
        rule_tree.search_clear = function(){
            var clear_node = function(n){
                try { n.ui.getEl().children[0].style.backgroundColor = null; } catch(e){ };
                n.eachChild(clear_node);
            };
            clear_node(rule_tree.root);
            btn_search.setText( '' );
        };
        rule_tree.search_nodes = function(str){
            if( str == undefined ) str = search_box.getValue()
            if( str==undefined || str=='' ) return;
            var re_opts = '';
            rule_tree.search_found = rule_tree.search_total = 0;
            if(Prefs.search_box_icase) re_opts += 'i';
            if(!Prefs.search_box_re) str=str.replace(/([.?*+^$[\]\\(){}|-])/g, "\\$1");
            var re = new RegExp(str,re_opts);
            var root = rule_tree.root;
            btn_search.setText( '<img src="/static/images/loading/loading-fast.gif" />') ;
            var expand_parents = function(n){
                if(n.parentNode) {
                    expand_parents(n.parentNode);
                    n.parentNode.expand();
                }
            };
            var search_node = function(n){
                var attr = Baseliner.clone(n.attributes);
                delete attr.children;
                delete attr.loader;
                if( re.test( Ext.util.JSON.encode(attr) ) ) {
                    expand_parents(n);
                    try { n.ui.getEl().children[0].style.backgroundColor = '#fff8dc'; } catch(e){ };
                    rule_tree.search_found++;
                }
                else {
                    try { n.ui.getEl().children[0].style.backgroundColor = null; } catch(e){ };
                }
                rule_tree.search_total++;
                n.eachChild( search_node );
            };
            root.eachChild( search_node );
            btn_search.setText( _('(%1/%2)', rule_tree.search_found||0, rule_tree.search_total||0) );
        };

        rule_tree.redecorate = function(n){
            if(!n) n = rule_tree.root;
            rule_tree.node_decorate(n);
            n.eachChild( rule_tree.redecorate );
        };
        rule_tree.node_decorate = function( node ) {
            var attr = node.attributes;
            var rf = _bool(attr.run_forward,true);
            var rr = _bool(attr.run_rollback,true);
            var props = [], parallel_mode=[], debug_mode=[], parallel_stash_keys='', data_key='';
            var blame = false;
            var semaphore_key='';
            var shortcut = false;
            if( !attr.disabled ) {
                if( rf && !rr ) {
                    props.push('NO ROLLBACK');
                }
                else if( rr && !rf ) {
                    props.push('ROLLBACK');
                }
                else if( !rr && !rf ) {
                    props.push('NO RUN');
                }
                if( attr.debug_mode && attr.debug_mode!='none' ) {
                    debug_mode.push( attr.debug_mode );
                }
                if( attr.parallel_mode && attr.parallel_mode!='none' ) {
                    parallel_mode.push( attr.parallel_mode );
                }
                if( attr.data && attr.data.parallel_stash_keys && attr.data.parallel_stash_keys.length ) {
                    parallel_stash_keys = '\u21D0 ' + attr.data.parallel_stash_keys;
                }
                if( attr.data_key ) {
                    data_key = '= ' + attr.data_key;
                }
                if( attr.semaphore_key ) {
                    semaphore_key = '\u00D8 ' + attr.semaphore_key;
                }
                if( attr.has_shortcut ) {
                    shortcut = true ;
                }
                if( attr.ts ) {
                    var ts = Cla.moment(attr.ts);
                    var bt = rule_tree.blame_time;
                    if( bt!=undefined && ( bt==-1 || ((new Date() - ts ) < bt) ) )
                        blame = String.format('{0}: {1}', attr.who, ts.fromNow() );
                }
            }
            if( attr.note ) node.setTooltip( attr.note );
            var nel = node.ui.getTextEl();
            if( nel ) {
                var nn = node.id;
                // cleanup if no properties, needed by save on properties panel
                $( "[parent-node-props='"+nn+"']" ).remove();
                var badges='';
                if( data_key.length ) badges += '<span class="label" style="font-size: 9px; background-color:#606090">'+data_key+'</span>&nbsp;';
                if( semaphore_key.length ) badges += '<span class="label" style="font-size: 9px; background-color:#906060">'+semaphore_key+'</span>&nbsp;';
                if( props.length ) badges += props.map(function(r){ return '<span class="badge" style="font-size: 9px;">'+r+'</span>&nbsp;' }).join('');
                if( debug_mode.length ) badges += debug_mode.map(function(r){ return '<span class="badge" style="font-size: 9px; background-color:#404040; text-transform: uppercase;">DEBUG: '+r+'</span>&nbsp;' }).join('');
                if( parallel_mode.length ) badges += parallel_mode.map(function(r){ return '<span class="badge" style="font-size: 9px; background-color:#609060; text-transform: uppercase;">'+r+'</span>&nbsp;' }).join('');
                if( parallel_stash_keys.length ) badges += '<span class="label" style="font-size: 9px; background-color:#606090">'+parallel_stash_keys+'</span>&nbsp;';
                if( shortcut ) badges += '<img style="height: 12px; margin-top: -5px" src="/static/images/icons/shortcut.svg" />';
                if( blame ) badges += '<span class="label" style="font-size: 9px; background-color:#606090">'+blame+'</span>&nbsp;';
                if( badges.length ) {
                    nel.insertAdjacentHTML( 'afterEnd',
                        '<span id="boot" parent-node-props="'+nn+'" style="margin: 0px 0px 0px 4px; background: transparent">'+badges+'</span>');
                }
            }
        };

        rule_tree.rule_dsl = function(from,include){
            var root = from || rule_tree.root;
            var stmts = encode_tree( root, include );
            var json = Ext.util.JSON.encode( stmts );
            Baseliner.ajaxEval( '/rule/dsl', { id_rule: id_rule, rule_type: rule_type, stmts: json, event_key: rule_event }, function(res) {
                if( res.success ) {
                    var editor;
                    var stash_txt = new Ext.form.TextArea({ region:'west', split:true, width: 140, value: rule_tree.last_stash || res.data_yaml });
                    var dsl_txt = new Ext.form.TextArea({  value: res.dsl });
                    var style_cons = 'background: black; background-image: none; color: #10C000; font-family: "DejaVu Sans Mono", "Courier New", Courier';
                    var dsl_cons = new Ext.form.TextArea({ style:style_cons });
                    var dsl_cons_tab = new Ext.Panel({ layout:'fit', title:_('Output'), items: dsl_cons,
                        tbar: [
                                Baseliner.button(_('Raw'), '/static/images/icons/detach.svg', function() {
                                    var ww = window.open('about:blank', '_blank' );
                                    ww.document.title = _('REPL');
                                    ww.document.write( '<pre>' + dsl_cons.getValue() + '</pre>' );
                                    ww.document.close();
                                })
                        ]
                    });
                    var dsl_stash = new Ext.form.TextArea({ style:style_cons });
                    var dsl_stash_tab = new Ext.Panel({ layout:'fit', title:_('Stash'), items: dsl_stash,
                        tbar: [
                                Baseliner.button(_('Raw'), '/static/images/icons/detach.svg', function() {
                                    var ww = window.open('about:blank', '_blank' );
                                    ww.document.title = _('REPL');
                                    ww.document.write( '<pre>' + dsl_stash.getValue() + '</pre>' );
                                    ww.document.close();
                                })
                        ]
                    });
                    var dsl_run = function(){
                        dsl_cons.setValue( '' );
                        dsl_stash.setValue( '' );
                        Baseliner.ajaxEval( '/rule/dsl_try', { stash: stash_txt.getValue(), dsl: editor.getValue(), event_key: rule_event }, function(res) {
                            Baseliner.message( 'Rule Runner', _('Finished OK') );
                            document.getElementById( dsl_cons.getId() ).style.color = "#10c000";  // green
                            var out = res.output != undefined ? res.output : '';
                            dsl_cons.setValue( out );
                            dsl_stash.setValue( res.stash_yaml );
                        }, function(res){
                            var msg = Baseliner.escapeHtmlEntities( res.msg );
                            Baseliner.message( 'Rule Runner', _('Error during DSL execution: %1', msg ), { time: 4000 } );
                            var el_cons = document.getElementById( dsl_cons.getId() );
                            if(!el_cons) return;
                            el_cons.style.color = "#f54";  // red
                            var out = res.output != undefined ? res.output : '';
                            dsl_cons.setValue( out + '\n\n********* DSL ERROR ********\n\n' + res.msg );
                            dsl_stash.setValue( res.stash_yaml );
                        });
                    };
                    var win = new Baseliner.Window({
                        layout: 'border',
                        width: 1024,
                        height: 650,
                        maximizable: true,
                        title: _('DSL: %1', name),
                        tbar: [{
                            text: _('Run'),
                            icon: '/static/images/icons/play.svg',
                            handler: dsl_run
                        }],
                        keys: [{
                            key: [10, 13],
                            ctrl: true,
                            fn: dsl_run
                        }],
                        items: [
                            stash_txt, {
                                region: 'center',
                                xtype: 'panel',
                                height: 400,
                                items: dsl_txt
                            }, {
                                xtype: 'tabpanel',
                                items: [dsl_cons_tab, dsl_stash_tab],
                                activeTab: 0,
                                plugins: [new Ext.ux.panel.DraggableTabs()],
                                region: 'south',
                                split: true,
                                height: 200
                            }
                        ]
                    });
                    win.on('beforeclose', function(){
                        rule_tree.last_stash = stash_txt.getValue();
                    });
                    dsl_txt.on('afterrender', function(){
                        editor = CodeMirror.fromTextArea( dsl_txt.getEl().dom , Ext.apply({
                               lineNumbers: true,
                               tabMode: "indent", smartIndent: true,
                               matchBrackets: true
                            }, Cla.AceEditor )
                        );
                    });
                    win.show();
                } else {
                    Baseliner.error( _('Error saving rule'), res.msg );
                }
            });
        };

        // ------ rule documentation
        var md_converter = new Markdown.Converter();
        var doc_gen = function(node,depth,doc,lev){
            if( depth==undefined ) depth=0
            if( doc==undefined ) doc=[];
            var k = 1;
            node.eachChild(function(n){
                var attr = n.attributes;
                var note_html = attr.note!=undefined ? md_converter.makeHtml(attr.note) : '';
                var rf = attr.run_forward, rb = attr.run_rollback;
                var dd = attr.data!=undefined ? YAML.stringify(attr.data) : '';
                dd.replace("\n", "<br>");
                dd.replace("\\n", "<br>");
                doc.push({ text:n.text,
                    depth:depth,
                    icon: attr.icon,
                    lev: lev.length>0 ? lev.join('.')+'.'+k : k,
                    debug_mode: attr.debug_mode && attr.debug_mode!='none'
                        ? _(attr.debug_mode) : '',
                    parallel_mode: attr.parallel_mode && attr.parallel_mode!='none'
                        ? _(attr.parallel_mode) : '',
                    run_mode: rf && !rb ? _('NO ROLLBACK')
                        : !rf && rb ? _('ROLLBACK')
                        : rf===false && rb===false ? _('NO RUN') : '',
                    disabled: attr.disabled,
                    data: dd,
                    key:attr.key,
                    name: attr.name||attr.text, note: note_html });
                doc_gen(n,depth+1,doc, [].concat(lev,[k]) );
                k++;
            });
        }
        var doc_title = function(){/*
            <h1>[%= name %]</h1>
            <hr />
        */}.tmpl();
        var doc_tmpl = function(){/*
            <div style="padding-left: [%= depth * 24 %]px">
            <h3 class="rule" style="text-decoration: [%= disabled ? 'line-through' : 'none' %]">
                [%= lev %]
                <img style="vertical-align: middle; float: left" src="[%= icon %]"> [%= text %]
            [% if( run_mode ) { %]<span class="badge">[%= run_mode %]</span>[% } %]
            [% if( debug_mode ) { %]<span class="badge" style="background-color: #404040; text-transform: uppercase;">[%= debug_mode %]</span>[% } %]
            [% if( parallel_mode ) { %]<span class="badge" style="background-color: #609060; text-transform: uppercase;">[%= parallel_mode %]</span>[% } %]
            </h3>
            <div style="margin-left: 16px">
            <small class="rule" style="color:#999">[%= name %] - [%= key %]</small>
            <p>[%= note %]</p>
            [% if( data.length ) { %]
            <pre><code>[%= data %]</code></pre>
            [% } %]
            </div>
            </div>
        */}.tmpl();
        rule_tree.view_docs = function(from,depth,doc){
            var root = from || rule_tree.root;
            var doc = [];
            doc_gen(root,0,doc,[]);
            var html = [ doc_title({ name: Ext.util.Format.capitalize(name) }) ];
            Ext.each( doc, function(d){
                html.push( doc_tmpl(d) );
            });
            Baseliner.print({ title: name, html: '<div id="boot">'+html.join('')+'</div>' }, true);
        };
        rule_tree.flowchart = function(from, depth, doc) {
            var root = from || rule_tree.root;
            Cla.use(['/static/gojs/go-debug.js', '/comp/rule_flowchart.js'], function() {
                var btn_back = new Ext.Button({
                    text: _('Back'),
                    icon: IC('arrow-left'),
                    handler: function() {
                        rule_card.getLayout().setActiveItem(0);
                        rule_card.remove(dg, true);
                    }
                });
                var stmts = encode_tree(rule_tree.root);
                var json = Ext.util.JSON.encode(stmts);
                var dg = new Cla.RuleFlowchart({
                    json: json,
                    tbar: [btn_back]
                });
                rule_card.add(dg);
                rule_card.getLayout().setActiveItem(dg);
            });
        };
        var rule_card = new Ext.Panel({
            closable: true,
            autoScroll: true,
            layout: 'card',
            activeItem: 0,
            items: [rule_tree],
            id_rule: id_rule,
            tree: rule_tree,
            title: String.format('{0}: {1}', id_rule, short_name)
        });
        rule_card.close_me = function() {
            return confirm(_("Rule '%1' has changed, but has not been saved. Leave without saving?", rule_card.title));
        };

        var tab = tabpanel.add(rule_card);
        tab.on('beforeclose', function(card) {
            if (card.tree && card.tree.is_dirty) {
                return card.close_me();
            }
            return true;
        });
        tabpanel.setActiveTab(tab);
        var icon = get_icon_category(rule_type);
        tabpanel.changeTabIcon(tab, icon || '/static/images/icons/workflow.svg');
    };

    var menu_tab = new Ext.ux.TabCloseMenu({
        closeTabText: _('Close Tab'),
        closeOtherTabsText: _('Close Other Tabs'),
        closeAllTabsText: _('Close All Tabs')
    });

    var tabpanel = new Ext.TabPanel({
        region: 'center',
        enableTabScroll: true,
        plugins: [ new Ext.ux.panel.DraggableTabs()],
        items: []
    });
    var search_palette = new Baseliner.SearchSimple({
        name: 'palette_search',
        width: 190,
        handler: function(){
            var lo = palette.getLoader();
            lo.baseParams = { query: this.getValue() };
            lo.load( palette.root );
        }
    });
    var palette = new Ext.tree.TreePanel({
        region: 'east',
        cls: 'ui-comp-palette',
        title: _('Palette'),
        width: 250,
        autoScroll: true,
        split: true,
        animate: true,
        lines: true,
        enableDrag: true,
        collapsible: true,
        resizable: true,
        tbar: [
            search_palette, {
                xtype: 'button',
                tooltip: _('Collapse'),
                icon: '/static/images/icons/collapseall.svg',
                handler: function() {
                    palette.collapseAll();
                }
            }, {
                xtype: 'button',
                tooltip: _('Refresh Node'),
                icon: '/static/images/icons/refresh.svg',
                handler: function() {
                    palette.loader.load(palette.root);
                }
            }
        ],
        dataUrl: '/rule/palette',
        rootVisible: false,
        useArrows: true,
        root: { nodeType: 'async', text: _('Palette'), draggable: false, id: 'root', expanded: true }
    });
    palette.on('beforechildrenrendered', function(node){
        node.eachChild(function(n) {
            var key = n.attributes.key;
            if( key != undefined ) {
                n.attributes.name = n.attributes.text; // save original for later
                n.setText( n.attributes.text + String.format('<span style="padding-left: 5px;color:#bbb">{0}</span>',key) );
            }
        });
    });

    var toggle_button = new Ext.Button(
        {
            tooltip:_('Tree view'),
            pressed: false,
            stateful: true,
            toggleGroup:'rule-tree-group'+Ext.id(),
            icon: '/static/images/icons/catalog-folder.svg',
            cls: 'x-btn-icon',
            handler: activate_tree_view
        }
    );


    toggle_button.on('click', function(){
        if(toggle_button.pressed){
            do_search('to_tree');
        }else{
            do_search('to_grid');
        }
    });


    var reload_data = function(){
        var t = searchField.getValue();
        if(toggle_button.pressed){
            // Tree mode reload
            reload_tree(t);
        } else {
            // Grid mode reload
            rules_store.baseParams.query = t;
            rules_store.reload();
        }
    };


    var left_panel = new Ext.Panel({
        region: 'west',
        layout: 'card',
        width: 320,
        split: true,
        collapsible: true,
        activeItem: 0,
        items: [ rules_grid, rules_tree ],
        tbar: [
            searchField,
            { xtype:'button', tooltip:_('Refresh'), handler: function(){ reload_data() }, icon:'/static/images/icons/refresh.svg', cls:'x-btn-icon' },
            { xtype:'button', tooltip:_('Create'), icon: '/static/images/icons/add.svg', cls: 'x-btn-icon ui-comp-rule-create', handler: rule_add },
            { xtype:'button', tooltip:_('Edit'), icon: '/static/images/icons/edit.svg', id: 'x-btn-edit', cls: 'x-btn-icon', handler: function(){ rule_edit(); }, disabled: true },
            { xtype:'button', tooltip:_('Delete'), icon: '/static/images/icons/delete.svg', id: 'x-btn-del', cls: 'x-btn-icon', handler: rule_del, disabled: true},
            { xtype:'button', tooltip:_('Activate'), icon: '/static/images/icons/restart-new.svg', id: 'x-btn-act', cls: 'x-btn-icon', handler: rule_activate, disabled: true },
            toggle_button,
            { xtype:'button', icon: '/static/images/icons/wrench.svg', tooltip:_('Import/Export'), cls: 'x-btn-icon', menu:[
                { text: _('Import YAML'), icon: '/static/images/icons/import.svg', handler: rule_import },
                { text: _('Import from File'), icon: '/static/images/icons/import.svg', handler: rule_import_file },
                '-',
                { text: _('Export YAML'), icon: '/static/images/icons/downloads-favicon.svg', handler: rule_export },
                { text: _('Export to File'), icon: '/static/images/icons/downloads-favicon.svg', handler: rule_export_file }
            ]}
        ]
    });


    var panel = new Ext.Panel({
        cls: 'ui-panel-rules',
        layout: 'border',
        items: [ left_panel, tabpanel, palette ]//rules_grid,
    });


    panel.on('beforeclose', function() {
        var close_this;
        tabpanel.cascade(function(card) {
            if (close_this !== false && card.tree && card.tree.is_dirty) {
                close_this = card.close_me();
            }
        });
        return close_this;
    });

    Baseliner.edit_check( panel, true );  // block window closing from the beginning
    panel.print_hook = function(){
        var at = tabpanel.activeTab;
        if( !at ) return { title: panel.title, id: panel.body.id };
        return {
            title: at.title,
            id: at.tree.body.id
        };
    };
    return panel;
})
