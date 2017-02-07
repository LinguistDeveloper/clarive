define(
    [
        '/static/widget/user_roles_and_projects.js',
        '/static/widget/user_assigned_roles_and_projects.js',
    ],
    function(rolesAndProjectsWidget, assignedRolesAndProjectsWidget) {
        function buildFormPanel() {
            var blankImage = new Ext.BoxComponent({
                autoEl: {
                    tag: 'img',
                    src: Ext.BLANK_IMAGE_URL
                },
                height: 10
            });

            var formPanel;

            var closeButton = new Ext.Toolbar.Button({
                text: _('Close'),
                icon: '/static/images/icons/close.svg',
                cls: 'ui-comp-users-edit-window-close',
                width: 70,
                handler: function() {
                    formPanel.fireEvent('close');
                }
            });

            var saveButton = new Ext.Toolbar.Button({
                text: _('Save'),
                icon: '/static/images/icons/save.svg',
                width: 70,
                handler: function() {
                    var form = formPanel.getForm();

                    if (!form.isValid()) {
                        return false;
                    }

                    form.submit({
                        success: function(f, a) {
                            formPanel.fireEvent('usersaved', a.result.user_id);

                            Baseliner.message(_('Success'), a.result.msg);
                        },
                        failure: function(f, action) {
                            if (action.result && action.result.errors) {
                                return;
                            }

                            Ext.Msg.show({
                                title: _('Information'),
                                msg: action.result.msg,
                                buttons: Ext.Msg.OK,
                                icon: Ext.Msg.INFO
                            });
                        }
                    });
                }
            });

            var userGroupBox = Baseliner.ci_box({
                name: 'groups',
                fieldLabel: _('Groups'),
                allowBlank: true,
                class: 'UserGroup',
                singleMode: false,
                force_set_value: true
            });

            formPanel = new Ext.FormPanel({
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
                                name: 'id'
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
                                        xtype: 'textfield',
                                        fieldLabel: _('Password'),
                                        name: 'pass',
                                        inputType: 'password'
                                    }, ]
                                }, {
                                    defaults: {
                                        anchor: '100%'
                                    },
                                    items: [{
                                        xtype: 'textfield',
                                        fieldLabel: _('Confirm Password'),
                                        name: 'pass_cfrm',
                                        inputType: 'password',
                                        validator: function(value) {
                                            var password = formPanel.getForm().findField('pass').getValue();

                                            if (password == value) {
                                                return true;
                                            }

                                            return 'Password do not match';
                                        }
                                    }]
                                }]
                            }, {
                                anchor: '97%',
                                fieldLabel: _('Name'),
                                name: 'realname',
                                xtype: 'textfield'
                            }, {
                                fieldLabel: _('Alias'),
                                name: 'alias',
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
                                        xtype: 'textfield'
                                    }]
                                }]
                            }, {
                                anchor: '97%',
                                fieldLabel: _('Email address'),
                                name: 'email',
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
                }],
                userGroupMode: function() {
                    return userGroupBox.items.items.length ? true : false;
                }
            });

            return formPanel;
        }

        var addEdit = function(rec) {
            var rolesAndProjectsContainer = rolesAndProjectsWidget.build();
            var assignedRolesAndProjectsContainer = assignedRolesAndProjectsWidget.build({
                controller: 'user'
            });

            var win;
            var userFormPanel = buildFormPanel();
            userFormPanel.on('close', function() {
                win.close()
            });
            userFormPanel.on('usersaved', function(id) {
                win.setUserId(id)

                if (listeners['save']) {
                    listeners['save']();
                }
            });

            rolesAndProjectsContainer.on('togglerolesprojects', function(action, roles, projects) {
                var userId = userFormPanel.getForm().findField("id").getValue();

                Baseliner.ajaxEval('/user/toggle_roles_projects', {
                        action: action,
                        id: userId,
                        roles_checked: roles,
                        projects_checked: projects
                    },
                    function(response) {
                        if (response.success) {
                            assignedRolesAndProjectsContainer.loadFor(userId);

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
            });

            assignedRolesAndProjectsContainer.on('deleteroles', function(roles) {
                var userId = userFormPanel.getForm().findField("id").getValue();
                Baseliner.ajaxEval('/user/delete_roles', {
                        id: userId,
                        roles_checked: roles
                    },
                    function(response) {
                        if (response.success) {
                            assignedRolesAndProjectsContainer.loadFor(userId);

                            Baseliner.message(_('Success'), response.msg);
                        } else {
                            Baseliner.message(_('ERROR'), response.msg);
                        }
                    }
                );
            });

            win = new Ext.Window({
                title: _('Create user'),
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
                    height: 260,
                    layout: 'fit',
                    items: [
                        userFormPanel
                    ]
                }, {
                    region: 'center',
                    layout: 'border',
                    items: [
                        rolesAndProjectsContainer,
                        assignedRolesAndProjectsContainer
                    ]
                }],
                setUserId: function(userId) {
                    var form = userFormPanel.getForm();
                    form.findField("id").setValue(userId);

                    assignedRolesAndProjectsContainer.loadFor(userId);

                    if (userFormPanel.userGroupMode()) {
                        rolesAndProjectsContainer.hide();
                        assignedRolesAndProjectsContainer.hideBBar();
                    } else {
                        rolesAndProjectsContainer.enableAll();
                        rolesAndProjectsContainer.show();
                        assignedRolesAndProjectsContainer.showBBar();
                    }

                    assignedRolesAndProjectsContainer.enableAll();
                    assignedRolesAndProjectsContainer.show();

                    this.setTitle(_('Edit user'));
                    this.doLayout();
                },
                loadUser: function(record) {
                    userFormPanel.getForm().loadRecord(record);

                    this.setUserId(record.data.id);

                    if (record.get('groups') && record.get('groups').length > 0) {
                        rolesAndProjectsContainer.hide();
                        assignedRolesAndProjectsContainer.hideBBar();
                    }
                }
            });

            win.show();

            if (rec) {
                win.loadUser(rec);
            }

            win.doLayout();
        };

        var listeners = {};
        return {
            on: function(ev, callback) {
                listeners[ev] = callback;
            },
            show: function(rec) {
                addEdit(rec);
            }
        };
    });
