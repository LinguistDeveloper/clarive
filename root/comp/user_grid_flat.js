(function(params){
    if( ! params ) params={};
    if( ! params.tbar ) params.tbar={};

    var store = new Baseliner.JsonStore({
        root: 'data' , 
        remoteSort: true,
        totalProperty:"totalCount", 
        id: 'id', 
        url: '/user/list_all',
        fields: [ 'id', 'username', 'role','role_desc','realname','ns','action','active','project' ]
    });

    var search_field = new Baseliner.SearchField({
        store: store,
        params: {start: 0, limit: ps}
    });

    var render_role = function(v,m,rec,ix){
        if( rec.data.role_desc==undefined ) return v;
        return String.format( '{0} ({1})', v, rec.data.role_desc );
    }
    var render_active = function(v){
        return String.format('<div class="{0}">&nbsp;</div>', ( v>0? 'bali-icon-active':'bali-icon-inactive' ) )   ;
    }
    var render_user = function(v,m,rec,ix){
        v = Baseliner.render_user_field( v ); 
        return rec.data.active > 0 ? v : String.format('<span style="text-decoration: line-through">{0}</span>',v);
    }
    var ps = 100; //page_size
    store.load({params:{start:0 , limit: ps}}); 

    // create the grid
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
            loadMask:'true',
            columns: [
                { header: _(''), width: 25, dataIndex: 'active', sortable: false, renderer: render_active },
                { header: _('User'), width: 120, dataIndex: 'username', sortable: true, renderer: render_user },	
                { header: _('Role'), width: 250, dataIndex: 'role', sortable: false, renderer: render_role },	
                { header: _('Project'), width: 150, dataIndex: 'project', sortable: false },	
                { header: _('Action'), width: 250, dataIndex: 'action', sortable: false },
                { header: _('Name'), width: 250, dataIndex: 'realname', sortable: false }
            ],
            autoSizeColumns: true,
            deferredRender:true,
            bbar: new Ext.PagingToolbar({
                                store: store,
                                pageSize: ps,
                                displayInfo: true,
                                displayMsg: 'Rows {0} - {1} de {2}',
                                emptyMsg: "No hay registros disponibles"
                        }),        
            tbar: [ 
                params.tbar,
                '-',
                search_field,
% if ( $c->stash->{can_surrogate} ) {
                {  
                    xtype: 'button',
                    text: _('Surrogate'),
                    icon:'/static/images/users.gif',
                    cls: 'x-btn-text-icon',
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
                },
%}
                {
                    xtype: 'button',
                    text: _('Inbox'),
                    icon:'/static/images/icons/envelope.gif',
                    cls: 'x-btn-text-icon',
                    handler: function(){
                        var sm = grid.getSelectionModel();
                        if (sm.hasSelection()) {
                            var row = sm.getSelected();
                            var username = row.data.username;
                            var title = _("Inbox for %1", username)
                            Baseliner.addNewTabComp("/message/inbox?username=" + username, title );
                        }
                    }

                },
<%doc>
                new Ext.Toolbar.Button({
                    text: '<% _loc('Add') %>',
                    icon:'/static/images/drop-add.gif',
                    cls: 'x-btn-text-icon',
                    handler: function() {
                        var sm = grid.getSelectionModel();
                        if (sm.hasSelection())
                        {
                            var sel = sm.getSelected();
                            Baseliner.addNewTab('/release/create?package=' + sel.data.package , '<% _loc('New Release') %>' );
                        } else {
                            Baseliner.addNewTab('/release/create' , '<% _loc('New Release') %>' );
                        };
                        
                    }
                }),
                new Ext.Toolbar.Button({
                    text: '<% _loc('Approve') %>',
                    icon:'/static/images/drop-yes.gif',
                    cls: 'x-btn-text-icon',
                    handler: function() {
                        var sm = grid.getSelectionModel();
                        if (sm.hasSelection())
                        {
                            var sel = sm.getSelected();
                            Ext.Msg.confirm('<% _loc('Confirmation') %>', '<% _loc('Are you sure you want to approve') %> ' + sel.data.package + '?', 
                                function(btn){ 
                                    if(btn=='yes') {
                                        var conn = new Ext.data.Connection();
                                        conn.request({
                                            url: '/endevor/approve',
                                            params: { action: 'delete', package: sel.data.package },
                                            success: function(resp,opt) { grid.getStore().remove(sel); },
                                            failure: function(resp,opt) { Ext.Msg.alert('<% _loc('Error') %>', '<% _loc('Could not approve the package.') %>'); }
                                        });	
                                    }
                                } );
                        } else {
                            Ext.Msg.alert('Error', 'Falta seleccionar una fila');	
                        };
                        
                    }
                }),
                new Ext.Toolbar.Button({
                    text: '<% _loc('Delete') %>',
                    icon:'/static/images/del.gif',
                    cls: 'x-btn-text-icon',
                    handler: function() {
                        var sm = grid.getSelectionModel();
                        var sel = sm.getSelected();
                        Ext.Msg.confirm('<% _loc('Confirmation') %>', 'Are you sure you want to delete the release ' + sel.data.name + '?', 
                            function(btn){ 
                                if(btn=='yes') {
                                    var conn = new Ext.data.Connection();
                                    conn.request({
                                        url: '/release/update',
                                        params: { action: 'delete', id_rel: sel.data.id },
                                        success: function(resp,opt) { grid.getStore().remove(sel); },
                                        failure: function(resp,opt) { Ext.Msg.alert('<% _loc('Error') %>', '<% _loc('Could not delete the release.') %>'); }
                                    });	
                                }
                            } );
                    }
                }),
</%doc>
                '->'
                ]
        });

        grid.on("rowdblclick", function(grid, rowIndex, e ) {
            var r = grid.getStore().getAt(rowIndex);
            //Baseliner.addNewTab('/endevor/pkg_data?package=' + r.get('package') , r.get('package') );
        });		

    return grid;
})
