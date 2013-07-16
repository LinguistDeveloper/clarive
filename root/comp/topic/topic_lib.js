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

/*
    parameters:
         {
            mid:
            category_name:
            category_color: 
            category_icon:
            is_changeset: 1|0
            is_release: 1|0
         }
*/
Baseliner.topic_name = function(args) {
        var mid = args.mid; //Cambiarlo en un futuro por un contador de categorias
        if( ! mid ) 
            mid = args.topic_mid; 
        if( mid )
            mid = '#' + mid;
        else
		    mid = '';
        var cat_name = _(args.category_name); //Cambiarlo en un futuro por un contador de categorias
        if( cat_name )
            cat_name = cat_name + ' ';
        else
            cat_name = ''
        var color = args.category_color;
        var cls = 'label';
        var icon = args.category_icon;
        var size = args.size ? args.size : '10';

        var top,bot,img;
        top=2, bot=4, img=2;

        if( ! color ) 
            color = '#999';

        // set default icons
        if( icon==undefined ) {
            if( args.is_changeset > 0  ) {
                icon = '/static/images/icons/package-white.png';
            }
            else if( args.is_release > 0  ) {
                icon = '/static/images/icons/release-white.png';
            }
        }

        // prepare icon background
        var style_str;
        if( icon && ! args.mini ) {
            style_str = "padding:{2}px 8px {3}px 18px;background: {0} url('{1}') no-repeat left {4}px; font-size: {5}px";
        }
        else {
            style_str = "padding:{2}px 8px {3}px 8px;background-color: {0}; font-size: {5}px";
        }
        var style = String.format( style_str, color, icon, top, bot, img, size );
        //if( color == undefined ) color = '#777';
        var on_click = args.link ? String.format('javascript:Baseliner.show_topic_colored({0},"{1}", "{2}", "{3}");', args.mid, cat_name, color, args.parent_id ) : '';  
        var cursor = args.link ? 'cursor:pointer' : '';

        var ret = args.mini 
            ? String.format('<span id="boot" onclick=\'{4}\' style="{5};background: transparent" ><span class="{0}" style="{5};{1};padding: 1px 1px 1px 1px; margin: 0px 4px -10px 0px;border-radius:0px">&nbsp;</span><span style="{5};font-weight:bolder;font-size:11px">{2}{3}</span></span>', 
                cls, [style,args.style].join(';'), cat_name, mid, on_click, cursor )
            : String.format('<span id="boot" onclick=\'{4}\'><span class="{0}" style="{1};{5}">{2}{3}</span></span>', 
                cls, [style,args.style].join(';'), cat_name, mid, on_click, cursor );
        return ret;
};

Baseliner.store.Topics = function(c) {
     Baseliner.store.Topics.superclass.constructor.call(this, Ext.apply({
        root: 'data' , 
        remoteSort: true,
        autoLoad: true,
        totalProperty:"totalCount", 
        baseParams: {},
        id: 'mid', 
        url: '/topic/related',
        fields: ['mid','name', 'title','description','color'] 
     }, c));
};
Ext.extend( Baseliner.store.Topics, Baseliner.JsonStore );

Baseliner.TopicBox = Ext.extend( Ext.ux.form.SuperBoxSelect, {
    minChars: 2,
    //forceSelection: true,
    typeAhead: false,
    loadingText: _('Searching...'),
    resizable: true,
    allowBlank: true,
    lazyRender: false,
    triggerAction: 'all',
    pageSize: 20,
    msgTarget: 'under',
    emptyText: _('Select a topic'),
    fieldLabel: _('Projects'),
    name: 'projects',
    displayField: 'name',
    hiddenName: 'projects',
    valueField: 'mid',
    extraItemCls: 'x-tag',
    initComponent: function(){
        var self = this;
        self.tpl = new Ext.XTemplate( '<tpl for="."><div class="x-combo-list-item">',
            '<span id="boot" style="width:200px"><span class="label" ', 
            ' style="float:left;padding:2px 8px 2px 8px;background: {color}"',
            ' >{name}</span></span>',
            '&nbsp;&nbsp;<b>{title}</b></div></tpl>' );
        self.displayFieldTpl = new Ext.XTemplate( '<tpl for=".">',
            '<span id="boot" style="background:transparent; margin-right: 8px"><span class="label" style="float:left;padding:2px 8px 2px 8px;background: {color}; cursor:pointer;margin-right: 8px"',
            ' onclick="javascript:Baseliner.show_topic_colored({mid}, \'{name}\', \'{color}\');">{name}</span>{title}</span>',
            '</tpl>' );
        Baseliner.TopicBox.superclass.initComponent.call(this);
    }
});

