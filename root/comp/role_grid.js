(function(){

    var store=new Baseliner.JsonStore({
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

    var role_detail = function(id_role, role){
        Baseliner.add_tabcomp('/comp/role_detail.js', null, { id_role: id_role, role: role, id_grid: grid.getId()  } );
    }

    //////////////// Role Create / Edit Window

    var render_actions = function (val){
        if( val == null || val == undefined ) return '';
        if( typeof val != 'object' ) return '';
        var str = ''
        for( var i=0; i<val.length; i++ ) {
            if( val[i].bl != undefined )
                str += String.format('<li>{0} ({1}) - {2}</li>', _(val[i].name), val[i].key, val[i].bl );
            else
                str += String.format('<li>{0} ({1})</li>', _(val[i].name), val[i].key );
        }
        return str;
    }

    var render_options = function (val,m,rd,inx){
        var kactions = rd.data.actions.length;
        var kiactions = rd.data.invalid_actions.length;
        return '<div id="boot" style="background: transparent">' + String.format('<button class="btn btn-mini" type="button" onclick="javascript:Ext.getCmp(\'{0}\').list_actions({1})">{2}</button>', grid.id, inx, _('Actions (%1)', kactions ) )
            + ( kiactions == 0 ? '' :
                String.format(' <button class="btn btn-mini btn-danger" type="button" onclick="javascript:Ext.getCmp(\'{0}\').list_actions({1},true)" style="color: #">{2}</button>', grid.id,inx, _('Invalid (%1)', kiactions) )
            )
            + '</div>';
        ;
    }
        var first_load = true;
        var ps = 60; //page_size

        // create the grid
        var grid = new Ext.grid.GridPanel({
            renderTo: 'main-panel',
            title: _('Roles'),
            header: false,
            autoScroll: true,
            store: store,
            stripeRows:true,
            viewConfig: { forceFit: true },
            selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
            columns: [
                { header: _('Role'), width: 200, dataIndex: 'role', sortable: true, renderer: function(v){ return '<b>'+v+'</b>'} },
                { header: _('Description'), width: 200, dataIndex: 'description', sortable: true },
                { header: _('Mailbox'), width: 200, dataIndex: 'mailbox', sortable: true, renderer: Baseliner.escape_lt_gt  },
                { header: _('Options'), width: 200, dataIndex: 'role', sortable: true, renderer: render_options },
                { header: _('Actions'), width: 400, dataIndex: 'actions', sortable: true, hidden: true, renderer: render_actions }
              //, { header: _('Members'), width: 150, dataIndex: 'users', sortable: true }
            ],
            autoSizeColumns: true,
            deferredRender:true,
            bbar: new Ext.PagingToolbar({
                                store: store,
                                pageSize: ps,
                                displayInfo: true,
                                displayMsg: _('Rows {0} - {1} de {2}'),
                                emptyMsg: "No hay registros disponibles"
                        }),
            tbar: [ _('Search') + ': ', ' ',
                new Baseliner.SearchField({
                    store: store,
                    params: {start: 0, limit: ps},
                    emptyText: _('<Enter your search string>')
                }),' ',' ',
                new Ext.Toolbar.Button({
                    text: _('Add'),
                    icon:'/static/images/icons/add.gif',
                    cls: 'x-btn-text-icon ui-comp-role-create',
                    handler: function() {
                        role_detail();
                    }
                }),
                new Ext.Toolbar.Button({
                    text: _('Edit'),
                    icon:'/static/images/icons/edit.gif',
                    cls: 'x-btn-text-icon',
                    handler: function() {
                        var sm = grid.getSelectionModel();
                        if (sm.hasSelection()) {
                            var sel = sm.getSelected();
                            role_detail(sel.data.id, sel.data.role);
                        } else {
                            Ext.Msg.alert('Error', _('Select at least one row'));
                        };
                    }
                }),

                new Ext.Toolbar.Button({
                    text: _('Delete'),
                    icon: '/static/images/icons/delete_.png',
                    cls: 'x-btn-text-icon',
                    handler: function() {
                        var sm = grid.getSelectionModel();

                        var sel = undefined;
                        sel = sm.getSelected();

                        if (sel === undefined) {
                            Ext.Msg.alert('Status', _('Please, select the role to delete'));
                            return;
                        }

                        var consult_role_user = new Ext.data.Connection();
                        consult_role_user.request({
                            url: '/role/delete',
                            params: {
                                id_role: sel.data.id
                            },
                            success: function(resp, opt) {
                                var info = Ext.util.JSON.decode(resp.responseText);

                                var message = undefined;

                                var role_name = sel.json.role.bold();
                                var role_users = info.users;
                                var user_list = role_users.slice(0, 10).join('<br>');

                                if (role_users.length == 0) {
                                    message = _('The role %1 does not have users assigned, delete this role?', role_name);
                                } else {
                                    message = _('The role %1 have %2 user(s) assigned, delete this role?', role_name, role_users.length) + '<br><br>' + user_list;

                                    if (role_users.length > 10) {
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
                                                success: function(resp, opt) {
                                                    grid.getStore().remove(sel);
                                                },
                                                failure: function(resp, opt) {
                                                    Ext.Msg.alert(_('Error'), _('Could not delete the role'));
                                                }
                                            });
                                        }
                                    });
                            },
                            failure: function(resp, opt) {
                                Ext.Msg.alert(_('Error'), _('El rol consultado no existe'));
                            }
                        });
                    }
                }),

                 new Ext.Toolbar.Button({
                    text: _('Duplicate'),
                    icon:'/static/images/icons/copy.gif',
                    cls: 'x-btn-text-icon',
                    handler: function() {
                        var sm = grid.getSelectionModel();
                        if (sm.hasSelection()) {
                            var sel = sm.getSelected();
                            var conn = new Ext.data.Connection();
                            conn.request({
                                url: '/role/duplicate',
                                params: { id_role: sel.data.id },
                                success: function(resp,opt) { grid.getStore().load(); },
                                failure: function(resp,opt) { Ext.Msg.alert(_('Error'), _('Could not duplicate the role')); }
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
        if( first_load ) {
            Baseliner.showLoadingMask( grid.getEl());
            first_load = false;
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

    grid.list_actions = function(ix,invalid){
        var row = grid.store.getAt(ix);
        var actions = [];
        Ext.each( (invalid ? row.data.invalid_actions : row.data.actions),function(r){
            actions.push([ (r.key||r.name), r.name ]);
        });
        var st = new Ext.data.SimpleStore({ fields: ['key','name'], data: actions });
        var agrid = new Ext.grid.GridPanel({
            store: st,
            autoScroll: true,
            stripeRows: true,
            viewConfig: { forceFit: true },
            loadMask: true,
            columns: [
               { header: _('Name'), width: 100, dataIndex: 'name', sortable: true  },
               { header: _('Key'), width: 100, dataIndex: 'key', sortable: true  }
            ]
        });
        var wt = invalid ? _('Invalid actions for role %1', row.data.role) : _('Actions for role %1', row.data.role);
        var btn_cleanup = !invalid ? '' : new Ext.Button({
            icon:'/static/images/icons/delete_red.png',
            text:_('Remove Invalid Actions'),
            handler: function(){
                var sm = agrid.getSelectionModel();
                var sel = sm.getSelected();
                var actions = sel ? sel.data : row.data.invalid_actions;  // selected one or all
                Baseliner.ajax_json('/role/cleanup', { id: row.data.id, actions: actions }, function(res){
                    Baseliner.message(_('Delete'), res.msg );
                    grid.store.reload();
                    if( sel ) {
                        agrid.store.remove(sel);
                    } else {
                        win.close();
                    }
                });
        }});
        var win = new Baseliner.Window({
            title: wt, height: 400, width: 800, layout:'fit', items:[agrid],
            tbar: [ btn_cleanup ]
        });
        win.show();
    };

    grid.on("rowdblclick", function(grid, rowIndex, e ) {
        var row = grid.getStore().getAt(rowIndex);
        Baseliner.showLoadingMask( grid.getEl());
        role_detail( row.get('id'), row.get('role'));
        Baseliner.hideLoadingMaskFade(grid.getEl());
    });

    grid.on("load", function(grid, rowIndex, e ) {
        Baseliner.hideLoadingMaskFade(grid.getEl());
    });

    return grid;
});
