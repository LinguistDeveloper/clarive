(function(params){
    if( ! params ) params={};
    if( ! params.tbar ) params.tbar={};

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
            {  name: 'active'}
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
    
    var store_roles = new Baseliner.JsonStore({
        root: 'data' , 
        remoteSort: true,
        totalProperty:"totalCount", 
        id: 'id', 
        url: '/role/json',
        fields: [ 
            {  name: 'id' },
            {  name: 'role' },
            {  name: 'actions' },
            {  name: 'description' },
            {  name: 'mailbox' }
        ]
    });
    
    var ps = 100; //page_size
    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


    var render_projects = function (val){
        if( val == null || val == undefined ) return '';
        if( typeof val != 'object' ) return '';
        var str = ''
        for( var i=0; i<val.length; i++ ) {
        if( val[i].name){
            str += String.format('{0} <br>', val[i].name);
        }else{
            str += String.format('{0} <br>', _("All"));
        }
        }
        return str;
    }
    
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
        icon:'/static/images/icons/surrogate.png',
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
        icon:'/static/images/icons/envelope.png',
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

    var add_edit = function(rec) {
        var win;
        //var username_readonly = false;
        
        var store_user_roles_projects = new Baseliner.JsonStore({
            root: 'data' , 
            remoteSort: true,
            totalProperty:"totalCount", 
            id: 'id_role', 
            url: '/user/infodetail',
            fields: [ 
                {name: 'id_role' },
                {name: 'role' },
                {name: 'description' },
                {name: 'projects' }         
            ],
            listeners: {
                'load': function(){
                    control_buttons();
                }
            }       
        });

        var btn_asignar_roles_projects = new Ext.Toolbar.Button({
                text: _('Assign roles/projects'),
                icon:'/static/images/icons/key_add.png',
                cls: 'x-btn-text-icon',
                disabled: true,
                handler: function() {
                    var form = form_user.getForm();
                    var action = 'update';                  
                    var projects_checked = new Array();
                    var projects_parents_checked = new Array();
                    var roles_checked = new Array();
                    check_roles_sm.each(function(rec){
                        roles_checked.push(rec.get('id'));
                    });                         
                
                    selNodes = tree_projects.getChecked();
                    Ext.each(selNodes, function(node){
                        if(node.attributes.leaf){
                            projects_checked.push(node.attributes.data.id_project);
                        }else{
                            if(node.childNodes.length > 0 || node.attributes.data.id_project == 'todos'){
                                projects_checked.push(node.attributes.data.id_project);
                            }
                            else{
                                projects_parents_checked.push(node.attributes.data.id_project);
                            }
                        }
                    });
    
                    ////////////////////////////////////////////////////////////////////
                    if (form.getValues()['id'] > 0) {
                           form.submit({
                               params: { action: action,
                                     type: 'roles_projects',
                                     projects_checked: projects_checked,
                                     projects_parents_checked: projects_parents_checked,
                                     roles_checked: roles_checked
                               },
                               success: function(f,a){
                                   Baseliner.message(_('Success'), a.result.msg );
                                   store_user_roles_projects.load({ params: {username: form.getValues()['username']} });
                                   form.findField("id").setValue(a.result.user_id);
                                   form.findField("username").getEl().dom.setAttribute('readOnly', true);
                               },
                               failure: function(f,a){
                                   Ext.Msg.show({  
                                   title: _('Information'), 
                                   msg: a.result.msg , 
                                   buttons: Ext.Msg.OK, 
                                   icon: Ext.Msg.INFO
                                   });                      
                               }
                           });
                    }
                    else{
                        Ext.Msg.show({  
                            title: _('Information'), 
                            msg: _('You must save the user before'), 
                            buttons: Ext.Msg.OK, 
                            icon: Ext.Msg.INFO
                        });                         
                    }
                }
        })
        
        var btn_desasignar_roles_projects = new Ext.Toolbar.Button({
            text: _('Unassign roles/projects'),
            icon:'/static/images/icons/key_delete.png',
            cls: 'x-btn-text-icon',
            disabled: true,
            handler: function() {
                var form = form_user.getForm();
                var action = 'delete_roles_projects';                   
                var projects_checked = new Array();
                var projects_parents_checked = new Array();
                var roles_checked = new Array();
                check_roles_sm.each(function(rec){
                    roles_checked.push(rec.get('id'));
                });                         
            
                selNodes = tree_projects.getChecked();
                Ext.each(selNodes, function(node){
                        if(node.attributes.leaf){
                            projects_checked.push(node.attributes.data.id_project);
                        }else{
                            if(node.childNodes.length > 0 || node.attributes.data.id_project == 'todos'){
                                projects_checked.push(node.attributes.data.id_project);
                            }
                            else{
                                projects_parents_checked.push(node.attributes.data.id_project);
                            }
                        }
                });

                ////////////////////////////////////////////////////////////////////
                    if (form.getValues()['id'] > 0) {
                           form.submit({
                           params: { action: action,
                                 type: 'roles_projects',
                                 projects_checked: projects_checked,
                                 projects_parents_checked: projects_parents_checked,
                                 roles_checked: roles_checked
                           },
                           success: function(f,a){
                               Baseliner.message(_('Success'), a.result.msg );
                               store_user_roles_projects.load({ params: {username: form.getValues()['username']} });
                               form.findField("username").getEl().dom.setAttribute('readOnly', true);
                           },
                           failure: function(f,a){
                               Ext.Msg.show({  
                               title: _('Information'), 
                               msg: a.result.msg , 
                               buttons: Ext.Msg.OK, 
                               icon: Ext.Msg.INFO
                               });                      
                           }
                           });
                    }
                    else{
                        Ext.Msg.show({  
                            title: _('Information'), 
                            msg: _("User doesn't exist"), 
                            buttons: Ext.Msg.OK, 
                            icon: Ext.Msg.INFO
                        });                         
                    }
                //////////////////////////////////////////////////////////////////////////

            }
        })
        
        var btn_cerrar = new Ext.Toolbar.Button({
            text: _('Close'),
            icon:'/static/images/icons/close.png',
            width: 70,
            handler: function() {
                win.close();
            }
        })
        
        var btn_grabar_user =   new Ext.Toolbar.Button({
            text: _('Save'),
            icon:'/static/images/icons/save.png',
            width: 70,
            handler: function(){
                var form = form_user.getForm();
                var action = form.getValues()['id'] >= 0 ? 'update' : 'add';
                
                if (form.isValid()) {
                    var swDo = true;
                    if (form.findField('pass').emptyText != form.getValues()['pass'] && form.getValues()['pass'] !='' ){
                        if(form.getValues()['pass_cfrm'] != form.getValues()['pass']){
                                       Ext.Msg.show({  
                                       title: _('Information'), 
                                       msg: _('Passwords do not match'), 
                                       buttons: Ext.Msg.OK, 
                                       icon: Ext.Msg.INFO
                                       });
                            swDo = false;
                        };                  
                    }
                    if (swDo){
                        form.submit({
                            params: { action: action,
                                  type: 'user'
                            },
                            success: function(f,a){
                            Baseliner.message(_('Success'), a.result.msg );
                            store.load();
                            grid.getSelectionModel().clearSelections();
                            store_user_roles_projects.load({ params: {username: form.getValues()['username']} });
                            form.findField("id").setValue(a.result.user_id);
                            form.findField("username").getEl().dom.setAttribute('readOnly', true);
                            btn_grabar_user.disable();
                            win.setTitle(_('Edit user'));
                            },
                            failure: function(f,a){
                            Ext.Msg.show({  
                                title: _('Information'), 
                                msg: a.result.msg , 
                                buttons: Ext.Msg.OK, 
                                icon: Ext.Msg.INFO
                            });                         
                            }
                        });
                    }
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
            height:200,
            columns: [
                check_roles_sm,
                { hidden: true, dataIndex:'id' }, 
                { header: _('All'), width:250, dataIndex: 'role', sortable: true }
            ],
            autoSizeColumns: true
        });
        
        grid_roles.on('rowclick', function(grid, rowIndex, columnIndex, e) {
            control_buttons();
        });     
    
        var blank_image = new Ext.BoxComponent({autoEl: {tag: 'img', src: Ext.BLANK_IMAGE_URL}, height:10});
    
        var treeRoot = new Ext.tree.AsyncTreeNode({
            text: _('All'),
            draggable: false,
            checked: false,
            id: 'All',
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
            height:200,         
            rootVisible: true,
            preloadChildren: true,
            root: treeRoot
        });
        
        tree_projects.getLoader().on("beforeload", function(treeLoader, node) {
            var loader = tree_projects.getLoader();
        
            loader.baseParams = node.attributes.data;
            node.attributes.data.parent_checked = (node.attributes.checked)?1:0;
        });
        
        tree_projects.on('checkchange', function(node, checked) {
            if(node != treeRoot){
                if (node.attributes.checked == false){
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

        var control_buttons = function (){
            var projects_nodes = tree_projects.getChecked().length;
            var roles_nodes = check_roles_sm.getCount();
            var rows_roles_projects = store_user_roles_projects.getCount();
            
            if(roles_nodes < 1 && projects_nodes < 1){
                btn_desasignar_roles_projects.disable();
                btn_asignar_roles_projects.disable();
            }
            else{
                if(projects_nodes < 1){
                    btn_asignar_roles_projects.disable();
                    rows_roles_projects < 1 ? btn_desasignar_roles_projects.disable():btn_desasignar_roles_projects.enable();
                }
                else{
                    if(roles_nodes < 1){
                        if(rows_roles_projects < 1){
                            btn_desasignar_roles_projects.disable()
                            btn_asignar_roles_projects.disable();
                        }
                        else{
                            btn_desasignar_roles_projects.enable()
                            btn_asignar_roles_projects.enable();
                        }
                    }
                    else{
                        rows_roles_projects < 1 ? btn_desasignar_roles_projects.disable():btn_desasignar_roles_projects.enable();
                        btn_asignar_roles_projects.enable();
                    }
                    
                }
            }
        }   


        //Para cuando se envia el formulario no coja el atributo emptytext de los textfields
        Ext.form.Action.prototype.constructor = Ext.form.Action.prototype.constructor.createSequence(function() {
            Ext.applyIf(this.options, {
            submitEmptyText:false
            });
        });

        var render_rol_field  = function(value,metadata,rec_grid,rowIndex,colIndex,store) {
            if( value==undefined || value=='null' || value=='' ) return '';
            //var script = String.format('javascript:Baseliner.showAjaxComp("/user/infoactions/{0}?id_role={1}&username={2}")', value, rec_grid.data.id_role, rec.data.username );
            var script = String.format('javascript:Baseliner.user_actions({ username: \"{0}\", id_role: \"{1}\"})', rec_grid.data.username, rec_grid.data.id_role );
            return String.format("<a href='{0}'>{1}</a>", script, value );
        };
        
        var grid_user_roles_projects = new Ext.grid.GridPanel({
            title: _('Roles/Projects User'),
            stripeRows: true,
            autoScroll: true,
            autoWidth: true,
            store: store_user_roles_projects,
            viewConfig: {
                forceFit: true
            },
            selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
            loadMask: true,
            columns: [
                { header: _('Role'), width: 120, dataIndex: 'role', sortable: true, renderer: render_rol_field },   
                { header: _('Description'), width: 350, dataIndex: 'description', sortable: true },
                { header: _('Namespace'), width: 150, dataIndex: 'projects', sortable: false, renderer: render_projects }
            ],
            autoSizeColumns: true,
            deferredRender:true,
            height:200
        });
        
        var form_user = new Ext.FormPanel({
            name: form_user,
            url: '/user/update',
            frame: true,
            
            items   : [
            {
            layout:'column'
            ,defaults:{
                layout:'form'
                ,border:false
                ,xtype:'panel'
                ,bodyStyle:'padding:0 18px 0 0'
            }
            ,items:[{
                columnWidth:0.90,
                items:[
                    { xtype: 'hidden', name: 'id', value: -1 },
                    {
                    // column layout with 2 columns
                    layout:'column'
                    ,defaults:{
                        columnWidth:0.5
                        ,layout:'form'
                        ,border:false
                        ,xtype:'panel'
                        ,bodyStyle:'padding:0 18px 0 0'
                    }
                    ,items:[{
                        // left column
                        defaults:{anchor:'100%'}
                        ,items:[
                            { fieldLabel: _('User'), name: 'username', emptyText: 'Usuario', allowBlank:false, xtype: 'textfield'}
                            ]
                        },
                        {
                        // right column
                        defaults:{anchor:'100%'}
                        ,items:[
                            //{ fieldLabel: _('Alias'), name: 'alias', emptyText: 'Alias', xtype: 'textfield'}
                            { fieldLabel: _('Password'), name: 'pass', id:'pass', emptyText: '********', xtype: 'textfield',  inputType: 'password'}
                            ]
                        }
                    ]
                    },
                    {
                    // column layout with 2 columns
                    layout:'column'
                    ,defaults:{
                        columnWidth:0.5
                        ,layout:'form'
                        ,border:false
                        ,xtype:'panel'
                        ,bodyStyle:'padding:0 18px 0 0'
                    }
                    ,items:[{
                        // left column
                        defaults:{anchor:'100%'}
                        ,items:[
                            { fieldLabel: _('Alias'), name: 'alias', emptyText: 'Alias', xtype: 'textfield'}
                            ]
                        },
                        {
                        // right column
                        defaults:{anchor:'100%'}
                        ,items:[
                            {
                            fieldLabel: _('Confirm Password'),
                            name: 'pass_cfrm',
                            emptyText: '********',
                            inputType: 'password',
                            vtype: 'password',
                            initialPassField: 'pass',
                            xtype: 'textfield'
                            }
                            ]
                        }
                    ]
                    },
                    
                    { anchor:'97%', fieldLabel: _('Name'), name: 'realname', emptyText: 'Full name', xtype: 'textfield'},                   
                    {
                    // column layout with 2 columns
                    layout:'column'
                    ,defaults:{
                        columnWidth:0.5
                        ,layout:'form'
                        ,border:false
                        ,xtype:'panel'
                        ,bodyStyle:'padding:0 18px 0 0'
                    }
                    ,items:[{
                        // left column
                        defaults:{anchor:'100%'}
                        ,items:[
                            //{ fieldLabel: _('Alias'), name: 'alias1', emptyText: 'Alias', xtype: 'textfield'}
                            ]
                        },
                        {
                        // right column
                        defaults:{anchor:'100%'}
                        ,items:[
                            {
                            fieldLabel: _('Phone Number'),
                            name: 'phone',
                            emptyText: 'xx-xxx-xx-xx',
                            //maskRe: /[\d\-]/,
                            //regex: /^\d{2}-\d{3}-\d{2}-\d{2}$/,
                            //regexText: 'Must be in the format xxx-xxx-xxxx',
                            xtype: 'textfield'
                            }
                            ]
                        }
                    ]
                    },
                    {
                    anchor:'97%',
                    fieldLabel: _('Email address'),
                    name: 'email',
                    emptyText: 'usuario@dominio.com',
                    vtype: 'email',
                    xtype: 'textfield'
                    }
                    ]
                },
                {
                columnWidth:0.10,
                items:[
                    btn_grabar_user,
                    blank_image,
                    btn_cerrar
                    ]
                }
            ]
            },
            blank_image 
            ,
            {
            xtype: 'panel',
            layout: 'column',
            bbar: [
                   btn_asignar_roles_projects,
                   btn_desasignar_roles_projects
            ],          
            items:  [
                {  
                columnWidth: .49,
                items:  grid_roles
                },
                {
                columnWidth: .02,
                items: blank_image
                },
                {  
                columnWidth: .49,
                items: tree_projects
            }]  
            },
            grid_user_roles_projects
        ]
        });

        Ext.apply(Ext.form.VTypes, {
            password : function(val, field) {
            if (field.initialPassField) {
                var pwd = Ext.getCmp(field.initialPassField);
                return (val == pwd.getValue());
            }
            return true;
            },
        
            passwordText : _('Passwords do not match')
        });     
        
        var username = '';
        var title = 'Create user';
        
        if(rec){
            var ff = form_user.getForm();
            ff.loadRecord( rec );
            username = rec.get('username');
            title = 'Edit user';
            //username_readonly = true;
        }

        win = new Ext.Window({
            title: _(title),
            autoHeight: true,
            width: 730,
            closeAction: 'close',
            modal: true,
            constrain: true,
            items: [
                form_user
            ]
        });
        store_roles.load({params:{start:0 , limit: ps}});
        store_user_roles_projects.load({ params: {username: username} });       
        win.show();
    };
    
 
    //var btn_add = new Ext.Toolbar.Button({
    //    text: _('New'),
    //    //icon:'/static/images/icons/add.gif',
    //    //cls: 'x-btn-text',
    //    iconCls: 'sprite add',
    //    handler: function() {
    //        add_edit();
    //    }
    //});
    
    var btn_add = new Baseliner.Grid.Buttons.Add({
        handler: function() {
            add_edit();
        }       
    });    
    
    
    

    var btn_edit = new Ext.Toolbar.Button({
        text: _('Edit'),
        icon:'/static/images/icons/edit.gif',
        cls: 'x-btn-text-icon',
        disabled: true,
        handler: function() {
        var sm = grid.getSelectionModel();
            if (sm.hasSelection()) {
                var sel = sm.getSelected();
                add_edit(sel);
            } else {
                Baseliner.message( _('ERROR'), _('Select at least one row'));    
            };
        }
    });
    
    var btn_prefs = new Ext.Toolbar.Button({
        text: _('Preferences'),
        icon:'/static/images/icons/prefs.png',
        cls: 'x-btn-text-icon',
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
        icon:'/static/images/icons/copy.gif',
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
        icon:'/static/images/icons/delete_.png',
        cls: 'x-btn-text-icon',
        disabled: true,
        handler: function() {
            var sm = grid.getSelectionModel();
            var sel = sm.getSelected();
            Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the user') + ' <b>' + sel.data.username + '</b>?', 
            function(btn){ 
                if(btn=='yes') {
                    Baseliner.ajaxEval( '/user/update?action=delete',
                        { id: sel.data.id,
                          username: sel.data.username
                        },
                        function(response) {
                            if ( response.success ) {
                                grid.getStore().remove(sel);
                                Baseliner.message( _('Success'), response.msg );
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
        icon:'/static/images/icons/delete_.png',
        cls: 'x-btn-text-icon',
        disabled: true,
        handler: function() {
            
        }
    });
    
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
                { header: _('Id'), hidden: true, dataIndex: 'id' },
                { header: _('Avatar'), hidden: false, width: 64, dataIndex: 'username', renderer: Baseliner.render_avatar },
                { header: _('User'), width: 120, dataIndex: 'username', sortable: true, renderer: Baseliner.render_user_field },
                { header: _('Name'), width: 350, dataIndex: 'realname', sortable: true },
                { header: _('Alias'), width: 150, dataIndex: 'alias', sortable: true },
                { header: _('Language'), width: 60, dataIndex: 'language_pref', sortable: true },
                { header: _('Email'), width: 150, dataIndex: 'email'  },
                { header: _('Phone'), width: 100, dataIndex: 'phone' }
            ],
            autoSizeColumns: true,
            deferredRender:true,
            bbar: new Ext.PagingToolbar({
                    store: store,
                    pageSize: ps,
                    displayInfo: true,
                    displayMsg: _('Rows {0} - {1} of {2}'),
                    emptyMsg: _('There are no rows available')
            }),        
            tbar: [ _('Search') + ': ', ' ',
                new Baseliner.SearchField({
                    store: store,
                    params: {start: 0, limit: ps},
                    emptyText: _('<Enter your search string>')
                }),' ',' ',


                
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
            
    store.load({params:{start:0 , limit: ps}});
    return grid;
})