//
// XXX **************** WARNING Baseliner.model.Topics is deprecated. Use TopicBox instead
//
Baseliner.model.Topics = function(c) {
    //var tpl = new Ext.XTemplate( '<tpl for="."><div class="search-item {recordCls}">{name} - {title}</div></tpl>' );
    var tpl_list = new Ext.XTemplate( '<tpl for="."><div class="x-combo-list-item">',
        '<span id="boot" style="width:200px"><span class="label" ', 
        ' style="float:left;padding:2px 8px 2px 8px;background: {color}"',
        ' >{name}</span></span>',
        '&nbsp;&nbsp;<b>{title}</b></div></tpl>' );
    var tpl_field = new Ext.XTemplate( '<tpl for=".">',
        '<span id="boot" style="background:transparent; margin-right: 8px"><span class="label" style="float:left;padding:2px 8px 2px 8px;background: {color}; cursor:pointer;margin-right: 8px"',
        ' onclick="javascript:Baseliner.show_topic_colored({mid}, \'{name}\', \'{color}\');">{name}</span>{title}</span>',
        '</tpl>' );
    Baseliner.model.Topics.superclass.constructor.call(this, Ext.apply({
        allowBlank: true,
        msgTarget: 'under',
        allowAddNewData: true,
        addNewDataOnBlur: true, 
        //emptyText: _('Enter or select topics'),
        triggerAction: 'all',
        resizable: true,
        mode: 'local',
        fieldLabel: _('Topics'),
        typeAhead: true,
            name: 'topics',
            displayField: 'title',
            hiddenName: 'topics',
            valueField: 'mid',
        tpl: tpl_list,
        displayFieldTpl: tpl_field,
        extraItemCls: 'x-tag'
        /*
        ,listeners: {
            newitem: function(bs,v, f){
                v = v.slice(0,1).toUpperCase() + v.slice(1).toLowerCase();
                var newObj = {
                    mid: v,
                    title: v
                };
                bs.addItem(newObj);
            }
        }
        */
    }, c));
};
Ext.extend( Baseliner.model.Topics, Ext.ux.form.SuperBoxSelect );

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
                {  name: 'references_out' },
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

