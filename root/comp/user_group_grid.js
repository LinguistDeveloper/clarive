(function(params) {
    if (!params) params = {};
    if (!params.tbar) params.tbar = {};

    Cla.help_push({ title:_('User Group Administration'), path:'admin/user_group' });

    var store = new Baseliner.JsonStore({
        root: 'data',
        remoteSort: true,
        totalProperty: "totalCount",
        id: 'id',
        url: '/usergroup/list',
        fields: [{
            name: 'id'
        }, {
            name: 'groupname'
        }, {
            name: 'language_pref'
        }, {
            name: 'active'
        }, {
            name: 'users'
        }, {
            name: 'user_names'
        }],
        listeners: {
            'load': function() {
                if (grid.getSelectionModel().hasSelection())
                    init_buttons('enable');
                else
                    init_buttons('disable');
            }
        }
    });

    var store_roles = new Baseliner.JsonStore({
        root: 'data',
        remoteSort: true,
        totalProperty: "totalCount",
        id: 'id',
        url: '/role/json',
        baseParams: {
            'get_actions': 0
        },
        fields: [{
            name: 'id'
        }, {
            name: 'role'
        }, {
            name: 'actions'
        }, {
            name: 'description'
        }, {
            name: 'mailbox'
        }]
    });

    var ps = 100; //page_size

    var render_projects = function(val) {
        if (val == null || val == undefined) return '';
        if (typeof val != 'object') return '';
        var str = ''
        for (var i = 0; i < val.length; i++) {
            if (val[i].name) {
                str += String.format('{0} <br>', val[i].name);
            } else {
                str += String.format('{0} <br>', _("All"));
            }
        }
        return str;
    }

    var init_buttons = function(action) {
        eval('btn_edit.' + action + '()');
        eval('btn_duplicate.' + action + '()');
        eval('btn_delete.' + action + '()');
    }

    var add_edit = function(rec) {
        var win;
        //var groupname_readonly = false;

        var store_usergroup_roles_projects = new Baseliner.JsonStore({
            root: 'data',
            remoteSort: true,
            totalProperty: "totalCount",
            id: 'id_role',
            url: '/usergroup/infodetail',
            fields: [{
                name: 'id_role'
            }, {
                name: 'role'
            }, {
                name: 'description'
            }, {
                name: 'projects'
            }],
            listeners: {
                'load': function() {
                    control_buttons();
                }
            }
        });

        var btn_assign_roles_projects = new Ext.Toolbar.Button({
            text: _('Assign roles/projects'),
            icon: '/static/images/icons/key_add.svg',
            cls: 'x-btn-text-icon',
            disabled: true,
            handler: function() {
                var form = form_user_group.getForm();
                var action = 'update';
                var projects_checked = new Array();
                var projects_parents_checked = new Array();
                var roles_checked = new Array();
                check_roles_sm.each(function(rec) {
                    roles_checked.push(rec.get('id'));
                });

                selNodes = tree_projects.getChecked();
                Ext.each(selNodes, function(node) {
                    if (node.attributes.leaf) {
                        projects_checked.push(node.attributes.data.id_project);
                    } else {
                        if (node.childNodes.length > 0 || node.attributes.data.id_project ==
                            'todos') {
                            projects_checked.push(node.attributes.data.id_project);
                        } else {
                            projects_parents_checked.push(node.attributes.data.id_project);
                        }
                    }
                });

                ////////////////////////////////////////////////////////////////////

                if (form.getValues()['id'] != '-1') {
                    form.submit({
                        params: {
                            action: action,
                            type: 'roles_projects',
                            projects_checked: projects_checked,
                            projects_parents_checked: projects_parents_checked,
                            roles_checked: roles_checked
                        },
                        success: function(f, a) {
                            Baseliner.message(_('Success'), a.result.msg);
                            store_usergroup_roles_projects.load({
                                params: {
                                    groupname: form.getValues()['groupname']
                                }
                            });
                            form.findField("groupname").getEl().dom.setAttribute(
                                'readOnly', true);
                        },
                        failure: function(f, a) {
                            Ext.Msg.show({
                                title: _('Information'),
                                msg: a.result.msg,
                                buttons: Ext.Msg.OK,
                                icon: Ext.Msg.INFO
                            });
                        }
                    });
                } else {
                    Ext.Msg.show({
                        title: _('Information'),
                        msg: _('You must save the user group before'),
                        buttons: Ext.Msg.OK,
                        icon: Ext.Msg.INFO
                    });
                }
            }
        })

        var btn_unassign_roles_projects = new Ext.Toolbar.Button({
            text: _('Unassign roles/projects'),
            icon: '/static/images/icons/key_delete.svg',
            cls: 'x-btn-text-icon',
            disabled: true,
            handler: function() {
                var form = form_user_group.getForm();
                var action = 'delete_roles_projects';
                var projects_checked = new Array();
                var projects_parents_checked = new Array();
                var roles_checked = new Array();
                check_roles_sm.each(function(rec) {
                    roles_checked.push(rec.get('id'));
                });

                selNodes = tree_projects.getChecked();
                Ext.each(selNodes, function(node) {
                    if (node.attributes.leaf) {
                        projects_checked.push(node.attributes.data.id_project);
                    } else {
                        if (node.childNodes.length > 0 || node.attributes.data.id_project ==
                            'todos') {
                            projects_checked.push(node.attributes.data.id_project);
                        } else {
                            projects_parents_checked.push(node.attributes.data.id_project);
                        }
                    }
                });

                ////////////////////////////////////////////////////////////////////
                if (form.getValues()['id'] != '-1') {
                    form.submit({
                        params: {
                            action: action,
                            type: 'roles_projects',
                            projects_checked: projects_checked,
                            projects_parents_checked: projects_parents_checked,
                            roles_checked: roles_checked
                        },
                        success: function(f, a) {
                            Baseliner.message(_('Success'), a.result.msg);
                            store_usergroup_roles_projects.load({
                                params: {
                                    groupname: form.getValues()['groupname']
                                }
                            });
                            form.findField("groupname").getEl().dom.setAttribute(
                                'readOnly', true);
                        },
                        failure: function(f, a) {
                            Ext.Msg.show({
                                title: _('Information'),
                                msg: a.result.msg,
                                buttons: Ext.Msg.OK,
                                icon: Ext.Msg.INFO
                            });
                        }
                    });
                } else {
                    Ext.Msg.show({
                        title: _('Information'),
                        msg: _("User doesn't exist"),
                        buttons: Ext.Msg.OK,
                        icon: Ext.Msg.INFO
                    });
                }
            }
        })

        var btn_cerrar = new Ext.Toolbar.Button({
            text: _('Close'),
            icon: '/static/images/icons/close.svg',
            width: 70,
            handler: function() {
                win.close();
            }
        })

        var btn_save_usergroup = new Ext.Toolbar.Button({
            text: _('Save'),
            icon: '/static/images/icons/save.svg',
            width: 70,
            handler: function() {
                var form = form_user_group.getForm();
                var action = form.getValues()['id'] != '-1' ? 'update' : 'add';

                if (form.isValid()) {
                    form.submit({
                        params: {
                            action: action,
                            type: 'group'
                        },
                        success: function(f, a) {
                            Baseliner.message(_('Success'), a.result.msg);
                            store.load();
                            grid.getSelectionModel().clearSelections();
                            store_usergroup_roles_projects.load({
                                params: {
                                    groupname: form.getValues()['groupname']
                                }
                            });
                            form.findField("id").setValue(a.result.user_id);
                            form.findField("groupname").getEl().dom.setAttribute(
                                'readOnly', true);
                            btn_save_usergroup.disable();
                            win.setTitle(_('Edit usergroup'));
                        },
                        failure: function(f, a) {
                            Ext.Msg.show({
                                title: _('Information'),
                                msg: a.result.msg,
                                buttons: Ext.Msg.OK,
                                icon: Ext.Msg.INFO
                            });
                        }
                    });
                }
            }
        })

        var check_roles_sm = new Ext.grid.CheckboxSelectionModel({
            singleSelect: false,
            sortable: false,
            checkOnly: true
        });

        var grid_roles = new Ext.grid.GridPanel({
            title: _('Available Roles'),
            sm: check_roles_sm,
            store: store_roles,
            stripeRows: true,
            autoScroll: true,
            autoWidth: true,
            viewConfig: {
                forceFit: true
            },
            height: 200,
            // loadMask: true,
            columns: [
                check_roles_sm, {
                    hidden: true,
                    dataIndex: 'id'
                }, {
                    header: _('All'),
                    width: 250,
                    dataIndex: 'role',
                    sortable: true
                }
            ],
            autoSizeColumns: true
        });

        grid_roles.on('rowclick', function(grid, rowIndex, columnIndex, e) {
            control_buttons();
        });

        var blank_image = new Ext.BoxComponent({
            autoEl: {
                tag: 'img',
                src: Ext.BLANK_IMAGE_URL
            },
            height: 10
        });

        var treeRoot = new Ext.tree.AsyncTreeNode({
            text: _('All'),
            draggable: false,
            checked: false,
            id: 'All',
            iconCls:'default_folders',
            data: {
                project: '',
                id_project: 'todos',
                parent_checked: ''
            }
        });

        var tree_projects = new Ext.tree.TreePanel({
            title: _('Available Projects'),
            dataUrl: "user/projects_list",
            split: true,
            colapsible: true,
            useArrows: true,
            ddGroup: 'secondGridDDGroup',
            animate: true,
            enableDrag: true,
            containerScroll: true,
            autoScroll: true,
            height: 200,
            rootVisible: true,
            preloadChildren: true,
            root: treeRoot
        });

        tree_projects.getLoader().on("beforeload", function(treeLoader, node) {
            var loader = tree_projects.getLoader();

            loader.baseParams = node.attributes.data;
            node.attributes.data.parent_checked = (node.attributes.checked) ? 1 : 0;
        });

        tree_projects.on('checkchange', function(node, checked) {
            if (node != treeRoot) {
                if (node.attributes.checked == false) {
                    treeRoot.attributes.checked = false;
                    treeRoot.getUI().checkbox.checked = false;
                }
            }
            node.eachChild(function(n) {
                n.getUI().toggleCheck(checked);
            });

            control_buttons();
        });

        //tree_projects.on('click', function(node, event){
        //  //node.getUI().toggleCheck(!node.attributes.checked);
        //  //node.attributes.data.parent_checked = (!node.attributes.checked)?1:0;
        //  //node.attributes.data.parent_checked = 1;
        //  //alert(node.attributes.data.parent_checked);
        //});

        var control_buttons = function() {
            var projects_nodes = tree_projects.getChecked().length;
            var roles_nodes = check_roles_sm.getCount();
            var rows_roles_projects = store_usergroup_roles_projects.getCount();

            if (roles_nodes < 1 && projects_nodes < 1) {
                btn_unassign_roles_projects.disable();
                btn_assign_roles_projects.disable();
            } else {
                if (projects_nodes < 1) {
                    btn_assign_roles_projects.disable();
                    rows_roles_projects < 1 ? btn_unassign_roles_projects.disable() :
                        btn_unassign_roles_projects.enable();
                } else {
                    if (roles_nodes < 1) {
                        if (rows_roles_projects < 1) {
                            btn_unassign_roles_projects.disable()
                            btn_assign_roles_projects.disable();
                        } else {
                            btn_unassign_roles_projects.enable()
                            btn_assign_roles_projects.enable();
                        }
                    } else {
                        rows_roles_projects < 1 ? btn_unassign_roles_projects.disable() :
                            btn_unassign_roles_projects.enable();
                        btn_assign_roles_projects.enable();
                    }

                }
            }
        }

        //Para cuando se envia el formulario no coja el atributo emptytext de los textfields
        Ext.form.Action.prototype.constructor = Ext.form.Action.prototype.constructor.createSequence(function() {
            Ext.applyIf(this.options, {
                submitEmptyText: false
            });
        });

        var render_rol_field = function(value, metadata, rec_grid, rowIndex, colIndex, store) {
            if (value == undefined || value == 'null' || value == '') return '';

            var script = String.format(
                'javascript:Baseliner.user_actions({ groupname: \"{0}\", id_role: \"{1}\"})', rec_grid.data
                .groupname, rec_grid.data.id_role);

            return String.format("<a href='{0}'>{1}</a>", script, value);
        };

        var btn_delete_row = new Ext.Toolbar.Button({
            text: _('Delete row'),
            icon: '/static/images/icons/delete_red.svg',
            cls: 'x-btn-text-icon',
            disabled: true,
            handler: function() {
                var sm = grid_usergroup_roles_projects.getSelectionModel();
                if (sm.hasSelection()) {
                    var row = sm.getSelected();

                    Ext.Msg.confirm(_('Confirmation'), _(
                            'Are you sure you want to delete the row selected?'),

                        function(btn) {
                            if (btn == 'yes') {
                                var form = form_user_group.getForm();
                                var id_role = row.data.id_role;
                                var groupname = form.getValues()['groupname'];
                                var groupId = form.getValues()['id'];

                                Baseliner.ajaxEval('/usergroup/update', {
                                        action: 'delete_roles_projects',
                                        roles_checked: id_role,
                                        type: 'roles_projects',
                                        groupname: groupname,
                                        id: groupId
                                    },
                                    function(response) {
                                        if (response.success) {
                                            Baseliner.message(_('Success'), response.msg);
                                            store_usergroup_roles_projects.load({
                                                params: {
                                                    groupname: groupname
                                                }
                                            });
                                            btn_delete_row.disable();
                                        } else {
                                            Baseliner.message(_('ERROR'), response.msg);
                                        }
                                    }
                                );
                            }
                        });
                }
            }
        });

        var btn_delete_all = new Ext.Toolbar.Button({
            text: _('Delete All'),
            icon: '/static/images/icons/del_all.svg',
            cls: 'x-btn-text-icon',
            // disabled: true,
            handler: function() {
                Ext.Msg.confirm(_('Confirmation'), _(
                    'Are you sure you want to delete the row selected?'), function(btn) {
                    if (btn == 'yes') {
                        var form = form_user_group.getForm();
                        var action = 'delete_roles_projects';
                        var projects_checked = new Array();
                        var projects_parents_checked = new Array();
                        var roles_checked = new Array();;
                        var groupId = form.getValues()['id'];

                        store_usergroup_roles_projects.getRange().forEach(function(rec) {
                            roles_checked.push(rec.id);
                        });

                        if (roles_checked.length > 0) {
                            Baseliner.ajaxEval('/usergroup/update', {
                                    action: 'delete_roles_projects',
                                    roles_checked: roles_checked,
                                    type: 'roles_projects',
                                    groupname: groupname,
                                    id: groupId
                                },
                                function(response) {
                                    if (response.success) {
                                        Baseliner.message(_('Success'), response.msg);
                                        store_usergroup_roles_projects.load({
                                            params: {
                                                groupname: groupname
                                            }
                                        });
                                    } else {
                                        Baseliner.message(_('ERROR'), response.msg);
                                    }
                                }
                            );
                        }
                    }
                });
            }
        })

        var grid_usergroup_roles_projects = new Ext.grid.GridPanel({
            title: _('Roles/Projects User'),
            stripeRows: true,
            autoScroll: true,
            autoWidth: true,
            store: store_usergroup_roles_projects,
            viewConfig: {
                forceFit: true
            },
            selModel: new Ext.grid.RowSelectionModel({
                singleSelect: true
            }),
            loadMask: true,
            columns: [{
                header: _('Role'),
                width: 120,
                dataIndex: 'role',
                sortable: true,
                renderer: render_rol_field
            }, {
                header: _('Description'),
                width: 350,
                dataIndex: 'description',
                sortable: true
            }, {
                header: _('Namespace'),
                width: 150,
                dataIndex: 'projects',
                sortable: false,
                renderer: render_projects
            }],
            autoSizeColumns: true,
            deferredRender: true,
            height: 200,
            bbar: [
                btn_delete_row,
                btn_delete_all
            ]
        });

        grid_usergroup_roles_projects.on('cellclick', function(grid, rowIndex, columnIndex, e) {
            if (columnIndex == 1) {
                btn_delete_row.enable();
            }
        });

        var user_box = Baseliner.ci_box({
            name: 'users',
            fieldLabel: _('Users'),
            allowBlank: true,
            class: 'user',
            singleMode: false
        });

        var form_user_group = new Ext.FormPanel({
            name: form_user_group,
            url: '/usergroup/update',
            frame: true,

            items: [{
                    layout: 'column',
                    defaults: {
                        layout: 'form',
                        border: false,
                        xtype: 'panel',
                        bodyStyle: 'padding:0 18px 0 0'
                    },
                    items: [{
                        columnWidth: 0.80,
                        items: [{
                            xtype: 'hidden',
                            name: 'id',
                            value: -1
                        }, {
                            // column layout with 2 columns
                            layout: 'column',
                            defaults: {
                                columnWidth: 0.5,
                                layout: 'form',
                                border: false,
                                xtype: 'panel',
                                bodyStyle: 'padding:0 18px 0 0'
                            },
                            items: [{
                                // left column
                                defaults: {
                                    anchor: '100%'
                                },
                                items: [{
                                    fieldLabel: _('Group'),
                                    name: 'groupname',
                                    emptyText: _('Group'),
                                    allowBlank: false,
                                    xtype: 'textfield'
                                }]
                            }]
                        }, ]
                    }, {
                        columnWidth: 0.10,
                        items: [
                            btn_save_usergroup
                        ]
                    }, {
                        columnWidth: 0.10,
                        items: [
                            btn_cerrar
                        ]
                    }]
                },
                user_box,
                blank_image, {
                    xtype: 'panel',
                    layout: 'column',
                    bbar: [
                        btn_assign_roles_projects,
                        btn_unassign_roles_projects
                    ],
                    items: [{
                        columnWidth: .49,
                        items: grid_roles
                    }, {
                        columnWidth: .02,
                        items: blank_image
                    }, {
                        columnWidth: .49,
                        items: tree_projects
                    }]
                },
                grid_usergroup_roles_projects
            ]
        });

        Ext.apply(Ext.form.VTypes, {
            password: function(val, field) {
                if (field.initialPassField) {
                    var pwd = Ext.getCmp(field.initialPassField);
                    return (val == pwd.getValue());
                }
                return true;
            },

            passwordText: _('Passwords do not match')
        });

        var groupname = '';
        var title = 'Create user';

        if (rec) {
            var ff = form_user_group.getForm();
            ff.loadRecord(rec);
            groupname = rec.get('groupname');
            title = 'Edit user';
            //groupname_readonly = true;
        }

        win = new Ext.Window({
            title: _(title),
            autoHeight: true,
            width: 730,
            closeAction: 'close',
            modal: true,
            constrain: true,
            items: [
                form_user_group
            ]
        });

        win.show();

        store_usergroup_roles_projects.load({
            params: {
                groupname: groupname
            }
        });

        store_roles.load({
            params: {
                start: 0,
                limit: ps
            }
        });
    };

    var btn_add = new Baseliner.Grid.Buttons.Add({
        handler: function() {
            add_edit();
        }
    });

    var btn_edit = new Ext.Toolbar.Button({
        text: _('Edit'),
        icon: '/static/images/icons/edit.svg',
        cls: 'x-btn-text-icon',
        disabled: true,
        handler: function() {
            var sm = grid.getSelectionModel();
            if (sm.hasSelection()) {
                var sel = sm.getSelected();
                add_edit(sel);
            } else {
                Baseliner.message(_('ERROR'), _('Select at least one row'));
            };
        }
    });

    var btn_duplicate = new Ext.Toolbar.Button({
        text: _('Duplicate'),
        icon: '/static/images/icons/copy.svg',
        cls: 'x-btn-text-icon',
        handler: function() {
            var sm = grid.getSelectionModel();
            if (sm.hasSelection()) {
                var sel = sm.getSelected();
                Baseliner.ajaxEval('/usergroup/duplicate', {
                        id_group: sel.data.id
                    },
                    function(response) {
                        if (response.success) {
                            store.reload();
                            Baseliner.message(_('Success'), response.msg);
                            init_buttons('disable');
                        } else {
                            Baseliner.message(_('ERROR'), response.msg);
                        }
                    }
                );
            } else {
                Ext.Msg.alert('Error', _('Select at least one row'));
            };
        }
    });

    var btn_delete = new Ext.Toolbar.Button({
        text: _('Delete'),
        icon: '/static/images/icons/delete.svg',
        cls: 'x-btn-text-icon',
        disabled: true,
        handler: function() {
            var sm = grid.getSelectionModel();
            var sel = sm.getSelected();
            Ext.Msg.confirm(_('Confirmation'), _('Are you sure you want to delete the user group %1',
                    ' <b>' + sel.data.groupname + '</b>?'),
                function(btn) {
                    if (btn == 'yes') {
                        Baseliner.ajaxEval('/usergroup/update?action=delete', {
                                id: sel.data.id,
                                groupname: sel.data.groupname
                            },
                            function(response) {
                                if (response.success) {
                                    grid.getStore().remove(sel);
                                    Baseliner.message(_('Success'), response.msg);
                                    init_buttons('disable');
                                } else {
                                    Baseliner.message(_('ERROR'), response.msg);
                                }
                            }
                        );
                    }
                });
        }
    });

    // create the grid
    var grid = new Ext.grid.GridPanel({
        title: _('User groups'),
        header: false,
        stripeRows: true,
        autoScroll: true,
        autoWidth: true,
        store: store,
        viewConfig: {
            forceFit: true
        },
        selModel: new Ext.grid.RowSelectionModel({
            singleSelect: true
        }),
        loadMask: 'true',
        columns: [{
            header: _('Id'),
            hidden: true,
            dataIndex: 'id'
        }, {
            header: _('Group'),
            width: 50,
            dataIndex: 'groupname',
            sortable: true
        }, {
            header: _('Users'),
            width: 130,
            dataIndex: 'user_names',
            sortable: true
        }, ],
        autoSizeColumns: true,
        deferredRender: true,
        bbar: new Ext.PagingToolbar({
            store: store,
            pageSize: ps,
            displayInfo: true,
            displayMsg: _('Rows {0} - {1} of {2}'),
            emptyMsg: _('There are no rows available')
        }),
        tbar: [_('Search') + ': ', ' ',
            new Baseliner.SearchField({
                store: store,
                params: {
                    start: 0,
                    limit: ps
                },
                emptyText: _('<Enter your search string>')
            }), ' ', ' ',


% if ($c->stash->{can_maintenance}) {
                btn_add,
                btn_edit,
                btn_delete,
                btn_duplicate,
%}
            '->'
        ]
    });

    var sm = grid.getSelectionModel();
    sm.on('rowselect', function(it, rowIndex) {
        var r = grid.getStore().getAt(rowIndex);
        var active = r.get('active');
        if (active != '0') {
            init_buttons('enable');
        } else {
            init_buttons('disable');
        }
    });
    sm.on('rowdeselect', function(grid, rowIndex) {
        init_buttons('disable');
    });

    store.load({
        params: {
            start: 0,
            limit: ps
        }
    });
    return grid;
})
