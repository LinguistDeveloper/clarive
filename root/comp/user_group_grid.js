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

    var btn_add = new Baseliner.Grid.Buttons.Add({
        handler: function() {
            require(['/static/comp/user_group.js'], function(comp) {
                comp.show();

                comp.on('save', function() {
                    store.reload();
                });
            });
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

                require(['/static/comp/user_group.js'], function(comp) {
                    comp.show(sel);

                    comp.on('save', function() {
                        store.reload();
                    });
                });
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
                        Baseliner.ajaxEval('/usergroup/delete', {
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
