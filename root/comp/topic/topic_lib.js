Baseliner.Topic = {};
    
Baseliner.Topic.rt = Ext.data.Record.create([
    {name: 'id_project'},
    {name: 'project'}
]);

Baseliner.topic_category_class = {};

Baseliner.show_topic = function(topic_mid, title, params) {
    Baseliner.add_tabcomp('/topic/view', title , Ext.apply({ topic_mid: topic_mid, title: title }, params) );
};


Baseliner.topic_title = function( mid, category, color) {
    var uppers = category ? category.replace( /[^A-Z]/g, '' ) : '';
    return color 
        ? String.format( '<span id="boot" style="background:transparent"><span class="label" style="background-color:{1}">{2} #{0}</span></span>', mid, color, uppers )
        : String.format( '<span id="boot" style="background:transparent"><span class="label" style="background-color:{2}">{0} #{1}</span></span>', uppers, mid, color )
        ;
}

Baseliner.show_topic_colored = function(mid, category, color, grid_id) {
    var title = Baseliner.topic_title( mid, _(category), color );
    Baseliner.show_topic( mid, title, { topic_mid: mid, title: title, _parent_grid: grid_id } );
    //Baseliner.add_tabcomp('/topic/view?topic_mid=' + r.get('topic_mid') + '&app=' + typeApplication , title ,  );
}

