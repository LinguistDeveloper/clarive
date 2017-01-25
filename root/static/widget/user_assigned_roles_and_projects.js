define(function() {
    var projectsRenderer = function(value) {
        var str = '';

        if (Ext.isEmpty(value) || !Ext.isArray(value)) {
            return str;
        }

        Ext.each(value, function(val) {
            var name = val.name ? val.name : _('All');

            if (val.icon) {
                name = '<img style="vertical-align:middle;" src="' + val.icon + '"/> ' + name;
            }

            str += String.format('{0} <br>', name);
        });

        return str;
    };

    var roleRenderer = function(value, metadata, rec_grid, rowIndex, colIndex, store) {
        if (value == undefined || value == 'null' || value == '') return '';
        var script = String.format('javascript:Baseliner.user_actions({ username: \"{0}\", id_role: \"{1}\"})',
            rec_grid.data.username, rec_grid.data.id_role);
        return String.format("<a href='{0}'>{1}</a>", script, value);
    };

    function build(opts) {
        var controller = opts.controller;

        var assignedRolesAndProjectsStore = new Baseliner.JsonStore({
            root: 'data',
            remoteSort: true,
            totalProperty: "totalCount",
            id: 'id_role',
            url: '/' + controller + '/roles_projects',
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

        var deleteRowButton = new Ext.Toolbar.Button({
            text: _('Delete row'),
            icon: '/static/images/icons/delete_red.svg',
            cls: 'x-btn-text-icon',
            disabled: true,
            handler: function() {
                var sm = assignedRolesAndProjectsGrid.getSelectionModel();
                if (sm.hasSelection()) {
                    var row = sm.getSelected();
                    var idRole = row.data.id_role;

                    Ext.Msg.confirm(_('Confirmation'), _('Are you sure you want to delete the row selected?'),
                        function(btn) {
                            if (btn == 'yes') {
                                assignedRolesAndProjectsContainer.fireEvent('deleteroles', [idRole]);
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
                        assignedRolesAndProjectsContainer.fireEvent('deleteroles', roles);
                    }
                });
            }
        });

        var assignedRolesAndProjectsGrid = new Ext.grid.GridPanel({
            title: _('Roles/Projects'),
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
            loadFor: function(userId) {
                if (!userId || userId == -1) {
                    return false;
                }

                assignedRolesAndProjectsStore.load({
                    params: {
                        id: userId
                    }
                });
            }
        });

        assignedRolesAndProjectsGrid.on('cellclick', function(grid, rowIndex, columnIndex, e) {
            if (columnIndex == 1) {
                deleteRowButton.enable();
            }
        });

        var assignedRolesAndProjectsContainer = new Ext.Container({
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
            loadFor: function(userId) {
                assignedRolesAndProjectsGrid.loadFor(userId);
            }
        });

        return assignedRolesAndProjectsContainer;
    }

    return {
        build: build
    };
});
