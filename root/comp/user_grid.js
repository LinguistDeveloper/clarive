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
            {  name: 'account_type'}
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
    store.load({params:{start:0 , limit: ps}});

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
                icon:'/static/images/icons/key-add.svg',
                cls: 'x-btn-text-icon ui-comp-users-edit-window-assign-roles',
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
                    if (form.getValues()['id'] != -1) {
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
            icon:'/static/images/icons/key-delete.svg',
            cls: 'x-btn-text-icon ui-comp-users-unassign-roles',
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
                    if (form.getValues()['id'] != '0') {
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
            icon:'/static/images/icons/close.svg',
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
                var form = form_user.getForm();

                var action = form.getValues()['id'] != '-1' ? 'update' : 'add';

                if (form.isValid()) {
                    var swDo = true;
                    if (form.findField('pass').emptyText != form.getValues()['pass'] && form.getValues()['pass'] != '') {
                        if (form.getValues()['pass_cfrm'] != form.getValues()['pass']) {
                            Ext.Msg.show({
                                title: _('Information'),
                                msg: _('Passwords do not match'),
                                buttons: Ext.Msg.OK,
                                icon: Ext.Msg.INFO
                            });
                            swDo = false;
                        };
                    }
                    if (swDo) {
                        form.submit({
                            params: {
                                action: action,
                                type: 'user'
                            },
                            success: function(f, a) {
                                Baseliner.message(_('Success'), a.result.msg);
                                store.load({
                                    params: {
                                        start: 0,
                                        limit: ptool.pageSize || ps
                                    }
                                });
                                grid.getSelectionModel().clearSelections();
                                store_user_roles_projects.load({
                                    params: {
                                        username: form.getValues()['username']
                                    }
                                });
                                form.findField("id").setValue(a.result.user_id);
                                form.findField("username").getEl().dom.setAttribute('readOnly', true);
                                win.setTitle(_('Edit user'));
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
            autoSizeColumns: true,
            viewConfig: {
                forceFit: true
            },
            loadMask: true,
            columns: [
                check_roles_sm,
                { hidden: true, dataIndex:'id' },
                { header: _('All'), width:250, dataIndex: 'role', sortable: true }
            ]
        });

        grid_roles.on('rowclick', function(grid, rowIndex, columnIndex, e) {
            control_buttons();
        });

        var blank_image = new Ext.BoxComponent({
             autoEl: {
                 tag: 'img',
                 src: Ext.BLANK_IMAGE_URL
             },
             height: 10
         });

        var treeRoot = new Ext.tree.AsyncTreeNode({
            text: _('All'),
            draggable: false,
            checked: false,
            id: 'All',
            iconCls:'default_folders',
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
            rootVisible: true,
            preloadChildren: true,
            root: treeRoot
        });

        tree_projects.getLoader().on("beforeload", function(treeLoader, node) {
            var loader = tree_projects.getLoader();
            loader.baseParams = node.attributes.data;
            loader.dataUrl = window.location.origin + "/" + tree_projects.dataUrl;
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

        var btn_delete_row = new Ext.Toolbar.Button({
            text: _('Delete row'),
            icon: IC('delete-grid-row'),
            cls: 'x-btn-text-icon',
            disabled: true,
            handler: function() {
                var sm = grid_user_roles_projects.getSelectionModel();
                if (sm.hasSelection()) {
                    var row = sm.getSelected();
                    Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the row selected?'),
                    function(btn){
                        if(btn=='yes') {
                            var form = form_user.getForm();
                            var id_role = row.data.id_role;
                            var username = form.getValues()['username'];
                            Baseliner.ajaxEval( '/user/update',{ action: 'delete_roles_projects', roles_checked: id_role, type:'roles_projects', username: username },
                                function(response) {
                                    if ( response.success ) {
                                        Baseliner.message( _('Success'), response.msg );
                                        store_user_roles_projects.load({ params: {username: username } });
                                        btn_delete_row.disable();
                                    } else {
                                        Baseliner.message( _('ERROR'), response.msg );
                                    }
                                }
                            );
                        }
                    });
                }
            }
        });

        var btn_delete_all = new Ext.Toolbar.Button({
            text: _('Delete All'),
            icon: IC('delete-grid-all-rows'),
            cls: 'x-btn-text-icon',
            handler: function() {
                Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the row selected?'), function(btn){
                    if(btn=='yes') {
                        var form = form_user.getForm();
                        var action = 'delete_roles_projects';
                        var projects_checked = new Array();
                        var projects_parents_checked = new Array();
                        var roles_checked = new Array();;

                        store_user_roles_projects.getRange().forEach(function(rec){
                            roles_checked.push(rec.id);
                        });
                        if(roles_checked.length>0){
                            Baseliner.ajaxEval( '/user/update',{ action: 'delete_roles_projects', roles_checked: roles_checked, type:'roles_projects', username: username },
                                function(response) {
                                    if ( response.success ) {
                                        Baseliner.message( _('Success'), response.msg );
                                        store_user_roles_projects.load({ params: {username: username } });
                                    } else {
                                        Baseliner.message( _('ERROR'), response.msg );
                                    }
                                }
                            );
                        }
                    }
                });
            }
        })

        var grid_user_roles_projects = new Ext.grid.GridPanel({
            title: _('Roles/Projects User'),
            stripeRows: true,
            autoScroll: true,
            store: store_user_roles_projects,
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
                renderer: render_rol_field
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
                renderer: render_projects
            }],
            autoSizeColumns: true,
            boxMinHeight: 150,
            bbar: [
                btn_delete_row,
                btn_delete_all
            ]
        });

        grid_user_roles_projects.on('cellclick', function(grid, rowIndex, columnIndex, e) {
            if(columnIndex == 1){
                btn_delete_row.enable();
            }
        });

        var form_user = new Ext.FormPanel({
            name: form_user,
            url: '/user/update',
            frame: true,
            cls: 'user_grid_edit_window_padding',
            layout: 'fit',
            items: [
                {
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
                                // column layout with 2 columns
                                layout: 'column',
                                defaults: {
                                    columnWidth: 0.5,
                                    layout: 'form',
                                    border: false,
                                    xtype: 'panel',
                                    bodyStyle: 'padding:0 18px 0 0'
                                },
                                items: [{
                                    // left column
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
                                    // right column
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
                                // column layout with 2 columns
                                layout: 'column',
                                defaults: {
                                    columnWidth: 0.5,
                                    layout: 'form',
                                    border: false,
                                    xtype: 'panel',
                                    bodyStyle: 'padding:0 18px 0 0'
                                },
                                items: [{
                                    // left column
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
                                    // right column
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
                                // column layout with 2 columns
                                layout: 'column',
                                defaults: {
                                    columnWidth: 0.5,
                                    layout: 'form',
                                    border: false,
                                    xtype: 'panel',
                                    bodyStyle: 'padding:0 18px 0 0'
                                },
                                items: [{
                                    // left column
                                    defaults: {
                                        anchor: '100%'
                                    },
                                    items: [
                                    ]
                                }, {
                                    // right column
                                    defaults: {
                                        anchor: '100%'
                                    },
                                    items: [{
                                        fieldLabel: _('Phone Number'),
                                        name: 'phone',
                                        emptyText: 'xx-xxx-xx-xx',
                                        //maskRe: /[\d\-]/,
                                        //regex: /^\d{2}-\d{3}-\d{2}-\d{2}$/,
                                        //regexText: 'Must be in the format xxx-xxx-xxxx',
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
                            }
                        ]
                    }, {
                        columnWidth: 0.10,
                        items: [
                            saveButton,
                            blank_image,
                            btn_cerrar
                        ]
                    }]
                },
                blank_image,
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
        var title = _('Create user');

        if(rec){
            var ff = form_user.getForm();
            ff.loadRecord( rec );
            username = rec.get('username');
            title = _('Edit user');
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
                    form_user
                ]
            }, {
                region: 'center',
                layout: 'border',
                items: [{
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
                            items: grid_roles
                        }, {
                            layout: 'fit',
                            flex: 1,
                            items: tree_projects
                        }],
                        bbar: [
                            btn_asignar_roles_projects,
                            btn_desasignar_roles_projects
                        ],
                    }]
                }, {
                    xtype: 'container',
                    split: true,
                    layout: 'fit',
                    region: 'center',
                    items: [
                        grid_user_roles_projects
                    ]
                }]
            }]
        });
        if (win.height >= window.innerHeight) {
            win.setSize(win.width, window.innerHeight - Cla.constants.MARGIN_BOTTOM_SIZE);
        }
        if (win.width >= window.innerWidth) {
            win.setSize(window.innerWidth - Cla.constants.MARGIN_BOTTOM_SIZE, win.height);
        }

        win.show();
        store_user_roles_projects.load({ params: {username: username} });
        store_roles.load({params:{start:0 }});
    };


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
            add_edit();
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
                add_edit(sel);
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
                    Baseliner.ajaxEval( '/user/update?action=delete',
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