Baseliner.show_topic_from_row = function(r, grid) {
    var title = Baseliner.topic_title( r.get('topic_mid'), _(r.get( 'category_name' )), r.get('category_color') );
    Baseliner.show_topic( r.data.topic_mid, title, { topic_mid: r.get('topic_mid'), title: title, _parent_grid: grid } );
    //Baseliner.add_tabcomp('/topic/view?topic_mid=' + r.get('topic_mid') + '&app=' + typeApplication , title ,  );
}

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
                {  name: 'moniker' },
                {  name: 'cis_in' },
                {  name: 'cis_out' },
                {  name: 'references' },
                {  name: 'referenced_in' },
                {  name: 'sw_edit'},
                {  name: 'modified_on', type: 'date', dateFormat: 'c' },        
                {  name: 'modified_by' }
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
            Baseliner.message( _('Error'), res.msg );
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
        self.detail = new Ext.Panel({ 
            layout:'fit'
        });
        
        Baseliner.Topic.file_del = function( topic_mid, md5, id_row ) {
            Baseliner.ajaxEval( '/topic/file/delete', { md5 : md5, topic_mid: topic_mid }, function(res) {
                if( res.success ) {
                    Baseliner.message( _('File'), res.msg );
                    Ext.fly( id_row ).remove();
                }
                else {
                    Baseliner.message( _('Error'), res.msg );
                }
            });
        };
    
        self._cis = [];
        var rg;
        var show_graph = function(){
            if( rg ) { rg.destroy(); rg=null }
            //Baseliner.ajaxEval( '/ci/json_tree', { mid: params.topic_mid, does_any:['Project', 'Infrastructure','Topic'], direction:'children', depth:4 }, function(res){
            Baseliner.ajaxEval( '/ci/json_tree', { mid: params.topic_mid, direction:'related', depth:2 }, function(res){
                if( ! res.success ) { Baseliner.message( 'Error', res.msg ); return }
                rg = new Baseliner.JitRGraph({ json: res.data });
                self.add( rg );
                self.getLayout().setActiveItem( rg );
            });
        };
    
        // if id_com is undefined, then its add, otherwise it's an edit
        Baseliner.Topic.comment_edit = function(topic_mid, id_com) {
            var win_comment;    
            //var comment_field = new Baseliner.MultiEditor({
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
                               Baseliner.message( _('Error'), res.msg );
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
                height: 450,
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
            enableToggle: true, pressed: true, allowDepress: false, 
            handler: function(){ self.show_detail() }, 
            toggleGroup: 'form'
        });
        
        self.btn_edit = new Ext.Toolbar.Button({
            name: 'edit',
            text:_('Edit'),
            icon:'/static/images/icons/edit.png',
            cls: 'x-btn-text-icon',
            enableToggle: true, 
            handler: function(){ return self.show_form() }, 
            allowDepress: false, toggleGroup: 'form'
        });
            
        self.btn_kanban = new Ext.Toolbar.Button({
            icon:'/static/images/icons/kanban.png',
            cls: 'x-btn-icon',
            enableToggle: true, 
            handler: function(){ self.show_kanban() }, 
            allowDepress: false, toggleGroup: 'form'
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
            if (self.topic_mid > 0 && !self.activarEdit) {
                self.detail_reload();
            }

            if( self.swEdit ) {
                if( !self.permEdit ) {
                    self.btn_edit.hide();
                } else {
                    self.btn_edit.toggle(true);
                    self.btn_detail.toggle(false);
                    self.show_form();
                    if (self.activarEdit) self.view_is_dirty = true;
                }
            }
        });
        
        if( !self.permEdit ) {
            self.btn_edit.hide();
        }
        
        //self.tab_icon = '/static/images/icons/topic_one.png';
        if( ! params.title ) {
            self.setTitle( Baseliner.topic_title( params.topic_mid, params.category, params.category_color ) ) 
        }
          
        Ext.apply(this, {
            layout: 'card',
            activeItem: 0,
            title: params.title,
            tbar: tb,
            autoScroll: true,
            //frame: true,
            padding: '15px 15px 15px 15px',
            defaults: {border: false},
            items: [ self.loading_panel, self.detail ]
        });
        Baseliner.TopicMain.superclass.initComponent.call(this);
    },
    load_form : function(rec) {
        var self = this;
        rec.html_buttons = self.html_buttons;
        if( rec._cis ) {
            self._cis = rec._cis;
        } else {
            rec._cis = self._cis;
        }
        rec.id_panel = self.id;
        Baseliner.ajaxEval( '/comp/topic/topic_form.js', rec, function(comp) {
            if( ! self.form_is_loaded ) {
                self.form_topic = comp;
                self.add( self.form_topic );
                self.getLayout().setActiveItem( self.form_topic );
                self.form_is_loaded = true;
            }

            // now show/hide buttons
            self.btn_form_ok.show();

            if(self.topic_mid){
                self.btn_comment.show();
                //Baseliner.TopicExtension.toolbar.length > 0 ? self.btn_detail.hide(): self.btn_detail.show();
                self.btn_detail.show();
            }else{
                self.btn_comment.hide();
                self.btn_detail.hide();
            }
        });            
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
                    if( rec.success ) {
                        self.load_form( rec );
                    } else {
                        Baseliner.error( _('Error'), rec.msg );
                        self.destroy();
                    }
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
                //   careful: errors here will break js in baseliner
                if( ! self.swEdit ) {
                    var layout = self.getLayout().setActiveItem( self.detail );
                }
                self.detail.body.parent().setStyle('width', null);
                self.detail.body.parent().parent().setStyle('width', null);
                self.detail.body.setStyle('width', null);
                self.detail.body.setStyle('height', null);
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
                    if( self._parent_grid != undefined && ! Ext.isObject( self._parent_grid ) ) {
                        self._parent_grid = Ext.getCmp( self._parent_grid ); 
                    }
                    if( Ext.isObject( self._parent_grid )  && self._parent_grid.getStore()!=undefined ) {
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
                   Baseliner.message( _('Error'), a.result.msg );
               }
            });
        }        
    }
});