// if id_com is undefined, then its add, otherwise it's an edit
Baseliner.Topic.comment_edit = function(topic_mid, id_com, cb) {
    var win_comment;    
    //var comment_field = new Baseliner.MultiEditor
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
                       if( Ext.isFunction(cb) ) cb( res.id_com );
                   } else {
                       Baseliner.error( _('Error'), res.msg );
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
        enableToggle: true, pressed: true, allowDepress: false, toggleGroup: 'comment_edit_' + self.ii,
        handler: function(){
            cardcom.getLayout().setActiveItem( 0 );
        }
    };
    var btn_code = {
        xtype: 'button',
        text: _('Code'),
        enableToggle: true, pressed: false, allowDepress: false, toggleGroup: 'comment_edit_' + self.ii,
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
    if( id_com != undefined ) {
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

Baseliner.TopicMain = Ext.extend( Ext.Panel, {
    initComponent: function(c){
        var self = this;
        var params = self;
        Ext.apply( this, c );
        
        self.view_is_dirty = false;
        self.form_is_loaded = false;
        self.ii = Ext.id();  // used by the detail page
        self.toggle_group = 'form_btns_' + self.ii;

        self.btn_save_form = new Ext.Button({
            text: _('Save'),
            icon:'/static/images/icons/save.png',
            cls: 'x-btn-icon-text',
            type: 'submit',
            hidden: true,
            handler: function(){ return self.save_topic() }
        });
    
        self.btn_delete_form = new Ext.Button({
            text: _('Delete'),
            icon:'/static/images/icons/delete.gif',
            cls: 'x-btn-icon-text',
            type: 'submit',
            hidden: self.topic_mid!=undefined ? false : true,
            handler: function(){ return self.delete_topic() }
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
    
    
        self.btn_comment = new Ext.Toolbar.Button({
            text: _('Add Comment'),
            icon:'/static/images/icons/comment_new.gif',
            cls: 'x-btn-icon-text',
            handler: function() {
                Baseliner.Topic.comment_edit( params.topic_mid, null, function(id_com){ self.detail_reload() });
            }
        });
    
        self.btn_detail = new Ext.Toolbar.Button({
            icon:'/static/images/icons/detail.png',
            cls: 'x-btn-icon',
            enableToggle: true, pressed: true, allowDepress: false, 
            handler: function(){ self.show_detail() }, 
            toggleGroup: self.toggle_group
        });
        
        self.btn_edit = new Ext.Toolbar.Button({
            name: 'edit',
            text:_('Edit'),
            icon:'/static/images/icons/edit.png',
            cls: 'x-btn-text-icon',
            enableToggle: true, 
            handler: function(){ return self.show_form() }, 
            allowDepress: false, toggleGroup: self.toggle_group
        });
            
        self.btn_kanban = new Ext.Toolbar.Button({
            icon:'/static/images/icons/kanban.png',
            cls: 'x-btn-icon',
            enableToggle: true, 
            handler: function(){ self.show_kanban() }, 
            allowDepress: false, toggleGroup: self.toggle_group
        });
            
        self.btn_graph = new Ext.Toolbar.Button({
            icon:'/static/images/ci/ci-grey.png',
            cls: 'x-btn-icon',
            enableToggle: true, handler: show_graph, allowDepress: false, toggleGroup: self.toggle_group
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
                    self.btn_delete_form.hide();
                } else {
                    self.btn_edit.toggle(true);
                    self.btn_detail.toggle(false);
                    self.btn_delete_form.show();
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

        self.form_topic = new Baseliner.TopicForm({ rec: rec, main: self });
        
        if( ! self.form_is_loaded ) {
            self.add( self.form_topic );
            self.getLayout().setActiveItem( self.form_topic );
            self.form_is_loaded = true;
        }

        // now show/hide buttons
        self.btn_save_form.show();

        if(self.topic_mid){
            self.btn_comment.show();
            //Baseliner.TopicExtension.toolbar.length > 0 ? self.btn_detail.hide(): self.btn_detail.show();
            self.btn_detail.show();
            self.btn_delete_form.show();
        }else{
            self.btn_comment.hide();
            self.btn_detail.hide();
            self.btn_delete_form.hide();
        }
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

                Baseliner.ajaxEval( '/topic/json', { topic_mid: self.topic_mid, topic_child_data : true }, function(rec) {
                    self.load_form( rec );         
                });
            }else{
                self.getLayout().setActiveItem( self.form_topic );

                self.btn_save_form.show();
                
                if(self.topic_mid){
                    self.btn_comment.show();
                    self.btn_detail.show();
                    self.btn_delete_form.show();
                }else{
                    self.btn_comment.hide();
                    self.btn_detail.hide();
                    self.btn_delete_form.hide();
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
                self.btn_delete_form,
                self.btn_save_form,
                '->',
                self.btn_kanban,
                self.btn_graph
            ]
        });
        return tb;
    },
    show_kanban: function(){
        var self = this;
        Baseliner.ajaxEval('/topic/children', { mid: self.topic_mid, _whoami: 'show_kanban' }, function(res){
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
        self.btn_save_form.hide();
        if( self.view_is_dirty ) {
            self.view_is_dirty = false;
            self.detail_reload();
        }
    },
    detail_reload : function(){
        var self = this;
        self.detail.load({
            url: '/topic/view',
            params: { topic_mid: self.topic_mid, ii: self.ii, html: 1, categoryId: self.new_category_id, topic_child_data : true },
            scripts: true,
            callback: function(x, success, res){ 
                if( !success ) {
                    self.detail.update( res.responseText );
                    var layout = self.getLayout().setActiveItem( self.detail );
                } else {
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
            }
        });
        self.detail.body.setStyle('overflow', 'auto');
    },
    save_topic : function(opts){
        var self = this;
        self.form_topic.on_submit();
        if( !opts ) opts = {};
        
        var form2 = self.form_topic.getForm();
        var action = form2.getValues()['topic_mid'] >= 0 ? 'update' : 'add';
        var custom_form = '';

        if (form2.isValid()) {
            self.btn_save_form.disable();
            self.btn_delete_form.disable();
            form2.submit({
               url: self.form_topic.url,
               params: {action: action, form: custom_form, _cis: Ext.util.JSON.encode( self._cis ) },
               success: function(f,a){
                    self.btn_save_form.enable();
                    self.btn_delete_form.enable();
                    Baseliner.message(_('Success'), a.result.msg );
                    self.reload_parent_grid();
                        
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
                    self.btn_delete_form.show();
                    
                    if(action == 'add'){
                        var res = a.result;
                        var tabpanel = Ext.getCmp('main-panel');
                        var objtab = tabpanel.getActiveTab();
                        var category = res.category;
                        var title = Baseliner.topic_title( res.topic_mid, category.name, category.color );
                        //objtab.setTitle( title );
                        var info = Baseliner.panel_info( objtab );
                        info.params.topic_mid = res.topic_mid;
                        info.title = title;
                        self.setTitle( title );    
                    }
                    self.view_is_dirty = true;
                    if( Ext.isFunction(opts.success) ) opts.success(a.result);
               },
               failure: function(f,action){
                   self.btn_save_form.enable();
                   self.btn_delete_form.enable();
                   var res = action.response;
                   Baseliner.error_win('',{},res,res.responseText );
                   if( Ext.isFunction(opts.failure) ) opts.failure(res);
               }
            });
        }        
    },
    delete_topic : function(){
        var self = this;
        if( self.topic_mid == undefined ) return;
        Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the topic?'),
            function(btn){ 
                if(btn=='yes') {
                    Baseliner.Topic.delete_topic({ topic_mids: self.topic_mid, success:function(){ 
                        self.reload_parent_grid();
                        self.destroy();
                    }});
                }
            }
        );
    },
    reload_parent_grid : function(){
        var self = this;
        if( self._parent_grid != undefined && ! Ext.isObject( self._parent_grid ) ) {
            self._parent_grid = Ext.getCmp( self._parent_grid ); 
        }
        if( Ext.isObject( self._parent_grid )  && self._parent_grid.getStore()!=undefined ) {
            self._parent_grid.getStore().reload();
        }
    }
});

Baseliner.Topic.delete_topic = function(opts){
    Baseliner.ajaxEval( '/topic/update?action=delete',{ topic_mid: opts.topic_mids },
        function(res) {
            if ( res.success ) {
                Baseliner.message( _('Success'), res.msg );
                if( Ext.isFunction(opts.success) ) opts.success(res);
            } else {
                Baseliner.error( _('Error'), res.msg );
                if( Ext.isFunction(opts.failure) ) opts.failure(res);
            }
        }
    
    );
};

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
    pageSize: true,
    triggerAction: 'all',
    itemSelector: 'div.search-item',
    initComponent: function(){
        var self = this;
        self.listeners = {
            beforequery: function(qe){
                delete qe.combo.lastQuery;
            }
        };
        self.tpl = new Ext.XTemplate( '<tpl for="."><div class="search-item">',
            '<span id="boot" style="width:200px"><span class="label" ', 
            ' style="float:left;padding:2px 8px 2px 8px;background: {color}"',
            ' >{name}</span></span>',
            '&nbsp;&nbsp;<b>{title}</b></div></tpl>' );
        Baseliner.TopicCombo.superclass.initComponent.call(this);
    }
});

Baseliner.TopicGrid = Ext.extend( Ext.grid.GridPanel, {
    height: 200,
    enableDragDrop: true,   
    pageSize: 10, // used by the combo 
    constructor: function(c){  // needs to declare the selection model in a constructor, otherwise incompatible with DD
        var sm = new Baseliner.CheckboxSelectionModel({
            checkOnly: true,
            singleSelect: false
        });
        
        var render_text_field = function(v){
            if( !v ) v ='';
            return '<pre>'+v+'</pre>';
        };
        
        var cols = [ sm ];
        var store_fields = ['mid'];
        var cols_keys = ['name', 'title'];
        var cols_templates = {
            mid: { header:_('id'), dataindex:'mid', hidden: true },
            name: { header:_('Name'), dataindex:'name', width: 80, renderer: this.render_topic_name },
            title: { header:_('Title'), dataindex:'title', renderer: function(v){ return '<b>'+v+'</b>'; } },
            name_status: { header:_('Status'), dataindex:'name_status', width: 80, renderer: Baseliner.render_status }
        };
        var col_prefs = Ext.isArray( c.columns ) ? c.columns : Ext.isString(c.columns) ? c.columns.split(';') : [];
        if( col_prefs.length > 0 ) {
            // from get_topics, which puts a lot of values
            Ext.each( col_prefs, function(ck){
                if( Ext.isObject( ck ) ) {
                    // user sent me a complete column object
                    cols.push( ck );
                    store_fields.push( ck.dataindex );
                } else {
                    // we have a col template string key
                    var ct = cols_templates[ ck ];
                    if( ct ) {
                        // ok, field is in templates
                        store_fields.push( ck );
                        cols.push( ct );
                    } else {
                        // if we dont have the field, create a text column with it
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
                    cols.push( ct );
                    store_fields.push( ck );
                }
            });
        }
        delete c['columns'];

        var store = new Ext.data.SimpleStore({
            fields: store_fields,
            data: []
        });

        Baseliner.TopicGrid.superclass.constructor.call( this, Ext.apply({
            store: store,
            viewConfig: {
                headersDisabled: true,
                enableRowBody: true,
                forceFit: true
            },
            columns: cols
        },c) );
    },
    initComponent: function(){
        var self = this;
        self.combo_store = self.combo_store || new Baseliner.store.Topics({});
        if( self.topic_grid == undefined ) self.topic_grid = {};
        self.combo = new Baseliner.TopicCombo({
            store: self.combo_store, 
            width: 600,
            height: 80,
            pageSize: self.pageSize,
            singleMode: true, 
            fieldLabel: _('Topic'),
            name: 'topic',
            hiddenName: 'topic', 
            allowBlank: true
        }); 
        self.combo.on('beforequery', function(qe){ delete qe.combo.lastQuery });
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
        self.ddGroup = 'bali-topic-grid-data-' + self.id;
        
        self.refresh(true);
        self.on("rowdblclick", function(grid, rowIndex, e ) {
            var r = grid.getStore().getAt(rowIndex);
            var title = Baseliner.topic_title( r.get('mid'), _(r.get( 'categories' ).name), r.get('color') );
            Baseliner.show_topic( r.get('mid'), title, { topic_mid: r.get('mid'), title: title, _parent_grid: undefined } );
            
        });        
        self.on('afterrender', function(){
            var ddrow = new Baseliner.DropTarget(self.container, {
                comp: self,
                ddGroup : self.ddGroup,
                copy: false,
                notifyDrop : function(dd, e, data){
                    var ds = self.store;
                    var sm = self.getSelectionModel();
                    var rows = sm.getSelections();
                    if(dd.getDragData(e)) {
                        var cindex=dd.getDragData(e).rowIndex;
                        if(typeof(cindex) != "undefined") {
                            for(i = 0; i <  rows.length; i++) {
                                ds.remove(ds.getById(rows[i].id));
                            }
                            ds.insert(cindex,data.selections);
                            sm.clearSelections();
                        }
                        self.refresh_field();
                    }
                }
            }); 
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
                    var p = { mids: mids, topic_child_data : true, _whoami: 'TopicGrid.refresh1' };
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
            var p = { mids: mids, topic_child_data : true, _whoami: 'TopicGrid.refresh2' };
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

Baseliner.TopicForm = Ext.extend( Ext.FormPanel, {
    layout:'column',
    url:'/topic/update',
    autoHeight: true,
    overflow: 'hidden',
    form_columns: 12,
    //layout:'table',
    //layoutConfig: { columns: form_columns },
    //cls: 'bali-form-table',
    initComponent: function(){
        var self = this;
        var rec = self.rec;

        var form_is_loaded = false;
        var data = rec.topic_data;
        if( data == undefined ) data = {};
        var on_submit_events = [];
        
        var unique_id_form = Ext.getCmp('main-panel').getActiveTab().id + '_form_topic';
        
        Ext.form.Action.prototype.constructor = Ext.form.Action.prototype.constructor.createSequence(function() {
            Ext.applyIf(this.options, {
                submitEmptyText: false
            });
        });

        Ext.apply(this, {
            id: unique_id_form,
            bodyStyle: {
              'padding': '5px 50px 5px 10px'
            },
            items: [
                { xtype: 'hidden', name: 'topic_mid', value: data ? data.topic_mid : -1 }
            ]
        });
        Baseliner.TopicForm.superclass.initComponent.call(this);

        self.on_submit = function(){
            Ext.each( on_submit_events, function(ev) {
                ev();
            });
        };

       
        // if we have an id, then async load the form
        self.on('afterrender', function(){
            //self.body.setStyle('overflow', 'auto');
            self.ownerCt.doLayout();  // so we get a scrollbar from the parent, XXX consider putting this in parent
        });

        self.render_fields(data);
    },
    render_fields : function(data) {
        var self = this;
        var rec = self.rec;
        if( rec.topic_meta == undefined ) return;
        ///*****************************************************************************************************************************
        var fields = rec.topic_meta;
        
        for( var i = 0; i < fields.length; i++ ) {
            var field = fields[i];
            if( field.active!=undefined && ( !field.active || field.active=='false') ) continue;
            
            if( field.body) {// some fields only have an html part
                if( field.body.length==0  ) continue; 
                var comp = Baseliner.eval_response(
                    field.body,
                    { 
                        form: self, topic_data: data, topic_meta:  field, value: '', 
                        _cis: rec._cis, id_panel: rec.id_panel, admin: rec.can_admin, 
                        html_buttons: rec.html_buttons 
                    }
                );
                
                if( !comp ) continue; // invalid field?

                if( comp.xtype == 'hidden' ) {
                        self.add( comp );
                } else {
                    var all_hidden = true;
                    Ext.each( comp, function(f){
                        if( f.hidden!=undefined && !f.hidden ) all_hidden = false;
                    });
                    var colspan =  field.colspan || self.form_columns;
                    var cw = field.colWidth || ( colspan / self.form_columns );
                    var p_style = {};
                    if( Ext.isIE && !all_hidden ) p_style['margin-top'] = '8px';
                    p_style['padding-right'] = '10px';
                    var p_opts = { layout:'form', style: p_style, border: false, columnWidth: cw };
                    var p = new Ext.Container( p_opts );
                    if( comp.items ) {
                        if( comp.on_submit ) on_submit_events.push( comp.on_submit );
                        p.add( comp.items ); 
                        self.add ( p );
                    } else {
                        p.add( comp ); 
                        self.add ( p );
                    }
                }
            }
        }  // for fields

        self.on( 'afterrender', function(){
            var form2 = self.getForm();
            var id_category = rec.new_category_id ? rec.new_category_id : data.id_category;
        
            var obj_combo_category = form2.findField("category");
            var obj_store_category;
            if(obj_combo_category){
                obj_store_category = form2.findField("category").getStore();
                obj_store_category.on("load", function() {
                   obj_combo_category.setValue(id_category);
                });
                obj_store_category.load();
            }
        
            var obj_combo_status = form2.findField("status_new");
            var obj_store_category_status;                
            
            if( rec.new_category_id != undefined ) {
                if(obj_combo_status){
                    obj_store_category_status = obj_combo_status.getStore();
                    obj_store_category_status.on('load', function(){
                        if( obj_store_category_status != undefined && obj_store_category_status.getAt(0) != undefined )
                            obj_combo_status.setValue( obj_store_category_status.getAt(0).id );
                    });
                    obj_store_category_status.load({
                        params:{ 'change_categoryId': id_category }
                    });                         
                }
                form2.findField("topic_mid").setValue(-1);
            }else {
                if(obj_combo_status){
                    obj_store_category_status = obj_combo_status.getStore();
                    obj_store_category_status.on("load", function() {
                        obj_combo_status.setValue( data ? data.id_category_status : '' );
                    });
                    obj_store_category_status.load({
                            params:{ 'categoryId': id_category, 'statusId': data ? data.id_category_status : '', 'statusName': data ? data.name_status : '' }
                    });                         
                }
            }
            
            var obj_combo_priority = form2.findField("priority");
            var obj_store_category_priority;
        
            if(obj_combo_priority){
                obj_store_category_priority = obj_combo_priority.getStore();
                obj_store_category_priority.on("load", function() {
                    obj_combo_priority.setValue(data ? data.id_priority : '');                            
                });                    
                obj_store_category_priority.load({params:{'active':1, 'category_id': id_category}});
            }
            self.doLayout();
        });
    }
})


