(function(params){
    var ps = 30;
    var rules_store = new Baseliner.JsonStore({
        url: '/rule/grid', root: 'data',
        id: 'id', totalProperty: 'totalCount', 
        fields: [ 'rule_name', 'rule_type', 'rule_when', 'rule_event', 'rule_active', 'event_name', 'id' ]
    });
    var search_field = new Baseliner.SearchField({
        store: rules_store,
        width: 140,
        params: {start: 0, limit: ps },
        emptyText: _('<search>')
    });

    var rule_del = function(){
        var sm = rules_grid.getSelectionModel();
        if( sm.hasSelection() ) {
            Baseliner.confirm( _('Delete rule %1?', sm.getSelected().data.rule_name ), function(){
                var id_rule = sm.getSelected().data.id;
                Baseliner.ajaxEval( '/rule/delete', { id_rule: id_rule }, function(res){
                    if( res.success ) {
                        rules_store.reload();
                        Baseliner.message( _('Rule'), res.msg );
                        // remove tab if any
                        var tab_arr = tabpanel.find( 'id_rule', id_rule );
                        if( tab_arr.length > 0 ) {
                            tabpanel.remove( tab_arr[0] );
                        }
                    } else {
                        Baseliner.error( _('Error'), res.msg );
                    }
                });
            });
        }
    };

    var rule_export = function(){
        var sm = rules_grid.getSelectionModel();
        if( sm.hasSelection() ) {
            var activate = sm.getSelected().data.rule_active > 0 ? 0 : 1;
            Baseliner.ajaxEval( '/rule/export', { id_rule: sm.getSelected().data.id }, function(res){
                if( res.success ) {
                    var win = new Baseliner.Window({ height: 400, width: 800, items: new Baseliner.MonoTextArea({ value: res.yaml }), 
                         layout:'fit' });       
                    win.show();
                } else {
                    Baseliner.error( _('Rule Export'), res.msg );
                }
            });
        } else {
            Baseliner.message( _('Error'), _('Select rows first') );
        }
    };
    
    var rule_import = function(){
        var data = new Baseliner.MonoTextArea({ value:'' });
        var btn_imp = new Ext.Button({ text: _('Import YAML'), handler: function(){
            Baseliner.ajaxEval('/rule/import', { data: data.getValue(), type:'yaml' }, function(res){
                if( res.success ) { 
                    rules_store.reload();
                    Baseliner.message( _('Import'), _('Imported rule: %1', res.rule_name) );
                    win.close();
                }
            },function(res){
                Baseliner.error( _('Rule Export'), res.msg );
            });
        }});
        var win = new Baseliner.Window({ title:_('Import'), layout:'fit', width: 800, height: 600, tbar:[btn_imp], items:data });
        win.show();
    };
    
    var rule_activate = function(){
        var sm = rules_grid.getSelectionModel();
        if( sm.hasSelection() ) {
            var activate = sm.getSelected().data.rule_active > 0 ? 0 : 1;
            Baseliner.ajaxEval( '/rule/activate', { id_rule: sm.getSelected().data.id, activate: activate }, function(res){
                if( res.success ) {
                    rules_store.reload();
                    Baseliner.message( _('Rule'), res.msg );
                } else {
                    Baseliner.error( _('Error'), res.msg );
                }
            });
        }
    };
    var rule_edit = function(){
        var sm = rules_grid.getSelectionModel();
        if( sm.hasSelection() ) {
            Baseliner.ajaxEval( '/rule/get', { id_rule: sm.getSelected().data.id }, function(res){
                if( res.success ) {
                    rule_editor( res.rec );
                } else {
                    Baseliner.error( _('Error'), res.msg );
                }
            });
        }
    };
    var rule_add = function(){
        rule_editor({});
    };
    var rule_editor = function(rec){
        Baseliner.ajaxEval( '/comp/rule_new.js', { rec: rec }, function(comp){
            if( comp ) {
                var win = new Baseliner.Window({
                    title: _('Edit Rule'),
                    width: 900,
                    items: [ comp ]
                });
                comp.on('destroy', function(){
                    win.close()
                    rules_store.reload();
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

    var render_rule = function( v,metadata,rec ) {
        if( rec.data.rule_active == 0 ) 
            v = String.format('<span style="text-decoration: line-through">{0}</span>', v );
        return String.format(
            '<div style="float:left"><img src="{0}" /></div>&nbsp;'
            + '<b>{2}: {1}</b>',
            '/static/images/icons/rule.png',
            v, rec.data.id
        );
    };
    var rules_grid = new Ext.grid.GridPanel({
        region: 'west',
        width: 300,
        split: true,
        collapsible: true,
        viewConfig: {
            enableRowBody: true,
            forceFit: true,
            getRowClass : function(rec, index, p, store){
                //p.body = String.format( '<div style="margin: 0 0 0 32;"><table><tr>'
                var caption = '';
                if( rec.data.rule_type == 'event' ) {
                    caption =  _("%1 for event '%2'", _(rec.data.rule_when), rec.data.rule_event );
                } else if( rec.data.rule_type == 'chain' ) {
                    var default_chain = rec.data.rule_when || '-';
                    caption =  _('job chain: %1', '<span style="font-weight: bold; color: #48b010">'+default_chain+'</span>' );
                } else {
                    caption =  _('independent');
                }
                p.body = String.format( '<div style="margin: 0 0 0 32px;color: #777">{0}</div>', caption );
                return ' x-grid3-row-expanded';
            }
        },
        header: false,
        store: rules_store,
        columns:[
            { header: _('Rule'), width: 160, dataIndex: 'rule_name', renderer: render_rule },
            { header: _('Type'), width: 40, dataIndex: 'rule_type' }
        ],
        tbar: [ 
            search_field,
            { xtype: 'button', handler: function(){ rules_store.reload() }, icon:'/static/images/icons/refresh.gif', cls:'x-btn-icon' },
            { xtype:'button', icon: '/static/images/icons/add.gif', cls: 'x-btn-icon', handler: rule_add },
            { xtype:'button', icon: '/static/images/icons/edit.gif', cls: 'x-btn-icon', handler: rule_edit },
            { xtype:'button', icon: '/static/images/icons/delete.gif', cls: 'x-btn-icon', handler: rule_del },
            { xtype:'button', icon: '/static/images/icons/activate.png', cls: 'x-btn-icon', handler: rule_activate },
            { xtype:'button', icon: '/static/images/icons/wrench.png', cls: 'x-btn-icon', menu:[
                { text: _('Import'), icon: '/static/images/icons/import.png', handler: rule_import },
                { text: _('Export'), icon: '/static/images/icons/export.png', handler: rule_export }
            ]}
        ]
    });
    rules_store.load();
    
    rules_grid.on('rowclick', function(grid, ix){
        var rec = rules_store.getAt( ix ); 
        var get_rule_ts = Baseliner.ajaxEval('/rule/get_rule_ts', { id_rule: rec.data.id }, function(response){
            if (response.success){
                var old_ts = response.ts;
                if( rec ) {
                    var tab_arr = tabpanel.find( 'id_rule', rec.data.id );
                    if( tab_arr.length > 0 ) {
                        tabpanel.setActiveTab( tab_arr[0] );
                    } else {
                        rule_flow_show( rec.data.id, rec.data.rule_name, rec.data.event_name, rec.data.rule_event, rec.data.rule_type, old_ts );
                    }
                }
            }
        });
    });
   
    var encode_tree = function( root, include ){
        var stmts = [];
        if( include ) {
            stmts.push({ attributes: root.attributes, children: encode_tree( root ) });
        } else {
            root.eachChild( function(n){
                stmts.push({ attributes: n.attributes, children: encode_tree( n ) });
            });
        }
        return stmts;
    };

    var show_win = function(node, item, opts, foo) {
        var win = new Baseliner.Window(Ext.apply({
            layout: 'fit',
            title: _('Edit: %1', node.text),
            items: item
        }, opts));
        item.on('destroy', function(){
            if( !Ext.isFunction(foo) ) foo = function(d){ 
                node.getOwnerTree().is_dirty=true; 
                node.attributes.data = d; 
            };
            if( item.data ) foo(item.data); // item.data is only set if modified
            win.close();
        });
        win.show();
        return win;
    };
    
    var clipboard;
    var cut_node = function( node ) {
        clipboard = { node: node };
    };
    var clone_node = function(node){    
        var copy = new Ext.tree.TreeNode( Ext.apply({}, node.attributes) ) 
        node.eachChild( function( chi ){
            copy.appendChild( clone_node( chi ) );
        });
        return copy;
    };
    var dsl_node = function( node ) {
        node.getOwnerTree().rule_dsl(node,true);
    };
    var copy_node = function( node ) {
        var copy = clone_node( node ); 
        clipboard = { node: copy };
    };
    var paste_node = function( node ) {
        if( clipboard ) {
            var p = clipboard.node;
            p.id = Ext.id();
            p.cascade(function(n_chi){
                n_chi.id = Ext.id();
            });
            node.appendChild( p );
        }
        //clipboard = 
    };
    var node_decorate = function( node ) {
        var attr = node.attributes;
        var rf = _bool(attr.run_forward,true);
        var rr = _bool(attr.run_rollback,true);
        var props = [], parallel_mode=[], data_key='';
        var semaphore_key='';
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
            if( attr.parallel_mode && attr.parallel_mode!='none' ) {
                parallel_mode.push( attr.parallel_mode );
            }
            if( attr.data_key ) {
                data_key = '= ' + attr.data_key;
            }
            if( attr.semaphore_key ) {
                semaphore_key = '\u00D8 ' + attr.semaphore_key;
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
            if( parallel_mode.length ) badges += parallel_mode.map(function(r){ return '<span class="badge" style="font-size: 9px; background-color:#609060; text-transform: uppercase;">'+r+'</span>&nbsp;' }).join('');
            if( badges.length ) {
                nel.insertAdjacentHTML( 'afterEnd', '<span id="boot" parent-node-props="'+nn+'" style="margin: 0px 0px 0px 4px; background: transparent">'+badges+'</span>');
            }
        }
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
            fieldLabel: _('Needs Rollback?'), name:'needs_rollback_mode', value: data.needs_rollback_mode || 'none', 
            data: [ ['nb_after',_('Rollback Needed After')], ['nb_before',_('Rollback Needed Before')], 
                    ['nb_always',_('Rollback Needed Always')], ['none',_('No Rollback Necessary')] ]
        });
        needs_rollback_mode.on('select', function(){ needs_rollback_mode.getValue()!='none' ? needs_rollback_key.show() : needs_rollback_key.hide() }); 
        var needs_rollback_key = new Ext.form.TextField({ 
            name: 'needs_rollback_key', fieldLabel:_('Needs Rollback Key'), 
            hidden: !( !data.needs_rollback_mode || data.needs_rollback_mode!='none' ),
            value: Baseliner.name_to_id(node.text) 
        });
        var enabled = new Ext.form.Checkbox({ fieldLabel:_('Enabled'), checked: node.disabled===true?false:true });
        var run_forward = new Ext.form.Checkbox({ fieldLabel:_('Run Forward'), checked: _bool(attr.run_forward,true) });
        var run_rollback = new Ext.form.Checkbox({ fieldLabel:_('Run Rollback'), checked: _bool(attr.run_rollback,true) });
        var error_trap = new Baseliner.ComboDouble({ 
            fieldLabel: _('Error Trap'), name:'error_trap', value: attr.error_trap || 'none', 
            data: [ ['none',_('No Trap')], ['trap',_('Trap Errors')], ['ignore',_('Ignore Errors')] ]
        });
        var parallel_mode = new Baseliner.ComboDouble({ 
            fieldLabel: _('Parallel Mode'), name:'parallel_mode', value: attr.parallel_mode || 'none', 
            data: [ ['none',_('No Parallel')], ['fork',_('Fork and Wait')], ['nohup', _('Fork and Leave')] ]
        });
        var semaphore_key = new Ext.form.TextField({ fieldLabel:_('Semaphore Key'), name:'semaphore_key', value: attr.semaphore_key });
        var timeout = new Ext.form.TextField({ fieldLabel:_('Timeout'), name:'timeout', value: attr.timeout });
        var opts = new Baseliner.FormPanel({ title:_('Options'), labelWidth: 150, style:{ padding:'5px 5px 5px 5px'}, defaults:{ anchor:'100%' }, items:[
            enabled, data_key, needs_rollback_mode, needs_rollback_key, run_forward, run_rollback, timeout, semaphore_key, parallel_mode, error_trap
        ]});
        var btn_save_meta = new Ext.Button({ text:_('Save'), icon:'/static/images/icons/save.png', handler:function(){
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
            node.attributes.run_forward = run_forward.checked;
            node.attributes.run_rollback = run_rollback.checked;
            node.attributes.parallel_mode = parallel_mode.getValue();
            node.attributes.error_trap = error_trap.getValue();
            node.attributes.semaphore_key = semaphore_key.getValue().trim();
            node.attributes.timeout = timeout.getValue();
            node.attributes.note = note.getValue();
            node.setText( node.attributes.text );
            node_decorate( node );  // change the node's look
            // data save
            if( !node.attributes.data ) node.attributes.data={};
            Ext.apply(node.attributes.data, opts.getValues() );
            win.close(); 
        }});
        var tbar = [ '->', 
            { xtype:'button', text:_('Cancel'), icon:'/static/images/icons/delete.gif', handler: function(){ win.close() } },
            btn_save_meta ];
        opts.doLayout();
        de.doLayout();
        var tabs = new Ext.TabPanel({ activeTab: goto_tab==undefined?0:goto_tab, items:[ opts,de,note ] });
        var win = show_win( node, tabs, { width: 800, height: 600, tbar:tbar }, function(d){ 
            //node.attributes=d;
            //node.setText( d.text );
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
                    Baseliner.ajaxEval( res.form, { data: node.attributes.data || {} }, function(comp){
                        var params = {};
                        var save_form = function(){
                            form.data = form.getValues();
                            form.destroy();
                        };
                        var form = new Baseliner.FormPanel({ 
                            frame: false, forceFit: true, defaults: { msgTarget: 'under', anchor:'100%' },
                            labelWidth: 150,
                            width: 800, height: 600,
                            labelAlign: 'right',
                            autoScroll: true,
                            tbar: [
                                '->',
                                { xtype:'button', text:_('Cancel'), icon:'/static/images/icons/delete.gif', handler: function(){ form.destroy() } },
                                { xtype:'button', text:_('Save'), icon:'/static/images/icons/save.png', handler: function(){ save_form() } }
                            ],
                            bodyStyle: { padding: '4px', "background-color": '#eee' },
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

    var rule_flow_show = function( id_rule, name, event_name, rule_event, rule_type, old_ts ) {
        var drop_handler = function(e) {
            var n1 = e.source.dragData.node;
            var n2 = e.target;
            if( n1 == undefined || n2 == undefined ) return false;
            var attr1 = n1.attributes;
            var attr2 = n2.attributes;
            if( attr1.palette ) {
                if( attr1.holds_children ) {
                    attr1.leaf = false;
                } 
                var copy = new Ext.tree.TreeNode( Ext.apply({}, attr1) );
                copy.attributes.palette = false;
                copy.setText( copy.attributes.name );  // keep original node text name
                //n2.getOwnerTree().is_dirty = true;
                e.dropNode = copy;
            }
            return true;
        };
        
        var rule_tree_loader = new Ext.tree.TreeLoader({
            dataUrl: '/rule/stmts_load',
            baseParams: { id_rule: id_rule }
            //requestMethod:'GET',
            //uiProviders: { 'col': Ext.tree.ColumnNodeUI }
        });



        /* 
         * strikethrough disabled nodes
         * XXX causes strange call stack exceeded errors on encode_tree
         *
        rule_tree_loader.on('load', function(loader,node){
            node.cascade(function(n) {
                var act = n.attributes.active;
                if( act===undefined || act == '1' ) return;
                if( n.ui && n.ui.textNode ) n.ui.textNode.style.textDecoration = 'line-through';
            });
        });*/
    
        var rule_save = function(opt){
            var root = rule_tree.root;
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
                var args = { id_rule: id_rule, stmts: json, old_ts: old_ts };
                Ext.apply(args, opts);
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
                        rule_tree.is_dirty = false;
                        Baseliner.message( _('Rule'), res.msg );
                        if( opt.callback ) {
                            opt.callback( res );
                        }
                    }
                },function(res){
                    if( btn_save_tree ) btn_save_tree.enable();
                    if( btn_refresh_tree ) btn_refresh_tree.enable();
                    if( res.error_checking_dsl ) {
                        Baseliner.confirm( _('DSL validation failed, save it anyway? Error: %1', res.msg ), function(){
                            save_action({ ignore_dsl_errors: 1 }); // repeat    
                        });
                    } else {
                        Baseliner.error( _('Error saving rule'), res.msg );
                    }
                });
            };
            // ignore dsl errors if the rule is independent
            save_action({ ignore_dsl_errors: rule_type=='independent' ? 1 : 0 });
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
        var short_name = name.length > 10 ? name.substring(0,20) : name;
        var menu_click = function(node,event){
            if( node.attributes.is_current ) return false;
            if( node.attributes.is_version ) {
                node.select();
                var stmts_menu = new Ext.menu.Menu({
                    items: [
                        { text: _('Rollback'), handler: function(){ rollback_version( btn_refresh_tree, node ) }, icon:'/static/images/icons/arrow_undo.png' }
                    ]
                });
                stmts_menu.showAt(event.xy);
                return;
            }
            node.select();
            var stmts_menu = new Ext.menu.Menu({
                items: [
                    { text: _('Configuration'), handler: function(){ edit_node( node ) }, icon:'/static/images/icons/edit.gif' },
                    { text: _('Rename'), handler: function(){ rename_node( node ) }, icon:'/static/images/icons/item_rename.png' },
                    { text: _('Properties'), handler: function(){ meta_node( node ) }, icon:'/static/images/icons/leaf.gif' },
                    { text: _('Note'), handler: function(){ meta_node( node, 2 ) }, icon:'/static/images/icons/field.png' },
                    { text: _('Copy'), handler: function(item){ copy_node( node ) }, icon:'/static/images/icons/copy.gif' },
                    { text: _('Cut'), handler: function(item){ cut_node( node ) }, icon:'/static/images/icons/cut.gif' },
                    { text: _('Paste'), handler: function(item){ paste_node( node ) }, icon:'/static/images/icons/paste.png' },
                    { text: _('DSL'), handler: function(item){ dsl_node( node ) }, icon:'/static/images/icons/edit.png' },
                    { text: _('Toggle'), handler: function(item){ toggle_node(node) }, icon:'/static/images/icons/activate.png' },
                    { text: _('Delete'), handler: function(item){ node.remove() }, icon:'/static/images/icons/delete.gif' } 
                ]
            });
            stmts_menu.showAt(event.xy);
        };
        var btn_save_tree = new Ext.Button({ text: _('Save'), icon:'/static/images/icons/save.png', handler: rule_save });
        var btn_refresh_tree = new Ext.Button({ text: _('Reload'), icon:'/static/images/icons/refresh.gif', handler: function(){ rule_load(btn_refresh_tree) } });
        var btn_dsl = new Ext.Button({ text: _('DSL'), icon:'/static/images/icons/edit.png', handler: function() { rule_tree.rule_dsl() } });
        var btn_version_tree = new Ext.Button({ enableToggle: true, pressed: false, icon:'/static/images/icons/history.png', 
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
            closable: true,
            title: String.format('{0}: {1}', id_rule, short_name), 
            autoScroll: true,
            useArrows: true,
            animate: true,
            lines: true,
            //stripeRows: true,
            enableSort: true,
            enableDD: true,
            ddScroll: true,
            loader: rule_tree_loader,
            listeners: {
                beforenodedrop: { fn: drop_handler },
                contextmenu: menu_click
            },
            rootVisible: true,
            tbar: [ 
                btn_save_tree,
                btn_refresh_tree,
                btn_dsl,
                '->',
                { xtype:'button', icon:'/static/images/icons/expandall.png', tooltip:_('Expand All'), handler: function() { rule_tree.expandAll() } },
                { xtype:'button', icon:'/static/images/icons/collapseall.png',tooltip:_('Collapse All'),  handler: function() { rule_tree.collapseAll() } },
                btn_version_tree,
                { xtype:'button', icon:'/static/images/icons/html.png', handler: function() { rule_tree.view_docs() } }
            ],
            root: { 
                text: String.format('<strong>{0}</strong>', _('Start: %1', event_name || short_name) ), 
                name: _('Start: %1', event_name || short_name),
                draggable: false, 
                id: 'root', 
                icon: (rule_type=='chain'?'/static/images/icons/job.png':'/static/images/icons/event.png'), expanded: true }
        });
        rule_tree.make_dirty = function(){ rule_tree.is_dirty = true };
        rule_tree.on('movenode', rule_tree.make_dirty );
        rule_tree.on('nodedrop', rule_tree.make_dirty );
        rule_tree.on('remove', rule_tree.make_dirty );
        rule_tree.close_me = function(){ 
            return confirm(_("Rule '%1' has changed, but has not been saved. Leave without saving?", rule_tree.title ));
        };
        // best place to decorate
        rule_tree.on('append', function(t,p,n){
            setTimeout( function(){ node_decorate(n) }, 500 ) ;
        });
        
        rule_tree.rule_dsl = function(from,include){
            var root = from || rule_tree.root;
            //rule_save({ callback: function(res) { } });
            var stmts = encode_tree( root, include );
            var json = Ext.util.JSON.encode( stmts );
            Baseliner.ajaxEval( '/rule/dsl', { id_rule: id_rule, rule_type: rule_type, stmts: json, event_key: rule_event }, function(res) {
                if( res.success ) {
                    var editor;
                    var idtxt = Ext.id();
                    var stash_txt = new Ext.form.TextArea({ region:'west', split:true, width: 140, value: rule_tree.last_stash || res.data_yaml });
                    var dsl_txt = new Ext.form.TextArea({  value: res.dsl });
                    var style_cons = 'background: black; background-image: none; color: #10C000; font-family: "DejaVu Sans Mono", "Courier New", Courier';
                    var dsl_cons = new Ext.form.TextArea({ title:_('Output'), style:style_cons });
                    var dsl_stash = new Ext.form.TextArea({ title:_('Stash'), style:style_cons });
                    var dsl_run = function(){
                        dsl_cons.setValue( '' );
                        dsl_stash.setValue( '' );
                        Baseliner.ajaxEval( '/rule/dsl_try', { stash: stash_txt.getValue(), dsl: editor.getValue(), event_key: rule_event }, function(res) {
                            Baseliner.message( 'DSL', _('Finished OK') );
                            document.getElementById( dsl_cons.getId() ).style.color = "#10c000";  // green
                            var out = res.output != undefined ? res.output : '';
                            dsl_cons.setValue( out ); 
                            dsl_stash.setValue( res.stash_yaml );
                        }, function(res){
                            Baseliner.message( 'DSL', _('Error during DSL execution: %1', res.msg ) );
                            var el_cons = document.getElementById( dsl_cons.getId() );
                            if(!el_cons) return;
                            el_cons.style.color = "#f54";  // red
                            var out = res.output != undefined ? res.output : '';
                            dsl_cons.setValue( out + '\n\n========= DSL ERROR =======\n\n' + res.msg ); 
                            dsl_stash.setValue( res.stash_yaml );
                        });
                    };
                    var win = new Baseliner.Window({
                        layout: 'border', width: 1024, height: 650, maximizable: true,
                        //tabifiable: true,
                        title: _('DSL: %1', name ),
                        tbar: [ { text:_('Run'), icon:'/static/images/icons/run.png', handler: dsl_run } ],
                        keys: [{
                            key:[10,13],
                            ctrl: true,
                            fn: dsl_run
                        }],
                        items: [
                           stash_txt,
                           { region:'center', xtype:'panel', height: 400, items: dsl_txt  },
                           { xtype:'tabpanel', items: [dsl_cons, dsl_stash], activeTab:0, region:'south', split: true, height: 200 }
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
                            }, Baseliner.editor_defaults )
                        );
                    });
                    win.show();
                } else {
                    Baseliner.error( _('Error saving rule'), res.msg );
                }
            });
        };
        
        // ========= rule documentation 
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

        var tab = tabpanel.add( rule_tree ); 
        tab.on('beforeclose', function(tree){
            if( tree.is_dirty ) {
                return tree.close_me();
            }
            return true;
        });
        tabpanel.setActiveTab( tab );
        tabpanel.changeTabIcon( tab, '/static/images/icons/rule.png' );
    };
    /* 
    var tree = new Ext.tree.TreePanel({
        region: 'center',
        autoScroll: true,
        animate: true,
        lines: true,
        stripeRows: true,
        enableSort: false,
        enableDD: true,
        dataUrl: '/rule/tree',
        listeners: {
            beforenodedrop: { fn: drop_handler }
        },
        rootVisible: true,
        useArrows: true,
        root: { nodeType: 'async', text: 'Reglas', draggable: false, id: 'root', expanded: true }
    });
    */
    var menu_tab = new Ext.ux.TabCloseMenu({
        closeTabText: _('Close Tab'),
        closeOtherTabsText: _('Close Other Tabs'),
        closeAllTabsText: _('Close All Tabs')        
    });

    var tabpanel = new Ext.TabPanel({
        region: 'center',
        plugins: [ menu_tab ],
        items: []
    });
    var palette_fake_store = {  // the SearchField needs a store, but the tree doesnt have one
        baseParams: {},
        reload: function(config){
            var lo = palette.getLoader();
            lo.baseParams = palette_fake_store.baseParams;
            lo.load( palette.root );
        }
    };
    var search_palette = new Baseliner.SearchField({
        store: palette_fake_store,
        width: 220,
        params: {start: 0, limit: ps },
        emptyText: _('<search>')
    });
    var palette = new Ext.tree.TreePanel({
        region: 'east',
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
            search_palette,
            { xtype:'button', icon:'/static/images/icons/refresh.gif', 
                handler: function(){
                    palette.loader.load( palette.root ); 
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
    var panel = new Ext.Panel({
        layout: 'border',
        items: [ rules_grid, tabpanel, palette ]
    });
    panel.on('beforeclose', function(){
        var close_this;
        tabpanel.cascade(function(tree){
            if( close_this!== false && tree.is_dirty ) {
                close_this = tree.close_me();
            }
        });
        return close_this;
    });

    Baseliner.edit_check( panel, true );  // block window closing from the beginning
    panel.print_hook = function(){
        var at = tabpanel.activeTab;
        if( !at ) return { title: panel.title, id: panel.body.id };
        return { title: at.title, id: at.body.id };
    };
    return panel;
})
