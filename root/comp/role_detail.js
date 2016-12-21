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
                return String.format('<img src="{0}"/>', IC('action'))
            }
        }, {
            header: _('Description'),
            width: 100,
            dataIndex: 'description',
            sortable: true,
            renderer: render_action
        }, {
            header: _('Bounds'),
            width: 100,
            dataIndex: 'bounds',
            sortable: true,
            renderer: function(val, meta, rec, rowIndex, colIndex, store) {
                var meta = roleGridPanel.getStore().getAt(rowIndex);

                if (meta.data.bounds_available) {
                    if (val) {
                        return '<b>' + _('Set') + '</b>';
                    }
                    else {
                        return 'Any';
                    }
                }
                else {
                    return '';
                }
            }
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
            name: 'bounds'
        }, {
            name: 'bounds_available'
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

    function buildAddBoundFormItems(action, bounds, boundsStore) {
        var items = [];

        var comboItems = [];
        for (var i = 0; i < bounds.length; i++) {
            var bound = bounds[i];

            var combo = new Ext.form.ComboBox({
                fieldLabel: _(bound.name),
                typeAhead: true,
                triggerAction: 'all',
                lazyRender: true,
                name: bound.key,
                hiddenName: bound.key,
                editable: false,
                queryMode: 'local',
                valueField: 'id',
                displayField: 'title',
                allowBlank: false,
                msgTarget: 'under',
                store: new Ext.data.JsonStore({
                    autoDestroy: true,
                    url: '/role/bounds',
                    baseParams: {
                        action: action,
                        bound: bound.key,
                        filter: '{}'
                    },
                    root: 'data',
                    idProperty: 'id',
                    fields: [{
                        name: 'id'
                    }, {
                        name: 'title'
                    }]
                }),
                listeners: {
                    select: function() {
                        for (var i = 0; i < comboItems.length; i++) {
                            if (items[i].name === this.name) {
                                continue;
                            }

                            var depends;
                            for (var j = 0; j < bounds.length; j++) {
                                if (bounds[j].key === items[i].name) {
                                    depends = bounds[j].depends;
                                    break;
                                }
                            }

                            if (!depends || depends.indexOf(this.name) == -1) {
                                continue;
                            }

                            var combo = items[i];
                            combo.reset();

                            var store = combo.getStore();

                            var filter = JSON.parse(store.baseParams['filter']);
                            filter[this.name] = this.getValue();
                            filter = JSON.stringify(filter);

                            store.setBaseParam('filter', filter);
                            store.load({params: {filter: filter}});
                            store.reload();
                        }

                        return true;
                    }
                }
            });

            comboItems.push(combo);

            items.push(combo);
        }

        items.push({
            xtype: 'checkbox',
            name: '_deny',
            fieldLabel: _('Negative')
        });

        items.push(
            new Ext.Button({
                icon: IC('add'),
                text: _('Add'),
                handler: function() {
                    var formPanel = this.findParentByType(Ext.form.FormPanel);
                    var form = formPanel.getForm();

                    if (form.isValid()) {
                        var values = {};

                        form.items.each(function(field) {
                            if (typeof field.isXType !== 'function') {
                                return;
                            }

                            if (field.isXType('checkbox')) {
                                values[field.getName()] = field.getValue();
                            } else if (field.isXType('combo')) {
                                values[field.getName()] = field.getValue();
                                values['_' + field.getName() + '_title'] = field.lastSelectionText;
                            }
                        });

                        boundsStore.add(new Ext.data.Record(values));
                    }
                }
            })
        );

        return items;
    }

    function buildBoundsStore(bounds, values) {
        var boundsStoreFields = [];

        for (var i = 0; i < bounds.length; i++) {
            var bound = bounds[i];

            boundsStoreFields.push({name: bound.key});
        }

        var boundsStore = new Ext.data.Store({
            fields: boundsStoreFields
        });

        for (var i = 0; i < values.length; i++) {
            var rec = {};
            for (key in values[i]) {
                if (!values[i].hasOwnProperty(key)) {
                    continue;
                }

                rec[key] = values[i][key];
            }

            boundsStore.add(new Ext.data.Record(rec));
        }

        return boundsStore;
    }

    function buildBoundsColumnModel(bounds, values) {
        var boundsColumnModelColumns = [{
            header: _('Type'),
            dataIndex: '_deny',
            renderer: function(value) {
                if (!value)
                    return _('Allow');

                return _('Deny');
            }
        }];

        for (var i = 0; i < bounds.length; i++) {
            var bound = bounds[i];

            boundsColumnModelColumns.push({
                header: _(bound.name),
                dataIndex: '_' + bound.key + '_title',
                sortable: true,
                renderer: function(value) {
                    if (!value)
                        return _('Any');

                    return value;
                }
            });
        }

        var boundsColumnModel = new Ext.grid.ColumnModel({
            defaults: { sortable: true },
            columns: boundsColumnModelColumns
        });

        return boundsColumnModel;
    }

    function actionBoundsEditor(id_role, action, values, callback) {
        if (!values) {
            values = [];
        }

        Ext.Ajax.request({
            url: '/role/action_info',
            params: { action: action, current_bounds: JSON.stringify(values) },
            success: function(response) {
                Baseliner.hideLoadingMask( rolePanel.getEl() );
                var text = response.responseText;
                var data = JSON.parse(text);

                var bounds = data.info.bounds;
                if (!bounds || !bounds.length) {
                    return;
                }

                var values = data.info.values;

                var boundsStore = buildBoundsStore(bounds, values);

                var boundsSearch = new Baseliner.SearchSimple({
                    width: 220,
                    handler: function() {
                        var query = this.getRawValue();
                        if (!query || !query.length) {
                            this.el.dom.value = '';
                            boundsStore.clearFilter();
                            return;
                        }
                        var queries = query.split(/\s+/).map(function(word) {
                            return new RegExp(word, 'i')
                        });
                        boundsStore.filterBy(function(rec) {
                            var matched = 0;
                            for (var i = 0; i < queries.length; i++) {
                                var values = [];
                                for (var j = 0; j < bounds.length; j++) {
                                    values.push(rec.data[bounds[j].key]);
                                }

                                if (queries[i].test(values.join(';'))) {
                                    matched++;
                                }
                            }
                            return matched == queries.length;
                        });
                    }
                });

                var boundsSelectionFormPanel = new Ext.form.FormPanel({
                    height: 185,
                    frame: true,
                    width: '100%',
                    defaults: {
                        msgTarget: 'under'
                    },
                    bodyCssClass: 'x-bounds-form',
                    items: buildAddBoundFormItems(action, bounds, boundsStore)
                });

                var win = new Ext.Window({
                    title: _('Role Bounds') +' : '+ action,
                    width: 730,
                    height: 500,
                    closeAction: 'close',
                    layout: 'border',
                    bodyBorder: false,
                    modal: true,
                    bodyCssClass: 'x-bounds-window-body',
                    bwrapCssClass: 'x-bounds-window-bwrap',
                    tbar: ['->', {
                        icon: IC('save'),
                        iconCls: 'x-btn-text-icon',
                        text: _('Save'),
                        handler: function() {
                            if (callback) {
                                var values = [];
                                boundsStore.clearFilter();
                                boundsStore.each(function(record) {
                                    values.push(record.data);
                                });

                                callback(values.length ? values : '');
                            }
                            win.close();
                            Baseliner.message(_('Success'), _('Action bounds saved'));
                        }
                    }, {
                        icon: IC('close'),
                        iconCls: 'x-btn-text-icon',
                        text: _('Close'),
                        handler: function() {
                            if (boundsSelectionFormPanel.getForm().isDirty()) {
                                Ext.Msg.confirm(_('Confirmation'), _('Are you sure you want to close the window?'),
                                    function(btn) {
                                        if (btn == 'yes') {
                                            win.close();
                                        }
                                    });
                            }
                            else {
                                win.close();
                            }
                        }
                    }],
                    items: [{
                        region: 'north',
                        layout: 'fit',
                        split: true,
                        height: 200,
                        title: _('Bounds Selection'),
                        items: boundsSelectionFormPanel
                    }, {
                        region: 'center',
                        layout: 'fit',
                        split: true,
                        items: new Ext.grid.GridPanel({
                            title: _('Bounds'),
                            autoScroll: true,
                            region: 'center',
                            layout: 'fit',
                            store: boundsStore,
                            split: true,
                            stripeRows: true,
                            viewConfig: {
                                forceFit: true
                            },
                            cm: buildBoundsColumnModel(bounds, values),
                            sm: new Baseliner.RowSelectionModel({
                                singleSelect: false
                            }),
                            tbar: [
                                boundsSearch, '->',
                                new Ext.Toolbar.Button({
                                    text: _('Remove Selection'),
                                    icon: '/static/images/icons/delete_red.svg',
                                    cls: 'x-btn-text-icon',
                                    handler: function() {
                                        var gridPanel = this.findParentByType(Ext.grid.GridPanel);

                                        var sm = gridPanel.getSelectionModel();
                                        if (sm.hasSelection()) {
                                            var selections = sm.getSelections();
                                            for (var i = 0; i < selections.length; i++) {
                                                boundsStore.remove(selections[i]);
                                            }
                                        }
                                    }
                                }),
                                new Ext.Toolbar.Button({
                                    text: _('Remove All'),
                                    icon: '/static/images/icons/del_all.svg',
                                    cls: 'x-btn-text-icon',
                                    handler: function() {
                                        boundsStore.removeAll();
                                    }
                                })
                            ]
                        })
                    }]
                });

                win.show();
            },
            failure: function() {
            }
        });
    }

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
        ],
        listeners: {
            rowdblclick: function(comp, rowIndex, e) {
                var sel = roleGridPanel.getSelectionModel().getSelected();

                if (sel.data.bounds_available) {
                    Baseliner.showLoadingMask(rolePanel.getEl());
                    var values = roleGridPanel.getStore().getAt(rowIndex).get('bounds');
                    actionBoundsEditor(params.id_role, sel.data.action, values, function(values) {
                        var row = roleGridPanel.getStore().getAt(rowIndex);
                        row.set("bounds", values);
                    });
                }
            }
        }
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

                var boundsAvailable = n.attributes.bounds_available;

                var found;
                action_store.each(function(record) {
                    if (record.data.action === n.id) {
                        found = record;
                    }
                });

                if (found) {
                    actionBoundsEditor(params.id_role, n.id, found.data.bounds, function(values) {
                        found.set("bounds", values);
                    });
                    return true;
                }

                var add_node = function(node) {
                    var rec = new Ext.data.Record({
                        action: node.id,
                        description: node.text,
                        bounds_available: boundsAvailable
                    });
                    action_store.add(rec);
                    tree_check_folder_enabled(node.parentNode);

                    return rec;
                };

                if (n.leaf) {
                    if (boundsAvailable) {
                        actionBoundsEditor(params.id_role, n.id, [], function(values) {
                            var rec = add_node(n);
                            rec.set("bounds", values);
                        });
                    }
                    else {
                        add_node(n);
                    }
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
        tab_icon: IC('role'),
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
                                grid.getStore().reload();
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
                icon: IC('close'),
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
