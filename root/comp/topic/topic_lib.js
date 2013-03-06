Baseliner.Topic = {};
    
Baseliner.Topic.rt = Ext.data.Record.create([
    {name: 'id_project'},
    {name: 'project'}
]);

Baseliner.topic_category_class = {};

Baseliner.Topic.StoreProject = Ext.extend(Ext.data.Store, {
    constructor: function(config) {
        config = Ext.apply({
            // explicitly create reader
            reader: new Ext.data.ArrayReader(
                {
                    idIndex: 0  // id for each record will be the first element
                },
                Baseliner.Topic.rt // recordType
            )
        }, config);
        Baseliner.Topic.StoreProject.superclass.constructor.call(this, config);
    }
}); 

Baseliner.Topic.StoreStatus = Ext.extend(Baseliner.JsonStore, {
    constructor: function(config) {
        config = Ext.apply({
            root: 'data' , 
            remoteSort: true,
            totalProperty:"totalCount", 
            url: '/topicadmin/list_status',
            fields: [ 
                {  name: 'id' },
                {  name: 'name' },
                {  name: 'description' },
                {  name: 'bl' },
                {  name: 'seq' },
                {  name: 'type' },
                {  name: 'bind_releases' },
                {  name: 'ci_update' },
                {  name: 'frozen' },
                {  name: 'readonly' }
            ]
        }, config);
        Baseliner.Topic.StoreStatus.superclass.constructor.call(this, config);
    }
}); 
    
Baseliner.Topic.StoreCategory = Ext.extend( Baseliner.JsonStore, {
    constructor: function(config) {
        config = Ext.apply({
            root: 'data' , 
            remoteSort: true,
            baseParams:{cmb:'category'},
            totalProperty:"totalCount", 
            url: '/topic/list_category',
            fields: [ 
                {  name: 'id' },
                {  name: 'name' },
                {  name: 'color' },
                {  name: 'description' },
                {  name: 'type' },
                {  name: 'statuses' },
                {  name: 'forms' },
                {  name: 'is_release' },
                {  name: 'is_changeset' },
                {  name: 'fields' },
                {  name: 'priorities' }
            ]
        },config);
        Baseliner.Topic.StoreCategory.superclass.constructor.call(this, config);
    }
});

Baseliner.Topic.StoreCategoryStatus = Ext.extend( Baseliner.JsonStore, {
    constructor: function(config) {
        config = Ext.apply({
            root: 'data' , 
            remoteSort: true,
            totalProperty:"totalCount", 
            url: '/topic/list_category',
            fields: [ 
                {  name: 'id' },
                {  name: 'name' },
                {  name: 'type' },
                {  name: 'bl' },
                {  name: 'description' },
                {  name: 'action' }
            ]
        },config);
        Baseliner.Topic.StoreCategoryStatus.superclass.constructor.call(this, config);
    }
});

Baseliner.Topic.StoreList = Ext.extend( Baseliner.JsonStore, {
    constructor: function(config) {
        config = Ext.apply({
            root: 'data' , 
            remoteSort: true,
            totalProperty:"totalCount", 
            url: '/topic/list',
            fields: [ 
                {  name: 'topic_mid' },
                {  name: 'topic_name' },
                {  name: 'title' },
                //{  name: 'description' },
                {  name: 'created_on', type: 'date', dateFormat: 'c' },        
                {  name: 'created_by' },
                {  name: 'numcomment' },
                {  name: 'category_id' },
                {  name: 'category_color' },
                {  name: 'is_release' },
                {  name: 'is_changeset' },
                {  name: 'category_name' },
                {  name: 'calevent' },
                {  name: 'projects' },          
                {  name: 'labels' },
                {  name: 'status' },
                {  name: 'progress' },
                {  name: 'revisions' },
                {  name: 'report_data' },
                {  name: 'category_status_name' },
                {  name: 'category_status_seq' },
                {  name: 'category_status_id' },
                {  name: 'category_status_type' },
                {  name: 'priority_id' },
                {  name: 'response_time_min' },
                {  name: 'expr_response_time' },
                {  name: 'deadline_min' },
                {  name: 'expr_deadline' },
                {  name: 'num_file' },
                {  name: 'assignee' },
                {  name: 'sw_edit'}
            ]
        },config);
        Baseliner.Topic.StoreList.superclass.constructor.call(this, config);
    }
});

