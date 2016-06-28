(function(params) {
    var roleFormPanel = new Ext.FormPanel({
        url: '/role/update',
        region: 'north',
        frame: true,
        labelWidth: 100,
        height: 130, // I am sorry, but this is the easiest way
        layout: 'column',
        split:true,
        defaults: {
            columnWidth: .5,
            msgTarget: 'under',
            layout: 'form',
            cls: 'role_form_column_body',
            itemCls: 'role_form_column_body_items'
        },
        items: [{
            items: [{
                xtype: 'hidden',
                name: 'id',
            }, {
                xtype: 'textfield',
                name: 'name',
                fieldLabel: _('Role Name'),
                allowBlank: false
            }, {
                xtype: 'textarea',
                name: 'description',
                height: 60,
                fieldLabel: _('Description')
            }]
        }, {
            items: [{
                    xtype: 'textfield',
                    name: 'mailbox',
                    fieldLabel: _('Mailbox')
                },
                new Baseliner.DashboardBox({
                    fieldLabel: _('Dashboards'),
                    name: 'dashboards',
                    anchor: '95%',
                    allowBlank: true
                })
            ]
        }]
    });

    var render_action = function(value, metadata, rec, rowIndex, colIndex, store) {
        var v = String.format('{0} (<code>{1}</code>)', _(value), rec.data.action);
        return v;
    }
    var cm = new Ext.grid.ColumnModel({
        defaults: {
            sortable: true // columns are not sortable by default           
        },
        columns: [{
            header: '',
            width: 20,
            dataIndex: 'action',
            sortable: false,
            renderer: function() {
                return String.format('<img src="{0}"/>', IC('action.svg'))
            }
        }, {
            header: _('Description'),
            width: 200,
            dataIndex: 'description',
            sortable: true,
            renderer: render_action
        }, {
            header: _('Baseline'),
            width: 50,
            dataIndex: 'bl',
            sortable: true,
            renderer: Baseliner.render_bl,
            editor: new Baseliner.model.ComboBaseline()
        }]
    });

    var treeLoader = new Ext.tree.TreeLoader({
        dataUrl: '/role/action_tree',
        baseParams: {
            type: 'all',
            id_role: params.id_role
        },
        preloadChildren: true
    });

    var tree_check_folder_enabled = function(root) { // checks if parent folder has children
        var flag = action_store.getCount() < 1 ? false : true;
        root.eachChild(function(child) {
            if (!child.disabled) {
                flag = false;
            }
        });
        if (flag) root.disable();
        else root.enable();
    };

    var tree_check_in_grid = function(node) {
        var ff = action_store.find('action', node.id);
        if (ff >= 0) { // check if its in the grid already
            node.disable();
        } else {
            node.enable();
        }
    };

    var tree_check = function(node) {
        if (node.isLeaf()) {
            //TODO: activar cuando metamos metodo que compruebe todas las bl
            //tree_check_in_grid( node );
            tree_check_folder_enabled(node.parentNode);
        } else {
            node.eachChild(function(child) {
                if (child.isLeaf()) {
                    tree_check(child);
                } else {
                    tree_check(child);
                    child.removeListener('expand', tree_check);
                    child.on({
                        'expand': {
                            fn: tree_check
                        }
                    });
                    if (child.hasChildNodes()) {
                        // tree_check_folder_enabled(child);
                    }
                }
            });
        }
    };

    var treeRoot = new Ext.tree.AsyncTreeNode({
        text: _('actions'),
        draggable: false,
        id: 'action.root',
        listeners: {
            expand: tree_check
        }
    });

    var search_box = new Baseliner.SearchSimple({
        width: 220,
        handler: function() {
            var lo = action_tree.getLoader();
            lo.baseParams = {
                id_role: params.id_role,
                query: this.getValue()
            };
            Baseliner.showLoadingMask(action_tree.getEl());
            lo.load(action_tree.root, function() {
                Baseliner.hideLoadingMask(action_tree.getEl());
            });
        }
    });
    var action_tree = new Cla.Tree({
        title: _('Available Actions'),
        loader: treeLoader,
        useArrows: true,
        ddGroup: 'secondGridDDGroup',
        animate: true,
        enableDrag: true,
        containerScroll: true,
        autoScroll: true,
        rootVisible: false,
        contextMenu: new Ext.menu.Menu({
            items: [{
                type: 'expand',
                text: 'Expand All'
            }, {
                type: 'collapse',
                text: 'Collapse All'
            }],
            listeners: {
                itemclick: function(item) {
                    switch (item.type) {
                        case 'expand':
                            var n = item.parentMenu.contextNode;
                            n.expand(true);
                            break;
                        case 'collapse':
                            var n = item.parentMenu.contextNode;
                            n.collapse(true);
                            break;
                    }
                }
            }
        }),
        root: treeRoot,
        tbar: [search_box],
        menu_click: function(node, e) {
            var c = node.getOwnerTree().contextMenu;
            c.contextNode = node;
            c.showAt(e.getXY());
        },
        listeners: {
            'render': function() {
                Baseliner.showLoadingMask(this.getEl());
            },
            'load': function() {
                this.getEl().unmask();
            }
        }
    });

    var store_role_users = new Baseliner.JsonStore({
        root: 'data',
        remoteSort: true,
        totalProperty: 'totalCount',
        id: 'id',
        baseParams: {
            id_role: params.id_role
        },
        url: '/role/roleusers',
        fields: ['user', 'projects']
    });
    var role_users = new Ext.grid.GridPanel({
        title: _('Users'),
        store: store_role_users,
        defaults: {
            sortable: true
        },
        autoScroll: true,
        viewConfig: {
            forceFit: true
        },
        stripeRows: true,
        columns: [{
            header: _('User'),
            width: 100,
            dataIndex: 'user',
            sortable: true
        }, {
            header: _('Scopes'),
            width: 100,
            dataIndex: 'projects',
            sortable: true,
            renderer: Baseliner.render_wrap
        }]
    });
    role_users.on('activate', function() {
        if (params.id_role && store_role_users.getCount() == 0)
            store_role_users.load();
    });

    var store_role_projects = new Baseliner.JsonStore({
        root: 'data',
        remoteSort: true,
        totalProperty: 'totalCount',
        id: 'id',
        baseParams: {
            id_role: params.id_role
        },
        url: '/role/roleprojects',
        fields: ['project', 'users']
    });
    var role_projects = new Ext.grid.GridPanel({
        title: _('Scopes'),
        store: store_role_projects,
        defaults: {
            sortable: true
        },
        autoScroll: true,
        stripeRows: true,
        viewConfig: {
            forceFit: true
        },
        columns: [{
            header: _('Scopes'),
            width: 100,
            dataIndex: 'project',
            sortable: true
        }, {
            header: _('Users'),
            width: 100,
            dataIndex: 'users',
            sortable: true,
            renderer: Baseliner.render_wrap
        }]
    });
    role_projects.on('activate', function() {
        if (params.id_role && store_role_projects.getCount() == 0)
            store_role_projects.load();
    });

    var roleNavigator = new Ext.TabPanel({
        region: 'west',
        plugins: [new Ext.ux.panel.DraggableTabs()],
        split: true,
        width: '45%',
        colapsible: true,
        cls: 'role_grid_edit_window',
        activeTab: 0,
        items: [action_tree, role_users, role_projects]
    });
    //////////////// Actions belonging to a role
    var action_store = new Ext.data.Store({
        fields: [{
            name: 'action'
        }, {
            name: 'description'
        }, {
            name: 'bl'
        }]
    });

    var search_grid = new Baseliner.SearchSimple({
        width: 220,
        handler: function() {
            var v = this.getRawValue();
            if (!v || !v.length) {
                this.el.dom.value = '';
                action_store.clearFilter();
                return;
            }
            var res = v.split(/\s+/).map(function(vv) {
                return new RegExp(vv, 'i')
            });
            action_store.filterBy(function(rec) {
                var all = 0;
                for (var i = 0; i < res.length; i++) {
                    if (res[i].test(rec.data.description + ';' + rec.data.action)) {
                        all++;
                    }
                }
                return all == res.length;
            });
        }
    });

    var roleGridPanel = new Ext.grid.EditorGridPanel({
        title: _('Role Actions'),
        region: 'center',
        autoScroll: true,
        store: action_store,
        split: true,
        stripeRows: true,
        viewConfig: {
            forceFit: true
        },
        clicksToEdit: 1,
        height: 450,
        width: 650,
        cm: cm,
        cls: 'role_grid_edit_window',
        sm: new Baseliner.RowSelectionModel({
            singleSelect: true
        }),
        tbar: [
            search_grid, '->',
            new Ext.Toolbar.Button({
                text: _('Remove Selection'),
                icon: '/static/images/icons/delete_red.svg',
                cls: 'x-btn-text-icon',
                handler: function() {
                    var sm = roleGridPanel.getSelectionModel();
                    if (sm.hasSelection()) {
                        var sel = sm.getSelected();
                        roleGridPanel.getStore().remove(sel);
                        tree_check(treeRoot);
                    }
                }
            }),
            new Ext.Toolbar.Button({
                text: _('Remove All'),
                icon: '/static/images/icons/del_all.svg',
                cls: 'x-btn-text-icon',
                handler: function() {
                    roleGridPanel.getStore().removeAll();
                    tree_check(treeRoot);
                }
            })
        ]
    });

    var convertGridPanelToJSON = function() {
        // turn grid into JSON to post data
        var cnt = roleGridPanel.getStore().getCount();
        var json = [];
        for (i = 0; i < cnt; i++) {
            var rec = roleGridPanel.getStore().getAt(i);
            json.push(Ext.util.JSON.encode(rec.data));
        }
        var json_res = '[' + json.join(',') + ']';
        return json_res;
    };

    roleGridPanel.on('afterrender', function() {
        Baseliner.showLoadingMask(roleGridPanel.getEl(), _('Loading...'));
        ////////// Setup the Drop Target - now that the window is shown
        var secondGridDropTarget = new Baseliner.DropTarget(roleGridPanel.getView().scroller.dom, {
            comp: roleGridPanel,
            ddGroup: 'secondGridDDGroup',
            notifyDrop: function(dd, e, data) {
                var n = dd.dragData.node;
                var s = action_store;
                var add_node = function(node) {
                    var rec = new Ext.data.Record({
                        action: node.id,
                        description: node.text,
                        bl: '*'
                    });
                    s.add(rec);
                    tree_check_folder_enabled(node.parentNode);
                };

                if (n.leaf) {
                    add_node(n);
                } else {
                    n.expand();
                    n.eachChild(function(child) {
                        if (!child.disabled)
                            add_node(child);
                    });
                }
                return true;
            }
        });
    });

    ////////// Role Single Row
    var role_data_store = new Baseliner.JsonStore({
        root: 'data',
        remoteSort: true,
        totalProperty: "totalCount",
        id: 'rownum',
        url: '/role/role_detail_json',
        fields: [{
            name: 'id'
        }, {
            name: 'name'
        }, {
            name: 'actions'
        }, {
            name: 'bl'
        }, {
            name: 'description'
        }, {
            name: 'mailbox'
        }, {
            name: 'dashboards'
        }]
    });
    ///////// Single Role Data Load Event
    role_data_store.on('load', function() {
        try {
            var rec = role_data_store.getAt(0);

            action_store.removeAll();
            if (rec && rec.data.id) {
                var gs = action_store;
                var rd = rec.data.actions;
                if (rd != undefined) {
                    for (var i = 0; i < rd.length; i++) {
                        var rec_action = new Ext.data.Record(rd[i]);
                        gs.add(rec_action);
                    }
                }

                var ff = roleFormPanel.getForm();
                ff.loadRecord(rec);
            }
            Baseliner.hideLoadingMask(roleGridPanel.getEl());
        } catch (e) {
            Cla.error(_('Error'), _('Could not load role form data') + ': ' + e.description);
        }
    });

    var panel_title = params.id_role ? _('Role: %1', params.role) : _('New Role');
    var rolePanel = new Ext.Panel({
        layout: 'border',
        tab_icon: IC('role.svg'),
        tbar: [
            '->', {
                text: _('Save'),
                cls: 'ui-comp-role-edit-save',
                icon: IC('save'),
                handler: function() {
                    var roleForm = roleFormPanel.getForm();
                    if (!roleForm.isValid()) return;

                    action_store.clearFilter();

                    roleForm.submit({
                        params: {
                            role_actions: convertGridPanelToJSON()
                        },
                        success: function(form, action) {
                            roleForm.findField("id").setValue(action.result.id);

                            var grid = Ext.getCmp(params.id_grid);
                            if (grid) {
                                grid.getStore().load();
                            }
                            Baseliner.showLoadingMask(action_tree.getEl());
                            action_tree.getRootNode().reload();

                            rolePanel.setTitle(_('Role: %1', roleForm.findField('name').getValue()));

                            Baseliner.message(_('Success'), action.result.msg);
                        },
                        failure: function(form, action) {
                            if (action.failureType != 'connect') {
                                if (!action.result.errors) {
                                    Baseliner.message(_('Error'), action.result.msg);
                                }
                            }
                        }
                    });
                }
            }, {
                text: _('Close'),
                cls: 'ui-comp-role-edit-close',
                icon: IC('close.svg'),
                handler: function() {
                    rolePanel.destroy()
                }
            }
        ],
        title: panel_title,
        items: [
            roleFormPanel,
            roleGridPanel,
            roleNavigator
        ]
    });

    role_data_store.load({
        params: {
            id: params.id_role
        }
    });

    roleFormPanel.doLayout();
    return rolePanel;
})
