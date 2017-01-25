define(function() {
    var projectsRenderer = function(value) {
        var str = '';

        if (Ext.isEmpty(value) || !Ext.isArray(value)) {
            return str;
        }

        Ext.each(value, function(val) {
            str += String.format('{0} <br>', val.name ? val.name : _('All'));
        });

        return str;
    };

    var roleRenderer = function(value, metadata, rec_grid, rowIndex, colIndex, store) {
        if (value == undefined || value == 'null' || value == '') return '';
        var script = String.format('javascript:Baseliner.user_actions({ username: \"{0}\", id_role: \"{1}\"})',
            rec_grid.data.username, rec_grid.data.id_role);
        return String.format("<a href='{0}'>{1}</a>", script, value);
    };

    Ext.apply(Ext.form.VTypes, {
        password: function(val, field) {
            if (field.initialPassField) {
                return val == pExt.getCmp(field.initialPassField).getValue();
            }
            return true;
        },
        passwordText: _('Passwords do not match')
    });

    Ext.form.Action.prototype.constructor = Ext.form.Action.prototype.constructor.createSequence(function() {
        Ext.applyIf(this.options, {
            submitEmptyText: false
        });
    });

    function buildRolesAndProjectContainer(userId, callback) {
        var rolesSelectionModel = new Ext.grid.CheckboxSelectionModel({
            singleSelect: false,
            sortable: false,
            checkOnly: true
        });

        var rolesStore = new Baseliner.JsonStore({
            root: 'data',
            remoteSort: true,
            totalProperty: "totalCount",
            autoLoad: true,
            id: 'id',
            url: '/role/json',
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

        var rolesGrid = new Ext.grid.GridPanel({
            title: _('Available Roles'),
            sm: rolesSelectionModel,
            store: rolesStore,
            stripeRows: true,
            autoScroll: true,
            autoWidth: true,
            autoSizeColumns: true,
            viewConfig: {
                forceFit: true
            },
            loadMask: true,
            columns: [
                rolesSelectionModel, {
                    hidden: true,
                    dataIndex: 'id'
                }, {
                    header: _('All'),
                    width: 250,
                    dataIndex: 'role',
                    sortable: true
                }
            ],
            getCheckedRoles: function() {
                var rolesChecked = [];

                rolesSelectionModel.each(function(rec) {
                    rolesChecked.push(rec.get('id'));
                });

                return rolesChecked;
            }
        });

        rolesGrid.on('rowclick', function(grid, rowIndex, columnIndex, e) {
            toggleButtons();
        });

        var treeRoot = new Ext.tree.AsyncTreeNode({
            text: _('All'),
            draggable: false,
            checked: false,
            id: 'All',
            iconCls: 'default_folders',
            data: {
                project: '',
                id_project: 'todos',
                parent_checked: ''
            }
        });

        var projectsTree = new Ext.tree.TreePanel({
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
            rootVisible: true,
            preloadChildren: true,
            root: treeRoot,
            getCheckedProjects: function() {
                var projectsChecked = [];

                Ext.each(projectsTree.getChecked(), function(node) {
                    if (node.attributes.leaf) {
                        projectsChecked.push(node.attributes.data.id_project);
                    } else {
                        if (node.childNodes.length > 0 || node.attributes.data.id_project == 'todos') {
                            projectsChecked.push(node.attributes.data.id_project);
                        }
                    }
                });

                return projectsChecked;
            }
        });

        projectsTree.getLoader().on("beforeload", function(treeLoader, node) {
            var loader = projectsTree.getLoader();
            loader.baseParams = node.attributes.data;
            loader.dataUrl = window.location.origin + "/" + projectsTree.dataUrl;
            node.attributes.data.parent_checked = (node.attributes.checked) ? 1 : 0;
        });

        projectsTree.on('checkchange', function(node, checked) {
            if (node != treeRoot) {
                if (node.attributes.checked == false) {
                    treeRoot.attributes.checked = false;
                    treeRoot.getUI().checkbox.checked = false;
                }
            }
            node.eachChild(function(n) {
                n.getUI().toggleCheck(checked);
            });

            toggleButtons();
        });

        function toggleRolesAndProjects(action, rolesChecked, projectsChecked) {
            Baseliner.ajaxEval('/user/toggle_roles_projects', {
                    action: action,
                    id: userId,
                    projects_checked: projectsChecked,
                    roles_checked: rolesChecked
                },
                function(response) {
                    if (response.success) {
                        callback();

                        Baseliner.message(_('Success'), response.msg);
                    } else {
                        Ext.Msg.show({
                            title: _('Information'),
                            msg: response.msg,
                            buttons: Ext.Msg.OK,
                            icon: Ext.Msg.INFO
                        });
                    }
                }
            );
        }

        var assignRolesAndProjectsButton = new Ext.Toolbar.Button({
            text: _('Assign roles/projects'),
            icon: '/static/images/icons/key_add.svg',
            cls: 'x-btn-text-icon ui-comp-users-edit-window-assign-roles',
            disabled: true,
            handler: function() {
                var rolesChecked = rolesGrid.getCheckedRoles();
                var projectsChecked = projectsTree.getCheckedProjects();

                toggleRolesAndProjects('assign', rolesChecked, projectsChecked);
            }
        });

        var unassignRolesAndProjectsButton = new Ext.Toolbar.Button({
            text: _('Unassign roles/projects'),
            icon: '/static/images/icons/key_delete.svg',
            cls: 'x-btn-text-icon ui-comp-users-unassign-roles',
            disabled: true,
            handler: function() {
                var rolesChecked = rolesGrid.getCheckedRoles();
                var projectsChecked = projectsTree.getCheckedProjects();

                toggleRolesAndProjects('unassign', rolesChecked, projectsChecked);
            }
        });

        function toggleButtons() {
            var rolesSelected = rolesSelectionModel.getCount();
            var projectsSelected = projectsTree.getChecked().length;

            if (rolesSelected && projectsSelected) {
                unassignRolesAndProjectsButton.enable()
                assignRolesAndProjectsButton.enable();
            } else {
                unassignRolesAndProjectsButton.disable();
                assignRolesAndProjectsButton.disable();
            }
        }

        var rolesAndProjectsContainer = new Ext.Container({
            height: 180,
            split: true,
            region: 'north',
            layout: 'fit',
            items: [{
                layout: 'hbox',
                layoutConfig: {
                    align: 'stretch'
                },
                items: [{
                    layout: 'fit',
                    flex: 1,
                    items: rolesGrid
                }, {
                    layout: 'fit',
                    flex: 1,
                    items: projectsTree
                }],
                bbar: [
                    assignRolesAndProjectsButton,
                    unassignRolesAndProjectsButton
                ]
            }]
        });

        return rolesAndProjectsContainer;
    }

    function buildAssignedRolesAndProjectsContainer(userId, userName) {
        var assignedRolesAndProjectsStore = new Baseliner.JsonStore({
            root: 'data',
            remoteSort: true,
            totalProperty: "totalCount",
            id: 'id_role',
            url: '/user/infodetail',
            fields: [{
                name: 'id_role'
            }, {
                name: 'role'
            }, {
                name: 'description'
            }, {
                name: 'projects'
            }]
        });

        if (userName) {
            assignedRolesAndProjectsStore.load({
                params: {
                    username: userName
                }
            });
        }

        var deleteRowButton = new Ext.Toolbar.Button({
            text: _('Delete row'),
            icon: '/static/images/icons/delete_red.svg',
            cls: 'x-btn-text-icon',
            disabled: true,
            handler: function() {
                var sm = assignedRolesAndProjectsGrid.getSelectionModel();
                if (sm.hasSelection()) {
                    var row = sm.getSelected();
                    Ext.Msg.confirm(_('Confirmation'), _('Are you sure you want to delete the row selected?'),
                        function(btn) {
                            if (btn == 'yes') {
                                var id_role = row.data.id_role;
                                Baseliner.ajaxEval('/user/delete_roles', {
                                        id: userId,
                                        roles_checked: id_role
                                    },
                                    function(response) {
                                        if (response.success) {
                                            assignedRolesAndProjectsGrid.loadFor(userName);

                                            deleteRowButton.disable();

                                            Baseliner.message(_('Success'), response.msg);
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

        var deleteAllButton = new Ext.Toolbar.Button({
            text: _('Delete All'),
            icon: '/static/images/icons/del_all.svg',
            cls: 'x-btn-text-icon',
            handler: function() {
                var roles = assignedRolesAndProjectsGrid.getAllRoles();

                if (!roles.length) {
                    return false;
                }

                Ext.Msg.confirm(_('Confirmation'), _('Are you sure you want to delete the row selected?'), function(btn) {
                    if (btn == 'yes') {
                        Baseliner.ajaxEval('/user/delete_roles', {
                                id: userId,
                                roles_checked: roles
                            },
                            function(response) {
                                if (response.success) {
                                    assignedRolesAndProjectsGrid.loadFor(userName);

                                    Baseliner.message(_('Success'), response.msg);
                                } else {
                                    Baseliner.message(_('ERROR'), response.msg);
                                }
                            }
                        );
                    }
                });
            }
        });

        var assignedRolesAndProjectsGrid = new Ext.grid.GridPanel({
            title: _('Roles/Projects User'),
            stripeRows: true,
            autoScroll: true,
            store: assignedRolesAndProjectsStore,
            stripeRows: true,
            selModel: new Ext.grid.RowSelectionModel({
                singleSelect: true
            }),
            loadMask: true,
            cls: 'user_grid_edit_window',
            columns: [{
                header: _('Role'),
                width: 120,
                dataIndex: 'role',
                sortable: true,
                renderer: roleRenderer
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
                renderer: projectsRenderer
            }],
            autoSizeColumns: true,
            boxMinHeight: 150,
            bbar: [
                deleteRowButton,
                deleteAllButton
            ],
            getAllRoles: function() {
                var roles = [];
                assignedRolesAndProjectsStore.getRange().forEach(function(rec) {
                    roles.push(rec.id);
                });

                return roles;
            },
            loadFor: function(username) {
                assignedRolesAndProjectsStore.load({
                    params: {
                        username: username
                    }
                });
            }
        });

        assignedRolesAndProjectsGrid.on('cellclick', function(grid, rowIndex, columnIndex, e) {
            if (columnIndex == 1) {
                deleteRowButton.enable();
            }
        });

        return new Ext.Container({
            xtype: 'container',
            split: true,
            layout: 'fit',
            region: 'center',
            items: [
                assignedRolesAndProjectsGrid
            ],
            hideBBar: function() {
                deleteRowButton.hide();
                deleteAllButton.hide();
            },
            showBBar: function() {
                deleteRowButton.show();
                deleteAllButton.show();
            },
            reload: function() {
                assignedRolesAndProjectsStore.load({
                    params: {
                        username: userName
                    }
                });
            }
        });
    }

    var addEdit = function(rec) {
        var userId = -1;
        var username = '';

        if (rec) {
            userId = rec.get('id');
            username = rec.get('username');
        }

        var win;

        var closeButton = new Ext.Toolbar.Button({
            text: _('Close'),
            icon: '/static/images/icons/close.svg',
            cls: 'ui-comp-users-edit-window-close',
            width: 70,
            handler: function() {
                win.close();
            }
        })

        var saveButton = new Ext.Toolbar.Button({
            text: _('Save'),
            icon: '/static/images/icons/save.svg',
            width: 70,
            handler: function() {
                var form = userForm.getForm();
                var action = form.getValues()['id'] != '-1' ? 'update' : 'add';

                if (!form.isValid()) {
                    return false;
                }

                form.submit({
                    params: {
                        action: action,
                        type: 'user'
                    },
                    success: function(f, a) {
                        userForm.loadUserId(a.result.user_id);

                        if (userGroupBox.items.items.length) {
                            rolesAndProjectsContainer.hide();
                            assignedRolesAndProjectsContainer.hideBBar();
                        } else {
                            rolesAndProjectsContainer.enable();
                            rolesAndProjectsContainer.show();
                            assignedRolesAndProjectsContainer.showBBar();
                        }

                        assignedRolesAndProjectsContainer.enable();
                        assignedRolesAndProjectsContainer.show();

                        win.setTitle(_('Edit user'));
                        win.doLayout();

                        Baseliner.message(_('Success'), a.result.msg);
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
        });

        var blankImage = new Ext.BoxComponent({
            autoEl: {
                tag: 'img',
                src: Ext.BLANK_IMAGE_URL
            },
            height: 10
        });

        var userGroupBox = Baseliner.ci_box({
            name: 'groups',
            fieldLabel: _('Groups'),
            allowBlank: true,
            class: 'UserGroup',
            singleMode: false,
            force_set_value: true
        });

        var userForm = new Ext.FormPanel({
            name: userForm,
            url: '/user/update',
            frame: true,
            cls: 'user_grid_edit_window_padding',
            layout: 'fit',
            items: [{
                    layout: 'column',
                    defaults: {
                        layout: 'form',
                        border: false,
                        xtype: 'panel',
                        bodyStyle: 'padding:0 18px 0 0'
                    },
                    items: [{
                        columnWidth: 0.90,
                        items: [{
                                xtype: 'hidden',
                                name: 'id',
                                value: -1
                            }, {
                                layout: 'column',
                                defaults: {
                                    columnWidth: 0.5,
                                    layout: 'form',
                                    border: false,
                                    xtype: 'panel',
                                    bodyStyle: 'padding:0 18px 0 0'
                                },
                                items: [{
                                    defaults: {
                                        anchor: '100%'
                                    },
                                    items: [{
                                        fieldLabel: _('User'),
                                        name: 'username',
                                        emptyText: 'User',
                                        allowBlank: false,
                                        xtype: 'textfield'
                                    }]
                                }, {
                                    defaults: {
                                        anchor: '100%'
                                    },
                                    items: [
                                        new Ext.form.ComboBox({
                                            name: 'account_type',
                                            hiddenName: 'account_type',
                                            fieldLabel: _('Account Type'),
                                            editable: false,
                                            typeAhead: true,
                                            triggerAction: 'all',
                                            lazyRender: true,
                                            mode: 'local',
                                            allowBlank: false,
                                            value: 'regular',
                                            store: new Ext.data.ArrayStore({
                                                id: 0,
                                                fields: ['accountType', 'displayText'],
                                                data: [
                                                    ['regular', _('Regular')],
                                                    ['system', _('System')]
                                                ]
                                            }),
                                            valueField: 'accountType',
                                            displayField: 'displayText'
                                        })
                                    ]
                                }]
                            }, {
                                layout: 'column',
                                defaults: {
                                    columnWidth: 0.5,
                                    layout: 'form',
                                    border: false,
                                    xtype: 'panel',
                                    bodyStyle: 'padding:0 18px 0 0'
                                },
                                items: [{
                                    defaults: {
                                        anchor: '100%'
                                    },
                                    items: [{
                                        fieldLabel: _('Password'),
                                        name: 'pass',
                                        id: 'pass',
                                        emptyText: '********',
                                        xtype: 'textfield',
                                        inputType: 'password'
                                    }, ]
                                }, {
                                    defaults: {
                                        anchor: '100%'
                                    },
                                    items: [{
                                        fieldLabel: _('Confirm Password'),
                                        name: 'pass_cfrm',
                                        emptyText: '********',
                                        inputType: 'password',
                                        vtype: 'password',
                                        initialPassField: 'pass',
                                        xtype: 'textfield'
                                    }]
                                }]
                            }, {
                                anchor: '97%',
                                fieldLabel: _('Name'),
                                name: 'realname',
                                emptyText: 'Full name',
                                xtype: 'textfield'
                            }, {
                                fieldLabel: _('Alias'),
                                name: 'alias',
                                emptyText: 'Alias',
                                xtype: 'textfield'
                            }, {
                                layout: 'column',
                                defaults: {
                                    columnWidth: 0.5,
                                    layout: 'form',
                                    border: false,
                                    xtype: 'panel',
                                    bodyStyle: 'padding:0 18px 0 0'
                                },
                                items: [{
                                    defaults: {
                                        anchor: '100%'
                                    },
                                    items: []
                                }, {
                                    defaults: {
                                        anchor: '100%'
                                    },
                                    items: [{
                                        fieldLabel: _('Phone Number'),
                                        name: 'phone',
                                        emptyText: 'xx-xxx-xx-xx',
                                        xtype: 'textfield'
                                    }]
                                }]
                            }, {
                                anchor: '97%',
                                fieldLabel: _('Email address'),
                                name: 'email',
                                emptyText: 'usuario@dominio.com',
                                vtype: 'email',
                                xtype: 'textfield'
                            },
                            userGroupBox
                        ]
                    }, {
                        columnWidth: 0.10,
                        items: [
                            saveButton,
                            blankImage,
                            closeButton
                        ]
                    }]
                }
            ],
            loadUserId: function(id) {
                var form = this.getForm();

                form.findField("id").setValue(id);
                //form.findField("username").disable();
            },
            loadUser: function(rec) {
                var form = this.getForm();

                form.loadRecord(rec);

                this.loadUserId(rec.data.id);
            }
        });

        var rolesAndProjectsContainer = buildRolesAndProjectContainer(userId, function() {
            assignedRolesAndProjectsContainer.reload();
        });
        var assignedRolesAndProjectsContainer = buildAssignedRolesAndProjectsContainer(userId, username);

        var title = _('Create user');

        if (rec) {
            userForm.loadUser(rec);

            title = _('Edit user');

            if (rec.get('groups') && rec.get('groups').length > 0) {
                rolesAndProjectsContainer.hide();
                assignedRolesAndProjectsContainer.hideBBar();
            }
        } else {
            rolesAndProjectsContainer.disable();
            assignedRolesAndProjectsContainer.disable();
        }

        win = new Ext.Window({
            title: title,
            width: 720,
            height: 700,
            minHeight: 700,
            minWidth: 720,
            resizable: true,
            maximizable: true,
            closeAction: 'close',
            modal: false,
            layout: 'border',
            items: [{
                region: 'north',
                height: 250,
                layout: 'fit',
                items: [
                    userForm
                ]
            }, {
                region: 'center',
                layout: 'border',
                items: [
                    rolesAndProjectsContainer,
                    assignedRolesAndProjectsContainer
                ]
            }]
        });

        win.show();
    };

    return {
        show: function(rec) {
            addEdit(rec);
        }
    };
});