Baseliner.Topic.StoreLabel = Ext.extend( Baseliner.JsonStore, {
    constructor: function(config) {
        config = Ext.apply({
            root: 'data' , 
            remoteSort: true,
            totalProperty:"totalCount", 
            url: '/topic/list_label',
            fields: [ 
                {  name: 'id' },
                {  name: 'name' },
                {  name: 'color' }
            ]
        },config);
        Baseliner.Topic.StoreLabel.superclass.constructor.call(this, config);
    }
});

Baseliner.Topic.StorePriority = Ext.extend( Baseliner.JsonStore, {
    constructor: function(config) {
        config = Ext.apply({
            root: 'data' , 
            remoteSort: true,
            totalProperty:"totalCount", 
            url: '/topic/list_priority',
            fields: [ 
                {  name: 'id' },
                {  name: 'name' },
                {  name: 'response_time_min' },
                {  name: 'expr_response_time' },
                {  name: 'deadline_min' },
                {  name: 'expr_deadline' }          
            ]
        },config);
        Baseliner.Topic.StorePriority.superclass.constructor.call(this, config);
    }
});

Baseliner.Topic.comment_delete = function(id_com, id_div ) {
    Baseliner.ajaxEval( '/topic/comment/delete', { id_com: id_com }, function(res) {
        if( res.failure ) {
            Ext.Msg.alert( _('Error'), res.msg );
        } else {
            // no need to report anything
            // delete div if any
            try {
                var el = Ext.fly( id_div );
                if( el !== undefined ) {
                    el.fadeOut({ duration: .5, callback: function(e){ e.remove() } });
                }
            } catch(eee) { }
        }
    });
};

Baseliner.Topic.StoreUsers = Ext.extend( Baseliner.JsonStore, {
    constructor: function(config) {
        config = Ext.apply({
            root: 'data' , 
            remoteSort: true,
            totalProperty:"totalCount", 
            url: '/topic/list_users',
            fields: [ 
                {  name: 'id' },
                {  name: 'username' },
                {  name: 'realname' }
            ]
        },config);
        Baseliner.Topic.StoreUsers.superclass.constructor.call(this, config);
    }
});

//Baseliner.store.Topics = function(c) {
//     Baseliner.store.Topics.superclass.constructor.call(this, Ext.apply({
//        root: 'data' , 
//        remoteSort: true,
//        autoLoad: true,
//        totalProperty:"totalCount", 
//        baseParams: {},
//        id: 'mid', 
//        url: '/topic/related',
//        fields: ['mid','name', 'title','description','color'] 
//     }, c));
//};
//Ext.extend( Baseliner.store.Topics, Baseliner.JsonStore );

//Baseliner.model.Topics = function(c) {
//    //var tpl = new Ext.XTemplate( '<tpl for="."><div class="search-item {recordCls}">{name} - {title}</div></tpl>' );
//    var tpl_list = new Ext.XTemplate( '<tpl for="."><div class="x-combo-list-item">',
//        '<span id="boot" style="width:200px"><span class="badge" style="float:left;padding:2px 8px 2px 8px;background: {color}">{name}</span></span>',
//        '&nbsp;&nbsp;<b>{title}</b></div></tpl>' );
//    var tpl_field = new Ext.XTemplate( '<tpl for=".">',
//        '<span id="boot"><span class="badge" style="float:left;padding:2px 8px 2px 8px;background: {color}">{name}</span></span>',
//        '</tpl>' );
//    Baseliner.model.Topics.superclass.constructor.call(this, Ext.apply({
//        allowBlank: true,
//        msgTarget: 'under',
//        allowAddNewData: true,
//        addNewDataOnBlur: true, 
//        //emptyText: _('Enter or select topics'),
//        triggerAction: 'all',
//        resizable: true,
//        mode: 'local',
//        fieldLabel: _('Topics'),
//        typeAhead: true,
//            name: 'topics',
//            displayField: 'title',
//            hiddenName: 'topics',
//            valueField: 'mid',
//        tpl: tpl_list,
//        displayFieldTpl: tpl_field,
//        value: '/',
//        extraItemCls: 'x-tag'
//        /*
//        ,listeners: {
//            newitem: function(bs,v, f){
//                v = v.slice(0,1).toUpperCase() + v.slice(1).toLowerCase();
//                var newObj = {
//                    mid: v,
//                    title: v
//                };
//                bs.addItem(newObj);
//            }
//        }
//        */
//    }, c));
//};
//Ext.extend( Baseliner.model.Topics, Ext.ux.form.SuperBoxSelect );

