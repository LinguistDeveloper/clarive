define(
    [
        '/static/widget/user_roles_and_projects.js',
        '/static/widget/user_assigned_roles_and_projects.js',
    ],
    function(rolesAndProjectsWidget, assignedRolesAndProjectsWidget) {
        Ext.form.Action.prototype.constructor = Ext.form.Action.prototype.constructor.createSequence(function() {
            Ext.applyIf(this.options, {
                submitEmptyText: false
            });
        });

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
                            formPanel.fireEvent('usergroupsaved', a.result.user_id);

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

            var userBox = Baseliner.ci_box({
                name: 'users',
                fieldLabel: _('Users'),
                allowBlank: true,
                class: 'user',
                singleMode: false
            });

            formPanel = new Ext.FormPanel({
                url: '/usergroup/update',
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
                                        fieldLabel: _('Group'),
                                        name: 'groupname',
                                        emptyText: 'Group',
                                        allowBlank: false,
                                        xtype: 'textfield'
                                    }]
                                }]
                            },
                            userBox
                        ]
                    }, {
                        columnWidth: 0.10,
                        items: [
                            saveButton,
                            blankImage,
                            closeButton
                        ]
                    }]
                }]
            });

            return formPanel;
        }

        var addEdit = function(rec) {
            var rolesAndProjectsContainer = rolesAndProjectsWidget.build();
            var assignedRolesAndProjectsContainer = assignedRolesAndProjectsWidget.build({
                controller: 'usergroup'
            });

            var win;
            var userGroupFormPanel = buildFormPanel();
            userGroupFormPanel.on('close', function() {
                win.close()
            });
            userGroupFormPanel.on('usergroupsaved', function(id) {
                win.setUserGroupId(id)
            });

            rolesAndProjectsContainer.on('togglerolesprojects', function(action, roles, projects) {
                var userGroupId = userGroupFormPanel.getForm().findField("id").getValue();

                Baseliner.ajaxEval('/usergroup/toggle_roles_projects', {
                        action: action,
                        id: userGroupId,
                        roles_checked: roles,
                        projects_checked: projects
                    },
                    function(response) {
                        if (response.success) {
                            assignedRolesAndProjectsContainer.loadFor(userGroupId);

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
                var userGroupId = userGroupFormPanel.getForm().findField("id").getValue();
                Baseliner.ajaxEval('/usergroup/delete_roles', {
                        id: userGroupId,
                        roles_checked: roles
                    },
                    function(response) {
                        if (response.success) {
                            assignedRolesAndProjectsContainer.loadFor(userGroupId);

                            Baseliner.message(_('Success'), response.msg);
                        } else {
                            Baseliner.message(_('ERROR'), response.msg);
                        }
                    }
                );
            });

            win = new Ext.Window({
                title: _('Create user group'),
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
                    height: 100,
                    layout: 'fit',
                    items: [
                        userGroupFormPanel
                    ]
                }, {
                    region: 'center',
                    layout: 'border',
                    items: [
                        rolesAndProjectsContainer,
                        assignedRolesAndProjectsContainer
                    ]
                }],
                setUserGroupId: function(userGroupId) {
                    var form = userGroupFormPanel.getForm();
                    form.findField("id").setValue(userGroupId);

                    rolesAndProjectsContainer.enable();
                    rolesAndProjectsContainer.show();

                    assignedRolesAndProjectsContainer.loadFor(userGroupId);
                    assignedRolesAndProjectsContainer.showBBar();
                    assignedRolesAndProjectsContainer.enable();
                    assignedRolesAndProjectsContainer.show();

                    this.setTitle(_('Edit user group'));
                    this.doLayout();
                },
                loadUserGroup: function(record) {
                    userGroupFormPanel.getForm().loadRecord(record);

                    this.setUserGroupId(record.data.id);
                }
            });

            win.show();

            if (rec) {
                win.loadUserGroup(rec);
            }

            win.doLayout();
        };

        return {
            show: function(rec) {
                addEdit(rec);
            }
        };
    });
