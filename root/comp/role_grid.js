(function(){
    var ps = 30;
    var fistLoad = true;
    var store = new Baseliner.JsonStore({
        root: 'data' ,
        remoteSort: true,
        totalProperty:"totalCount",
        id: 'rownum',
        url: '/role/json',
        fields: [
            {  name: 'id' },
            {  name: 'role' },
            {  name: 'actions' },
            {  name: 'invalid_actions' },
            //{  name: 'users' },
            {  name: 'description' },
            {  name: 'mailbox' }
        ]
    });
    Cla.help_push({ title:_('Roles'), path:'admin/roles' });

    //////////////// Role Create / Edit Window
    var openRoleDetail = function(id_role, role){
        Baseliner.add_tabcomp('/comp/role_detail.js', null, { id_role: id_role, role: role, id_grid: grid.getId() } );
    }

    var ptool = new Baseliner.PagingToolbar({
        store: store,
        pageSize: ps,
        listeners: {
            pagesizechanged: function(pageSize) {
                searchField.setParam('limit', pageSize);
             }
        }
    });
    var searchField = new Baseliner.SearchField({
        store: store,
        params: {start: 0, limit: ps},
        emptyText: _('<Enter your search string>')
    });

    var renderOptions = function(val, m, rd, inx) {
        var response = '<div id="boot" style="background: transparent">';
        response += String.format('<button class="btn btn-mini" type="button" \
            onclick="javascript:Ext.getCmp(\'{0}\').list_actions({1})">{2}</button>',
            grid.id, inx, _('Actions')
        );
        response += String.format(' <button class="btn btn-mini btn-danger" type="button" \
            onclick="javascript:Ext.getCmp(\'{0}\').list_actions({1},true)" style="color: #">{2}</button>',
            grid.id, inx, _('Invalid')
        );
        response += '</div>';

        return response;
    }

    // create the grid
    var grid = new Ext.grid.GridPanel({
        renderTo: 'main-panel',
        title: _('Roles'),
        header: false,
        autoScroll: true,
        store: store,
        stripeRows: true,
        viewConfig: {
            forceFit: true
        },
        selModel: new Ext.grid.RowSelectionModel({
            singleSelect: true
        }),
        columns: [{
            header: _('Role'),
            width: 200,
            dataIndex: 'role',
            sortable: true,
            renderer: function(v) {
                return '<b>' + v + '</b>'
            }
        }, {
            header: _('Description'),
            width: 200,
            dataIndex: 'description',
            sortable: true
        }, {
            header: _('Mailbox'),
            width: 200,
            dataIndex: 'mailbox',
            sortable: true,
            renderer: Baseliner.escape_lt_gt
        }, {
            header: _('Options'),
            width: 200,
            dataIndex: 'role',
            sortable: true,
            renderer: renderOptions
        }, ],
        autoSizeColumns: true,
        deferredRender: true,
        bbar: ptool,
        tbar: [_('Search') + ': ', ' ',
            searchField, ' ', ' ',
            new Ext.Toolbar.Button({
                text: _('Add'),
                icon: '/static/images/icons/add.svg',
                cls: 'x-btn-text-icon ui-comp-role-create',
                handler: function() {
                    openRoleDetail();
                }
            }),
            new Ext.Toolbar.Button({
                text: _('Edit'),
                icon: '/static/images/icons/edit.svg',
                cls: 'x-btn-text-icon',
                handler: function() {
                    var sm = grid.getSelectionModel();
                    if (sm.hasSelection()) {
                        var sel = sm.getSelected();
                        openRoleDetail(sel.data.id, sel.data.role);
                    } else {
                        Ext.Msg.alert('Error', _('Select at least one row'));
                    };
                }
            }),

            new Ext.Toolbar.Button({
                text: _('Delete'),
                icon: '/static/images/icons/delete.svg',
                cls: 'x-btn-text-icon',
                handler: function() {
                    var sm = grid.getSelectionModel();

                    var sel = undefined;
                    sel = sm.getSelected();

                    if (sel === undefined) {
                        Ext.Msg.alert('Status', _('Please, select the role to delete'));

                        return;
                    }

                    var consultRoleUser = new Ext.data.Connection();
                    consultRoleUser.request({
                        url: '/role/delete',
                        params: {
                            id_role: sel.data.id
                        },
                        success: function(resp) {
                            var info = Ext.util.JSON.decode(resp.responseText);

                            var message;

                            var roleName = sel.json.role.bold();
                            var roleUsers = info.users;
                            var userList = roleUsers.slice(0, 10).join('<br>');

                            if (roleUsers.length == 0) {
                                message = _('The role %1 does not have users assigned, delete this role?', roleName);
                            } else {
                                message = _('The role %1 has %2 user(s) assigned, delete this role?', roleName, roleUsers.length) + '<br><br>' + userList;

                                if (roleUsers.length > 10) {
                                    message += '<br>[...]';
                                }

                                message += '<br>';
                            }
                            Ext.Msg.confirm(_('Confirmation'), message,
                                function(btn) {
                                    if (btn == 'yes') {
                                        var conn = new Ext.data.Connection();
                                        conn.request({
                                            url: '/role/delete',
                                            params: {
                                                id_role: sel.data.id,
                                                delete_confirm: '1'
                                            },
                                            success: function() {
                                                grid.getStore().remove(sel);
                                                store.reload();
                                            },
                                            failure: function() {
                                                Ext.Msg.alert(_('Error'), _('Could not delete the role'));
                                            }
                                        });
                                    }
                                });
                        },
                        failure: function() {
                            Ext.Msg.alert(_('Error'), _('The role does not exist'));
                        }
                    });
                }
            }),

            new Ext.Toolbar.Button({
                text: _('Duplicate'),
                icon: '/static/images/icons/copy.svg',
                cls: 'x-btn-text-icon',
                handler: function() {
                    var sm = grid.getSelectionModel();
                    if (sm.hasSelection()) {
                        var sel = sm.getSelected();
                        var conn = new Ext.data.Connection();
                        conn.request({
                            url: '/role/duplicate',
                            params: {
                                id_role: sel.data.id
                            },
                            success: function(resp, opt) {
                                grid.getStore().load();
                            },
                            failure: function(resp, opt) {
                                Ext.Msg.alert(_('Error'), _('Could not duplicate the role'));
                            }
                        });
                    } else {
                        Ext.Msg.alert('Error', _('Select at least one row'));
                    };
                }
            }),
            '->'
        ]
    });
    grid.on("activate", function() {
        if( fistLoad ) {
            Baseliner.showLoadingMask( grid.getEl());
            fistLoad = false;
        }
    });
    store.load({
        params:{
            start:0,
            limit: ps
        },
        callback: function(){
            Baseliner.hideLoadingMaskFade(grid.getEl());
        }
    });

    grid.getView().forceFit = true;

    grid.list_actions = function(ix, invalid) {
        var row = grid.store.getAt(ix);
        var role = row.data.id;
        Baseliner.ajax_json('/role/actions', {
            role_id: role
        }, function(res) {
            var actions = [];
            Ext.each((invalid ? res.invalid_actions : res.actions), function(r) {
                actions.push([(r.key || r.name), r.name]);
            });
            var st = new Ext.data.SimpleStore({
                fields: ['key', 'name'],
                data: actions
            });
            var agrid = new Ext.grid.GridPanel({
                store: st,
                stripeRows: true,
                autoScroll: true,
                viewConfig: {
                    forceFit: true
                },
                loadMask: true,
                columns: [{
                    header: _('Name'),
                    width: 100,
                    dataIndex: 'name',
                    sortable: true
                }, {
                    header: _('Key'),
                    width: 100,
                    dataIndex: 'key',
                    sortable: true
                }]
            });
            var wt = invalid ? _('Invalid actions for role %1', row.data.role) : _('Actions for role %1', row.data.role);
            var cleanUpButton = !invalid ? '' : new Ext.Button({
                icon: '/static/images/icons/delete.svg',
                text: _('Delete Invalid Actions'),
                handler: function() {
                    var sm = agrid.getSelectionModel();
                    var sel = sm.getSelected();
                    var actions = sel ? sel.data : res.invalid_actions; // selected one or all
                    Baseliner.ajax_json('/role/cleanup', {
                        id: row.data.id,
                        actions: actions
                    }, function(resDelete) {
                        Baseliner.message(_('Delete'), resDelete.msg);
                        grid.store.reload();
                        if (sel) {
                            agrid.store.remove(sel);
                        } else {
                            win.close();
                        }
                    });
                }
            });
            var win = new Baseliner.Window({
                title: wt,
                height: 400,
                width: 800,
                layout: 'fit',
                items: [agrid],
                tbar: [cleanUpButton]
            });
            win.show();
        });
    };

    grid.on("rowdblclick", function(grid, rowIndex, e ) {
        var row = grid.getStore().getAt(rowIndex);
        Baseliner.showLoadingMask( grid.getEl());
        openRoleDetail( row.get('id'), row.get('role'));
        Baseliner.hideLoadingMaskFade(grid.getEl());
    });

    grid.on("load", function(grid, rowIndex, e ) {
        Baseliner.hideLoadingMaskFade(grid.getEl());
    });

    return grid;
});