Baseliner.TopicMain = Ext.extend( Ext.Panel, {
    initComponent: function(c){
        var self = this;
        var params = self;
        Ext.apply( this, c );
        
        self.view_is_dirty = false;
        self.form_is_loaded = false;
        self.ii = Ext.id();  // used by the detail page
        
        self.btn_form_ok = new Ext.Button({
            name: 'grabar',
            text: _('Save'),
            icon:'/static/images/icons/save.png',
            cls: 'x-btn-icon-text',
            type: 'submit',
            hidden: true,
            handler: function(){ return self.save_topic() }
        });
    
        // Detail Panel
        self.detail = new Ext.Panel({});
        
        Baseliner.Topic.file_del = function( topic_mid, md5, id_row ) {
            Baseliner.ajaxEval( '/topic/file/delete', { md5 : md5, topic_mid: topic_mid }, function(res) {
                if( res.success ) {
                    Baseliner.message( _('File'), res.msg );
                    Ext.fly( id_row ).remove();
                }
                else {
                    Ext.Msg.alert( _('Error'), res.msg );
                }
            });
        };
    
        // Form Panel
        var form_panel = new Ext.Panel({
            layout:'form',
            //autoHeight: true
            style: { padding: '15px' },
            defaults: {anchor:'80%' }
        });
    
        self._cis = [];
        self.load_form = function(rec) {
            if( rec._cis ) {
                self._cis = rec._cis;
            } else {
                rec._cis = self._cis;
            }
            rec.id_panel = self.id;
            Baseliner.ajaxEval( '/comp/topic/topic_form.js', rec, function(comp) {
                if( ! self.form_is_loaded ) {
                    //form_panel.removeAll();
                    self.form_topic = comp;
                    ////form_panel.add( comp );
                    //form_panel.doLayout();
                    self.add( self.form_topic );
                    self.getLayout().setActiveItem( self.form_topic );
                    self.form_is_loaded = true;
                }
    
                // now show/hide buttons
                self.btn_form_ok.show();
    
                if(params.topic_mid){
                    self.btn_comment.show();
                    //Baseliner.TopicExtension.toolbar.length > 0 ? self.btn_detail.hide(): self.btn_detail.show();
                    self.btn_detail.show();
                }else{
                    self.btn_comment.hide();
                    self.btn_detail.hide();
                }
            });            
        };
    
        
    

        var rg;
        var show_graph = function(){
            if( rg ) { rg.destroy(); rg=null }
            Baseliner.ajaxEval( '/ci/json_tree', { mid: params.topic_mid, does_any:['Project', 'Infrastructure','Topic'], direction:'children', depth:4 }, function(res){
                if( ! res.success ) { Baseliner.message( 'Error', res.msg ); return }
                rg = new Baseliner.JitRGraph({ json: res.data });
                self.add( rg );
                self.getLayout().setActiveItem( rg );
            });
        };
    
        Baseliner.show_topic = function(topic_mid, title) {
            Baseliner.add_tabcomp('/topic/view', title , { topic_mid: topic_mid, title: title } );
        };
    
        // if id_com is undefined, then its add, otherwise it's an edit
        Baseliner.Topic.comment_edit = function(topic_mid, id_com) {
            var win_comment;    
            var comment_field = new Baseliner.HtmlEditor({
                listeners: { 'initialize': function(){ comment_field.focus() } }
            });
            var btn_submit = {
                xtype: 'button',
                text: _('Add Comment'),
                handler: function(){
                    var text, content_type;
                    var id = cardcom.getLayout().activeItem.id;
                    if( id == comment_field.getId() ) {
                        text = comment_field.getValue();
                        content_type = 'html';
                    } else {
                        text = code.getValue();
                        content_type = 'code';
                    }
                    Baseliner.ajaxEval( '/topic/comment/add',
                        { topic_mid: topic_mid, id_com: id_com, text: text, content_type: content_type },
                        function(res) {
                           if( ! res.failure ) { 
                               Baseliner.message(_('Success'), res.msg );
                               win_comment.close();
                               self.detail_reload();
                           } else {
                                Ext.Msg.show({ 
                                    title: _('Information'),
                                    msg: res.msg , 
                                    buttons: Ext.Msg.OK, 
                                    icon: Ext.Msg.INFO
                                });                         
                            }
                         }
                    );
                }
            };
    
            var code_field = new Ext.form.TextArea({});
            var code;
    
            var btn_html = {
                xtype: 'button',
                text: _('HTML'),
                enableToggle: true, pressed: true, allowDepress: false, toggleGroup: 'comment_edit',
                handler: function(){
                    cardcom.getLayout().setActiveItem( 0 );
                }
            };
            var btn_code = {
                xtype: 'button',
                text: _('Code'),
                enableToggle: true, pressed: false, allowDepress: false, toggleGroup: 'comment_edit',
                handler: function(){
                    cardcom.getLayout().setActiveItem( 1 );
                    var com = code_field.getEl().dom;
                    code = CodeMirror(function(elt) {
                        com.parentNode.replaceChild( elt, com );
                    }, { 
                        value: comment_field.getValue(),
                        lineNumbers: true, tabMode: "indent", smartIndent: true, matchBrackets: true
                    });
                }
            };
            var cardcom = new Ext.Panel({ 
                layout: 'card', 
                activeItem: 0,
                items: [ comment_field, code_field ]
            });
    
            win_comment = new Ext.Window({
                title: _('Add Comment'),
                layout: 'fit',
                width: 700,
                closeAction: 'close',
                maximizable: true,
                autoHeight: true,
                bbar: [ 
                    btn_html,
                    btn_code, '->', btn_submit],
                items: cardcom
            });
            if( id_com !== undefined ) {
                Baseliner.ajaxEval('/topic/comment/view', { id_com: id_com }, function(res) {
                    if( res.failure ) {
                        Baseliner.message( _('Error'), res.msg );
                    } else {
                        comment_field.setValue( res.text );
                        win_comment.show();
                    }
                });
            } else {
                win_comment.show();
            }
        };
    
        self.btn_comment = new Ext.Toolbar.Button({
            text: _('Add Comment'),
            icon:'/static/images/icons/comment_new.gif',
            cls: 'x-btn-icon-text',
            handler: function() {
                Baseliner.Topic.comment_edit( params.topic_mid );
            }
        });
    
        self.btn_detail = new Ext.Toolbar.Button({
            icon:'/static/images/icons/detail.png',
            cls: 'x-btn-icon',
            enableToggle: true, pressed: true, allowDepress: false, handler: function(){ self.show_detail() }, toggleGroup: 'form'
        });
        
        self.btn_edit = new Ext.Toolbar.Button({
            name: 'edit',
            text:_('Edit'),
            icon:'/static/images/icons/edit.png',
            cls: 'x-btn-text-icon',
            enableToggle: true, handler: function(){ return self.show_form() }, allowDepress: false, toggleGroup: 'form'
        });
            
        self.btn_kanban = new Ext.Toolbar.Button({
            icon:'/static/images/icons/kanban.png',
            cls: 'x-btn-icon',
            enableToggle: true, handler: function(){self.show_kanban() }, allowDepress: false, toggleGroup: 'form'
        });
            
        self.btn_graph = new Ext.Toolbar.Button({
            icon:'/static/images/ci/ci-grey.png',
            cls: 'x-btn-icon',
            enableToggle: true, handler: show_graph, allowDepress: false, toggleGroup: 'form'
        });
            
        self.loading_panel = Baseliner.loading_panel();
    
        var tb;
        var typeToolBar = ''; //'GDI';
        
        tb = self.create_toolbar();

    
        self.detail.on( 'render', function() {
            if (self.topic_mid > 0) self.detail_reload();
            if( self.swEdit ) {
                if( !self.permEdit ) {
                    self.btn_edit.hide();
                } else {
                    self.btn_edit.toggle(true);
                    self.btn_detail.toggle(false);
                    self.show_form();        
                }
            }
        });
        
        if( !self.permEdit ) {
            self.btn_edit.hide();
        }
        
        //Baseliner.ajaxEval( '/topic/json', { topic_mid: params.topic_mid }, function(rec) {
        //    self.load_form( rec );
        //});
        
        self.tab_icon = '/static/images/icons/topic_one.png';
        if( ! params.title ) {
            self.setTitle("#" + params.topic_mid) 
        }
          
        Ext.apply(this, {
            layout: 'card',
            activeItem: 0,
            title: params.title,
            tbar: tb,
            //frame: true,
            padding: '15px 15px 15px 15px',
            defaults: {border: false},
            items: [ self.loading_panel, self.detail ]
        });
        Baseliner.TopicMain.superclass.initComponent.call(this);
    },
    show_form : function(){
        var self = this;
        self.getLayout().setActiveItem( self.loading_panel );
            if( self!==undefined && self.topic_mid !== undefined ) {
                
                var tabpanel = Ext.getCmp('main-panel');
                var panel = tabpanel.getActiveTab();
                var activeTabIndex = tabpanel.items.findIndex('id', panel.id );
                var id = panel.getId();
                var info = Baseliner.tabInfo[id];
                if( info!=undefined ) info.params.swEdit = 1;
                
                if (!self.form_is_loaded){
    
                    Baseliner.ajaxEval( '/topic/json', { topic_mid: self.topic_mid }, function(rec) {
                        self.load_form( rec );         
                    });
                }else{
                    self.getLayout().setActiveItem( self.form_topic );
    
                    self.btn_form_ok.show();
                    
                    if(self.topic_mid){
                        self.btn_comment.show();
                        self.btn_detail.show();
                    }else{
                        self.btn_comment.hide();
                        self.btn_detail.hide();
                    }                
                }
            } else {
                Baseliner.ajaxEval( '/topic/new_topic', { new_category_id: self.new_category_id, new_category_name: self.new_category_name, ci: self.ci, dni: self.dni, clonar: self.clonar}, function(rec) {
                    self.load_form( rec );
                });
            }
              
    },
    create_toolbar : function(){
        var self = this;
        var tb = new Ext.Toolbar({
            isFormField: true,
            items: [
                self.btn_detail,
                self.btn_edit,
                '-',
                self.btn_comment,
                self.btn_form_ok,
                '->',
                self.btn_kanban,
                self.btn_graph
            ]
        });
        return tb;
    },
    show_kanban: function(){
        var self = this;
        Baseliner.ajaxEval('/topic/children', { mid: self.topic_mid }, function(res){
            var topics = res.children;
            self.kanban = Baseliner.kanban({ topics: topics, background: '#888',
                on_tab: function(){
                    self.getLayout().setActiveItem( self.detail );
                    self.btn_detail.toggle( true );
                }
            });
            self.add( self.kanban );
            self.getLayout().setActiveItem( self.kanban );
        });
    },
    show_detail : function(){
        var self = this;
        self.getLayout().setActiveItem( self.detail );
        var tabpanel = Ext.getCmp('main-panel');
        var panel = tabpanel.getActiveTab();
        var activeTabIndex = tabpanel.items.findIndex('id', panel.id );
        var id = panel.getId();
        var info = Baseliner.tabInfo[id];
        if( info!=undefined ) info.params.swEdit = 0;        
        self.btn_form_ok.hide();
        if( self.view_is_dirty ) {
            self.view_is_dirty = false;
            self.detail_reload();
        }
    },
    detail_reload : function(){
        var self = this;
        self.detail.load({
            url: '/topic/view',
            params: { topic_mid: self.topic_mid, ii: self.ii, html: 1, categoryId: self.new_category_id },
            scripts: true,
            callback: function(x){ 
                // loading HTML has finished
                //   careful: errors here block will break js in baseliner
                if( ! self.swEdit ) {
                    var layout = self.getLayout().setActiveItem( self.detail );
                }
            }
        });
        self.detail.body.setStyle('overflow', 'auto');
    },
    save_topic : function(){
        var self = this;
        self.form_topic.on_submit();
        
        var form2 = self.form_topic.getForm();
        var action = form2.getValues()['topic_mid'] >= 0 ? 'update' : 'add';
        var custom_form = '';

        if (form2.isValid()) {
            form2.submit({
               params: {action: action, form: custom_form, _cis: Ext.util.JSON.encode( self._cis ) },
               success: function(f,a){
                    Baseliner.message(_('Success'), a.result.msg );
                    if( self._parent_grid != undefined && self._parent_grid.getStore()!=undefined ) {
                        self._parent_grid.getStore().reload();
                    }
                        
                    form2.findField("topic_mid").setValue(a.result.topic_mid);
                    form2.findField("status").setValue(a.result.topic_status);

                    var store = form2.findField("status_new").getStore();
                    store.on("load", function() {
                        form2.findField("status_new").setValue( a.result.topic_status );
                    });
                    store.load({
                        params:{    'categoryId': form2.findField("category").getValue(),
                                    'statusId': form2.findField("status").getValue(),
                                    'statusName': form2.findField("status_new").getRawValue()
                                }
                    });
                    
                    self.topic_mid = a.result.topic_mid;
                    self.btn_comment.show();
                    self.btn_detail.show();
                    
                    if(action == 'add'){
                        var tabpanel = Ext.getCmp('main-panel');
                        var objtab = tabpanel.getActiveTab();
                        var title = objtab.title + ' #' + a.result.topic_mid;
                        objtab.setTitle( title );
                        var info = Baseliner.panel_info( objtab );
                        info.params.topic_mid = a.result.topic_mid;
                        info.title = title;
                    }
                    self.view_is_dirty = true;
                        
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
});

