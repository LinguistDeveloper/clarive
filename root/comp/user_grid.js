(function(params){
    if( ! params ) params={};
    if( ! params.tbar ) params.tbar={};
    var ps = 30;

    var store = new Baseliner.JsonStore({
        root: 'data' ,
        remoteSort: true,
        totalProperty:"totalCount",
        id: 'id',
        url: '/user/list',
        fields: [
            {  name: 'id' },
            {  name: 'username' },
            {  name: 'role' },
            {  name: 'realname' },
            {  name: 'alias' },
            {  name: 'email' },
            {  name: 'language_pref' },
            {  name: 'phone' },
            {  name: 'ts' },
            {  name: 'active'},
            {  name: 'account_type'},
            {  name: 'groups'}
        ],
        listeners: {
            'load': function(){
                if( grid.getSelectionModel().hasSelection() )
                    init_buttons('enable');
                else
                    init_buttons('disable');
            }
        }
    });

    store.load({params:{start:0 , limit: ps}});

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    var init_buttons = function(action) {
        eval('btn_surrogate.' + action + '()');
        eval('btn_buzon.' + action + '()');
        eval('btn_edit.' + action + '()');
        eval('btn_prefs.' + action + '()');
        eval('btn_duplicate.' + action + '()');
        eval('btn_delete.' + action + '()');
    }


    var btn_surrogate = new Ext.Toolbar.Button({
        text: _('Surrogate'),
        icon:'/static/images/icons/surrogate.svg',
        cls: 'x-btn-text-icon',
        disabled: true,
        handler: function() {
            var sm = grid.getSelectionModel();
            if (sm.hasSelection()) {
                var row = sm.getSelected();
                var username = row.data.username;
                Baseliner.message( _("Surrogate"), _("Surrogating as %1", username) );
                Ext.Ajax.request({
                    url: '/auth/surrogate',
                    params: { login: username },
                    success: function(xhr) {
                        document.location.href = document.location.href;
                    },
                    failure: function(xhr) {
                        var err = xhr.responseText;
                        Baseliner.message( _("Surrogate Error"), _("Error during surrogate: %1", err ));
                    }
                });
            }
        }
    });

    var btn_buzon = new Ext.Toolbar.Button({
        text: _('Inbox'),
        icon:'/static/images/icons/envelope.svg',
        cls: 'x-btn-text-icon',
        disabled: true,
        handler: function(){
            var sm = grid.getSelectionModel();
            if (sm.hasSelection()) {
                var row = sm.getSelected();
                var username = row.data.username;
                var title = _("Inbox for %1", username);
                Baseliner.addNewTabComp("/message/inbox?username=" + username, title );
            }
        }

    });

    //var btn_add = new Ext.Toolbar.Button({
    //    text: _('New'),
    //    //icon:'/static/images/icons/add.svg',
    //    //cls: 'x-btn-text',
    //    iconCls: 'sprite add',
    //    handler: function() {
    //        add_edit();
    //    }
    //});

    var btn_add = new Baseliner.Grid.Buttons.Add({
        cls: 'ui-comp-users-create',
        handler: function() {
            require(['/static/comp/user.js'], function(comp) {
                comp.show();
            });
        }
    });

    var btn_edit = new Ext.Toolbar.Button({
        text: _('Edit'),
        icon:'/static/images/icons/edit.svg',
        cls: 'x-btn-text-icon ui-comp-users-edit',
        disabled: true,
        handler: function() {

        var sm = grid.getSelectionModel();
            if (sm.hasSelection()) {
                var sel = sm.getSelected();

                require(['/static/comp/user.js'], function(comp) {
                    comp.show(sel);
                });

            } else {
                Baseliner.message( _('ERROR'), _('Select at least one row'));
            };
        }
    });

    var btn_prefs = new Ext.Toolbar.Button({
        text: _('Preferences'),
        icon:'/static/images/icons/prefs.svg',
        cls: 'x-btn-text-icon ui-comp-users-prefs',
        disabled: true,
        handler: function() {
        var sm = grid.getSelectionModel();
            if (sm.hasSelection()) {
                var sel = sm.getSelected();
                Prefs.open_editor({ username: sel.data.username, on_save: function(res){
                    store.reload();
                }});
            } else {
                Baseliner.message( _('ERROR'), _('Select at least one row'));
            };
        }
    });

    var btn_duplicate = new Ext.Toolbar.Button({
        text: _('Duplicate'),
        icon:'/static/images/icons/copy.svg',
        cls: 'x-btn-text-icon',
        handler: function() {
            var sm = grid.getSelectionModel();
            if (sm.hasSelection()) {
                var sel = sm.getSelected();
                Baseliner.ajaxEval( '/user/duplicate',
                    { id_user: sel.data.id },
                    function(response) {
                        if ( response.success ) {
                            store.reload();
                            Baseliner.message( _('Success'), response.msg );
                            init_buttons('disable');
                        } else {
                            Baseliner.message( _('ERROR'), response.msg );
                        }
                    }

                );
            } else {
                Ext.Msg.alert('Error', '<% _loc('Select at least one row') %>');
            };
        }
    });

    var btn_delete = new Ext.Toolbar.Button({
        text: _('Delete'),
        icon:'/static/images/icons/delete.svg',
        cls: 'x-btn-text-icon ui-comp-users-delete',
        disabled: true,
        handler: function() {
            var sm = grid.getSelectionModel();
            var sel = sm.getSelected();
            Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the user') + ' <b>' + sel.data.username + '</b>?',
            function(btn){
                if(btn=='yes') {
                    Baseliner.ajaxEval( '/user/delete',
                        { id: sel.data.id,
                          username: sel.data.username
                        },
                        function(response) {
                            if ( response.success ) {
                                grid.getStore().remove(sel);
                                Baseliner.message( _('Success'), response.msg );
                                store.reload();
                                init_buttons('disable');
                            } else {
                                Baseliner.message( _('ERROR'), response.msg );
                            }
                        }
                    );
                }
            } );
        }
    });

    var btn_change_password = new Ext.Toolbar.Button({
        text: _('Change password'),
        icon:'/static/images/icons/delete.svg',
        cls: 'x-btn-text-icon',
        disabled: true,
        handler: function() {
        }
    });

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
        params: {start: 0, limit: ptool.pageSize},
        emptyText: _('<Enter your search string>')
    });

    var grid = new Ext.grid.GridPanel({
            title: _('Users'),
            header: false,
            stripeRows: true,
            autoScroll: true,
            autoWidth: true,
            store: store,
            viewConfig: {
                forceFit: true
            },
            selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
            loadMask: true,
            columns: [
                { header: _('Id'), hidden: true, dataIndex: 'id' },
                { header: _('Avatar'), hidden: false, width: 64, dataIndex: 'username', renderer: Baseliner.render_avatar },
                { header: _('User'), width: 120, dataIndex: 'username', sortable: true, renderer: Baseliner.render_user_field },
                { header: _('Name'), width: 300, dataIndex: 'realname', sortable: true },
                { header: _('Alias'), width: 150, dataIndex: 'alias', sortable: true },
                { header: _('Language'), width: 60, dataIndex: 'language_pref', sortable: true },
                { header: _('Modified On'), width: 120, dataIndex: 'ts', sortable: true, renderer: Cla.render_date },
                { header: _('Email'), width: 150, dataIndex: 'email'  },
                { header: _('Phone'), width: 100, dataIndex: 'phone' },
                { header: _('Type'), width: 100, dataIndex: 'account_type' }
            ],
            autoSizeColumns: true,
            deferredRender:true,
            bbar: ptool,
            tbar: [ _('Search') + ': ', ' ',
                searchField,' ',' ',

% if ($c->stash->{can_maintenance}) {
                btn_add,
                btn_edit,
                btn_delete,
                btn_prefs,
                btn_duplicate,
%}

% if ($c->stash->{can_surrogate}) {
                    btn_surrogate,
%}
                btn_buzon,
                '->'
            ]
        });

    var sm = grid.getSelectionModel();
    sm.on('rowselect', function(it,rowIndex){
        var r = grid.getStore().getAt(rowIndex);
        var active = r.get( 'active' );
        if(active != '0'){
            init_buttons('enable');
        }else{
            init_buttons('disable');
        }
    });
    sm.on('rowdeselect', function(grid,rowIndex){
        init_buttons('disable');
    });

    return grid;
})