Baseliner.TopicCombo = Ext.extend( Ext.form.ComboBox, {
    minChars: 2,
    name: 'topic',
    displayField: 'name',
    hiddenName: 'topic',
    valueField: 'mid',
    msgTarget: 'under',
    forceSelection: true,
    typeAhead: false,
    loadingText: _('Searching...'),
    resizable: true,
    allowBlank: false,
    lazyRender: false,
    pageSize: 20,
    triggerAction: 'all',
    itemSelector: 'div.search-item',
    initComponent: function(){
        var self = this;
        self.listeners = {
            beforequery: function(qe){
                delete qe.combo.lastQuery;
            }
        };
        //self.xxtpl = new Ext.XTemplate( '<tpl for="."><div class="search-item">{name} {title}</div></tpl>');
        self.tpl = new Ext.XTemplate( '<tpl for="."><div class="search-item">',
            '<span id="boot" style="width:200px"><span class="badge" ', 
            ' style="float:left;padding:2px 8px 2px 8px;background: {color}"',
            ' >{name}</span></span>',
            '&nbsp;&nbsp;<b>{title}</b></div></tpl>' );
        //self.xdisplayFieldTpl = new Ext.XTemplate( '<tpl for=".">',
        //    '<span id="boot"><span class="badge" style="float:left;padding:2px 8px 2px 8px;background: {color}; cursor:pointer;"',
        //    ' onclick="javascript:Baseliner.show_topic({mid}, \'{name}\');">{name}</span></span>',
        //    '</tpl>' );
        Baseliner.TopicCombo.superclass.initComponent.call(this);
    }
});

Baseliner.TopicGrid = Ext.extend( Ext.grid.GridPanel, {
    height: 200,
    initComponent: function(){
        var self = this;
        self.combo_store = self.combo_store || new Baseliner.store.Topics({});
        if( self.topic_grid == undefined ) self.topic_grid = {};
  
        self.combo = new Baseliner.TopicCombo({
            store: self.combo_store, 
            width: 600,
            height: 80,
            singleMode: true, 
            fieldLabel: _('Topic'),
            name: 'topic',
            hiddenName: 'topic', 
            allowBlank: true
        }); 

        self.combo.on('beforequery', function(qe){
            delete qe.combo.lastQuery;
        });
        self.field = new Ext.form.Hidden({ name: self.name, value: self.value });
        var btn_delete = new Baseliner.Grid.Buttons.Delete({
            disabled: false,
            handler: function() {
                var sm = self.getSelectionModel();
                if (sm.hasSelection()) {
                    Ext.each( sm.getSelections(), function( sel ){
                        self.getStore().remove( sel );
                    });
                    self.refresh_field();
                } else {
                    Baseliner.message( _('ERROR'), _('Select at least one row'));    
                };                
            }
        });
        var btn_reload = new Ext.Button({
            icon: '/static/images/icons/refresh.gif',
            handler: function(){ self.refresh() }
        });
        self.tbar = [ self.field, self.combo, btn_reload, btn_delete ];
        self.combo.on('select', function(combo,rec,ix) {
            self.add_to_grid( rec.data );
        });
        self.viewConfig = {
            headersDisabled: true,
            enableRowBody: true,
            forceFit: true
        };
        self.sm = new Baseliner.CheckboxSelectionModel({
            checkOnly: true,
            singleSelect:false
        });

        var render_text_field = function(v){
            if( !v ) v ='';
            return '<pre>'+v+'</pre>';
        };
        
        var cols = [ self.sm ];
        var store_fields = ['mid'];
        var cols_keys = ['name', 'title'];
        var cols_templates = {
            mid: { header:_('id'), dataindex:'mid', hidden: true },
            name: { header:_('Name'), dataindex:'name', renderer: self.render_topic_name },
            title: { header:_('Title'), dataindex:'title' },
            status: { header:_('Status'), dataindex:'name_status', renderer: Baseliner.render_status }
        };
        var col_prefs = Ext.isArray( self.columns ) ? self.columns : Ext.isString(self.columns) ? self.columns.split(';') : [];
        if( col_prefs.length > 0 ) {
            // from get_topics, which puts a lot of values
            Ext.each( col_prefs, function(ck){
                if( Ext.isObject( ck ) ) {
                    cols.push( ck );
                    store_fields.push( ck.dataindex );
                } else {
                    var ct = cols_templates[ ck ];
                    if( ct ) {
                        store_fields.push( ck );
                        cols.push( ct );
                    } else {
                        store_fields.push( ck );
                        ct = { header:_(ck), dataindex: ck, renderer: render_text_field };
                        cols.push( ct );
                    }
                }
            });
        } else {
            // use the default columns
            Ext.each( cols_keys, function(ck){
                var ct = cols_templates[ ck ];
                if( ct ) {
                    cols.push( ct.dataindex );
                    store_fields.push( ck );
                }
            });
        }
        //self.on('rowclick', function(grid, rowIndex, e) { btn_delete.enable(); });		
        self.columns = cols;

        self.store = new Ext.data.SimpleStore({
            fields: store_fields,
            data: []
        });
        
        self.refresh(true);
        self.on("rowdblclick", function(grid, rowIndex, e ) {
            var r = grid.getStore().getAt(rowIndex);
            var title = Baseliner.topic_title( r.get('mid'), _(r.get( 'categories' ).name), r.get('color') );
            Baseliner.show_topic( r.get('mid'), title, { topic_mid: r.get('mid'), title: title, _parent_grid: undefined } );
            
        });        
        Baseliner.TopicGrid.superclass.initComponent.call( this );
    },
    refresh : function(initial){
        var self = this;
        var val = self.value;
        if( initial ) {
            if( Ext.isArray( val ) ) {
                // self.value may be an array of full records or just mids, try to detect it 
                var mids = [];
                Ext.each( val, function(r){
                    if( Ext.isObject( r ) ) {
                        self.add_to_grid( r );
                    } else {
                        mids.push( r );
                    }
                });

                if( mids.length > 0 ) {
                    var p = { mids: mids };
                    Baseliner.ajaxEval( '/topic/related', Ext.apply(self.topic_grid, p ), function(res){
                        Ext.each( res.data, function(r){
                            if( ! r ) return;
                            self.add_to_grid( r );
                        });
                    });
                }
            }        
        } else {
            // we have data in the grid, reload
            var mids = [];
            self.store.each( function(row){
                mids.push( row.data.mid ); 
            });
            if( mids.length == 0 ) return;
            var p = { mids: mids, topic_child_data : true };
            Baseliner.ajaxEval( '/topic/related', Ext.apply(self.topic_grid, p ), function(res){
                self.store.removeAll();
                Ext.each( res.data, function(r){
                    if( ! r ) return;
                    self.add_to_grid( r );
                });
            });
        }
    },
    refresh_field: function(){
        var self = this;
        var mids = [];
        self.store.each(function(row){
            mids.push( row.data.mid ); 
        });
        self.field.setValue( mids.join(',') );
    },
    add_to_grid: function(rec){
        var self = this;
        var f = self.store.find( 'mid', rec.mid );
        if( f != -1 ) {
            Baseliner.warning( _('Warning'), _('Row already exists: %1', rec.name + '(' + rec.mid + ')' ) );
            return;
        }
        var r = new self.store.recordType( rec );
        self.store.add( r );
        self.store.commitChanges();
        self.refresh_field();
    },
    render_topic_name: function(value,metadata,rec,rowIndex,colIndex,store){
        var d = rec.data;
        var category_name;

        if(!d.categories){
            var category = d.name.split('#');
            category_name = category[0];
        }else{
            category_name = d.categories.name;
        }
        return String.format('<a href="#" onclick="javascript:Baseliner.show_topic_colored({0},\'{1}\',\'{2}\');return false;">{3}</a>',
            d.mid,
            category_name,
            d.color,
            Baseliner.topic_name({
                mid: d.mid, 
                mini: true,
                size: true ? '9' : '11',
                category_name: category_name,
                category_color:  d.color//,
                //category_icon: d.category_icon,
                //is_changeset: d.is_changeset,
                //is_release: d.is_release
            }) );
    }    
});

