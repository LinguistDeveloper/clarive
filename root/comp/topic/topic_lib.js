Baseliner.Topic = {};
    
Baseliner.Topic.rt = Ext.data.Record.create([
    {name: 'id_project'},
    {name: 'project'}
]);

Baseliner.topic_category_class = {};

Baseliner.show_topic = function(topic_mid, title, params) {
    Baseliner.add_tabcomp('/topic/view', title , Ext.apply({ topic_mid: topic_mid, title: title }, params) );
    var grid = Ext.getCmp(params._parent_grid);
    if( grid ) {
        Baseliner.user_seen_row( grid, topic_mid );
    }
};

Baseliner.tree_topic_style = [
    '<span unselectable="on" style="font-size:0px;',
    'padding: 8px 8px 0px 0px;',
    'margin : 0px 4px 0px 0px;',
    'border : 2px solid {0};',
    'background-color: transparent;',
    'color:{0};',
    'border-radius:0px"></span>'
].join('');

Baseliner.topic_title = function( mid, category, color, literal_only, id) {
    var uppers = category ? category.replace( /[^A-Z]/g, '' ) : '';
    var pad_for_tab = 'margin: 0 0 -3px 0; padding: 2px 4px 2px 4px; line-height: 12px;'; // so that tabs stay aligned
    if(!id) id = Ext.id();
    if (literal_only){
        return uppers + ' #' + mid;   
    }else{
        return color 
            ? String.format( '<span id="boot" style="background:transparent; margin-bottom: 0px"><span id="{4}" class="label" style="{3}; background-color:{1}">{2} #{0}</span></span>', mid, color, uppers, pad_for_tab, id )
            : String.format( '<span id="boot" style="background:transparent; margin-bottom: 0px"><span id="{4}" class="label" style="{3}; background-color:{2}">{0} #{1}</span></span>', uppers, mid, color, pad_for_tab, id )
            ;
    }
}

Baseliner.show_category = function(category_id, title, params) {
    Baseliner.add_tabcomp('/topic/grid', title , Ext.apply({ category_id: category_id, title: title }, params) );
};

Baseliner.category_title = function( id, category, color, id) {
    var uppers = category ? category.replace( /[^A-Z]/g, '' ) : '';
    var pad_for_tab = 'margin: 0 0 -3px 0; padding: 2px 4px 2px 4px; line-height: 12px;'; // so that tabs stay aligned
    if(!id) id = Ext.id();
    return String.format( '<span id="boot" style="background:transparent; margin-bottom: 0px"><span id="{4}" class="label" style="{3}; background-color:{1}">{2}</span></span>', id, color, uppers, pad_for_tab, id );
}

Baseliner.show_topic_colored = function(mid, category, color, grid_id) {
    var title = Baseliner.topic_title( mid, _(category), color );
    Baseliner.show_topic( mid, title, { topic_mid: mid, title: title, _parent_grid: grid_id } );
    //Baseliner.add_tabcomp('/topic/view?topic_mid=' + r.get('topic_mid') + '&app=' + typeApplication , title ,  );
}

Baseliner.show_topic_from_row = function(r, grid) {
    var title = Baseliner.topic_title( r.get('topic_mid'), _(r.get( 'category_name' )), r.get('category_color') );
    Baseliner.show_topic( r.data.topic_mid, title, { topic_mid: r.get('topic_mid'), title: title, _parent_grid: grid.id } );
    //Baseliner.add_tabcomp('/topic/view?topic_mid=' + r.get('topic_mid') + '&app=' + typeApplication , title ,  );
}

Baseliner.user_seen_row = function(grid,mid){
    var store = grid.getStore();
    if( !store ) return;
    var row;
    if( Ext.isObject( mid ) ) {
        row = mid;
    } else {
        var ix = store.find('topic_mid', mid );
        if( ix<0 ) return;
        var row = store.getAt( ix );
        if( !row ) return;
    }
    row.data.user_seen = true;
    grid.getStore().commitChanges();
    grid.getView().refresh();
};
    
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
        var cat_name = args.short_name ? _(args.category_name).replace( /[^A-Z]/g, '' ) : _(args.category_name); //Cambiarlo en un futuro por un contador de categorias
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
    var fields = ['mid','name', 'title','description','color','short_name'];

    if (c.display_field){
        fields.push(c.display_field);
        delete c.display_field;  
    }

    if (c.tpl_cfg){
        var column_tpl = c.tpl_cfg.split(';');
        for (i=0;i<column_tpl.length;i++) {        
            var col_name = column_tpl[i].split(':');
            fields.push(col_name[0]);
        }
    }

    Baseliner.store.Topics.superclass.constructor.call(this, Ext.apply({
        root: 'data' , 
        remoteSort: true,
        autoLoad: true,
        totalProperty:"totalCount", 
        baseParams: {},
        id: 'mid', 
        url: '/topic/related',
        fields: fields 
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
    // stackItems: true,
    initComponent: function(){
        var self = this;

        if (self.tpl_cfg){
            var columns = self.tpl_cfg.split(';');
            var header = [];
            var body = [];
            header.push('<p>');
            body.push('<p><div class="x-combo-list-item">');
            for (i=0;i<columns.length;i++){
                var properties = columns[i].split(':');
                var width_column;
                var name_column;
                if (properties[0] == 'mid'){
                    width_column = properties[1] ? properties[1] : '75'; 
                    header.push('<div class="titulo" style="width:' + width_column + 'px;">&nbsp;');
                    name_column = _(properties[0]).toUpperCase();
                    header.push( name_column );
                    header.push('</div>');

                    body.push('<div class="columna" style="width:' + width_column + 'px;"><span class="bl-label" style="background: {color}; cursor:pointer;">');
                    body.push( properties[0] == 'mid' ? '{short_name}' : '{' + properties[0] + '}' );
                    body.push('</span></div>');
                }else{
                    width_column = properties[1] ? properties[1] : undefined;
                    if (width_column){
                        header.push('<div class="titulo" style="width:' + width_column + 'px;">&nbsp;');
                        body.push('<div class="columna" style="width:' + width_column +'px;">{');
                    }else{
                        header.push('<div class="titulo">&nbsp;');
                        body.push('<div class="columna">{');
                    }
                    name_column = _(properties[0]).toUpperCase();
                    header.push( name_column );
                    header.push('</div>');

                    body.push( properties[0] );
                    body.push('}</div>');
                }
            }
            header.push('</p>');
            body.push('</div></p>');

            str_header = header.join('');
            str_body = body.join('');

            self.tpl = new Ext.XTemplate( 
                '<tpl>',
                '<div class="tabla">',
                str_header,
                '<tpl for=".">',
                str_body,
                '</tpl>',
                '</div>',
                '</tpl>');        
        }else{
            self.tpl = new Ext.XTemplate( '<tpl for=".">',
                '<div class="x-combo-list-item">',
                '<span class="bl-label" style="background: {color}">{short_name}</span>',
                ( self.display_field ? '&nbsp;[{'+self.display_field+'}]' : '' ),
                '<span style="padding-left:4px"><b>{title}</b></span>',
                '</div></tpl>' );            
        }

        self.displayFieldTpl = new Ext.XTemplate( '<tpl for=".">',
            '<div class="bl-text-over" title="{title}">',
            '<span class="bl-label" style="background: {color}; cursor:pointer;" onclick="javascript:Baseliner.show_topic_colored({mid}, \'{name}\', \'{color}\');">{short_name}</span>',
            ( self.display_field ? '&nbsp;{'+self.display_field+'}' : '' ),
            // '<span style="padding-left:4px">{title}</span>',
            '</div></tpl>' );
        
        Baseliner.TopicBox.superclass.initComponent.call(this);
    }
    // }, 
    // get_save_data : function(){
    //     var self = this;
    //     var mids = [];
    //     self.store.each(function(row){
    //         mids.push( row.data.mid ); 
    //     });
    //     return mids;
    // }
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
        var fields = [ 
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
            {  name: 'directory' },
            {  name: 'current_job' },
            {  name: 'user_seen' },
            {  name: 'sw_edit'},
            {  name: 'modified_on', type: 'date', dateFormat: 'c' },        
            {  name: 'modified_by' }
        ];

        if( config.add_fields ) {
            var ff = {};
            Ext.each( config.add_fields, function(f){
                fields.push(f);
            });
            delete config.add_fields;
        }

        config = Ext.apply({
            root: 'data' , 
            remoteSort: true,
            totalProperty:"totalCount", 
            url: '/topic/list',
            fields: fields
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

Baseliner.Topic.comment_delete = function(topic_mid, id_com, id_div ) {
    Baseliner.ajaxEval( '/topic/comment/delete', { id_com: id_com }, function(res) {
        if( res.failure ) {
            Baseliner.error( _('Error'), res.msg );
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
        Baseliner.ajaxEval('/topic/comment/view', { topic_mid: topic_mid, id_com: id_com }, function(res) {
            if( res.failure ) {
                Baseliner.error( _('Error'), res.msg );
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
    layout: 'card',
    activeItem: 0,
    autoScroll: true,
    //frame: true,
    //padding: '15px 15px 15px 15px',
    initComponent: function(c){
        var self = this;
        var params = self;
        
        self.view_is_dirty = false;
        self.form_is_loaded = false;
        self.ii = self.id;  // used by the detail page
        self.toggle_group = 'form_btns_' + self.ii;
        self.id_title = Ext.id(); // so that we can set the tooltip to the tab 

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
            hidden: self.permDelete,
            handler: function(){ return self.delete_topic() }
        });
    
        // Detail Panel
        self.detail = new Ext.Panel({ 
            padding: 15,
            layout:'fit'
        });
        
        Baseliner.Topic.file_del = function( topic_mid, mid, id_row ) {
            Baseliner.ajaxEval( '/topic/file/delete', { asset_mid: mid, topic_mid: topic_mid }, function(res) {
                if( res.success ) {
                    Baseliner.message( _('File'), res.msg );
                    Ext.fly( id_row ).remove();
                }
                else {
                    Baseliner.error( _('Error'), res.msg );
                }
            });
        };
    
        self._cis = [];
        var rg;
        var show_graph = function(){
            if( rg ) { rg.destroy(); rg=null }
            rg = new Baseliner.CIGraph({ mid: params.topic_mid, direction:'children', depth: 2, which:'rg' });
            self.add( rg );
            self.getLayout().setActiveItem( rg );
        };
    
    
        self.btn_comment = new Ext.Toolbar.Button({
            text: _('Add Comment'),
            icon:'/static/images/icons/comment_new.gif',
            cls: 'x-btn-icon-text',
            hidden: !self.permComment,
            handler: function() {
                Baseliner.Topic.comment_edit( params.topic_mid, null, function(id_com){ self.detail_reload() });
            }
        });
    
        self.btn_detail = new Ext.Toolbar.Button({
            icon:'/static/images/icons/detail.png',
            cls: 'x-btn-icon',
            enableToggle: true, 
            hidden: self.topic_mid==undefined,
            pressed: self.topic_mid!=undefined, 
            allowDepress: false, 
            handler: function(){ self.show_detail() }, 
            toggleGroup: self.toggle_group
        });
        
        self.btn_edit = new Ext.Toolbar.Button({
            name: 'edit',
            text:_('Edit'),
            icon:'/static/images/icons/edit.png',
            cls: 'x-btn-text-icon',
            enableToggle: true, 
            pressed: self.topic_mid==undefined,
            handler: function(){ 
                //if( self.btn_edit.toggle ) return; 
                return self.show_form() }, 
            allowDepress: false, toggleGroup: self.toggle_group
        });
        
        var obj_deploy_items_menu = Ext.util.JSON.decode(self.menu_deploy || []);

        self.menu_deploy = [];

        if ( obj_deploy_items_menu.menu ) {
            for(i=0; i < obj_deploy_items_menu.menu.length;i++){
                var topic = { 
                    text: _(obj_deploy_items_menu.menu[i].text), 
                    topic_mid: self.topic_mid, 
                    id: obj_deploy_items_menu.menu[i].eval.id,
                    id_project: obj_deploy_items_menu.menu[i].eval.id_project, 
                    state_id: obj_deploy_items_menu.menu[i].id_status_from, 
                    promotable: obj_deploy_items_menu.promotable, 
                    demotable: obj_deploy_items_menu.demotable, 
                    deployable: obj_deploy_items_menu.deployable, 
                    job_type: obj_deploy_items_menu.menu[i].eval.job_type,
                    state_to: obj_deploy_items_menu.menu[i].eval.state_to
                };
                self.menu_deploy.push({ 
                    text: _(obj_deploy_items_menu.menu[i].text), 
                    icon: obj_deploy_items_menu.menu[i].icon,
                    topic: topic,
                    handler: function(obj){ 
                        Baseliner.add_tabcomp( '/job/create', _('New Job'), { node: obj.topic } );
                    } 
                });
            }
        };
        
        self.menu_deploy_final = new Ext.menu.Menu({
            items: self.menu_deploy
        });

        self.btn_deploy = new Ext.Toolbar.Button({ text: _("New Job"), menu: self.menu_deploy_final, hidden: true });

        if (self.menu_deploy.length <= 0){
            self.btn_deploy.hide();
        }

        var obj_status_items_menu = Ext.util.JSON.decode(self.status_items_menu);
        
        self.status_items_menu = [];
        for(i=0; i < obj_status_items_menu.length;i++){
            self.status_items_menu.push({ 
                text: _(obj_status_items_menu[i].status_name), 
                id_status_to: obj_status_items_menu[i].id_status, 
                id_status_from: obj_status_items_menu[i].id_status_from, 
                handler: function(obj){ self.change_status(obj) } 
            });
        }
    
        self.status_menu = new Ext.menu.Menu({
            items: self.status_items_menu
        });

        
        self.btn_change_status = new Ext.Toolbar.Button({ text: _("Change State"), menu: self.status_menu, hidden: true });
        if (self.status_items_menu.length <= 0){
            self.btn_change_status.hide();
        }
        
        self.btn_kanban = new Ext.Toolbar.Button({
            icon:'/static/images/icons/kanban.png',
            cls: 'x-btn-icon',
            enableToggle: true, 
            handler: function(){ self.show_kanban() }, 
            hidden: self.viewKanban==undefined?true:!self.viewKanban,
            allowDepress: false, toggleGroup: self.toggle_group
        });
            
        self.btn_graph = new Ext.Toolbar.Button({
            icon:'/static/images/ci/ci-grey.png',
            cls: 'x-btn-icon',
            hidden: self.permGraph==undefined?true:!self.permGraph,
            enableToggle: true, handler: show_graph, allowDepress: false, toggleGroup: self.toggle_group
        });
            
        self.loading_panel = Baseliner.loading_panel();
    
        var tb;
        var typeToolBar = ''; //'GDI';
        
        tb = self.create_toolbar();

        self.detail.on( 'render', function() {
            if (self.topic_mid > 0){
                if (self.status_items_menu.length <= 0){
                    self.btn_change_status.hide();
                }else{
                    self.btn_change_status.show();
                }
                if (self.menu_deploy.length <= 0){
                    self.btn_deploy.hide();
                }else{
                    self.btn_deploy.show();
                }
            }
            
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
            if( !self.permDelete ) {
                self.btn_delete_form.hide();
            } else {
                self.btn_delete_form.show();
            }
        });
        
        if( !self.permEdit ) {
            self.btn_edit.hide();
        }
        if( !self.permDelete ) {
            self.btn_delete_form.hide();
        }
        if( ! params.title ) {
            self.setTitle( Baseliner.topic_title( params.topic_mid, params.category, params.category_color, null, self.id_title ) ) 
        }
        
        self.title = params.title;
        self.tbar = tb;
        self.defaults = {border: false};
        self.items = [ self.loading_panel, self.detail ];
        
        Baseliner.TopicMain.superclass.initComponent.call(this);

        self.on('afterrender', function(){
            new Ext.KeyMap( self.el, {
                key: 's', ctrl: true, scope: self.el,
                stopEvent: true,
                fn: function(){  
                    if( self.btn_save_form && !self.btn_save_form.hidden && !self.btn_save_form.disabled ) {
                        self.save_topic(); 
                    }
                    return false;
                }
            });
        });
        self.on('beforeclose', function(){ 
            self.close_answer=''; 
            return self.closing() 
        });
        self.on('beforedestroy', function(){ 
              if( self.close_answer ) return true; 
              self.closing('destroy'); 
              return true; // destroy cannot be stopped
        }); 
    },
    is_dirty : function(){
        var self = this;
        if( !self.form_topic || !self.form_topic.getForm() ) return false;
        if( !self.original_record ) return false;
        var values = self.form_topic.getValues();
        var diff = objectDiff.diff( self.original_record, values );
        if( diff.changed == 'equal' ) return false;
        var fields = [];
        for( var k in diff.value ) {
            var field = diff.value[k];
            if( k==undefined || k=='undefined' ) continue;
            if( /^(mid|topic|topic_mid|status|status_new|category)$/.test(k) ) continue;
            if( /ext-gen/.test(k) ) continue;
            if( field.changed == 'equal' ) continue;
            fields.push( k );  // translate keys to english, then translate again
        }
        // topic status changes automatically, but should not be considered dirty
        if( fields.length==0 ) return false;
        self.changed_fields = [];
        Ext.each( fields, function(k){
            var meta = self.form_topic.field_map[ k ];
            label = meta && meta.name_field;
            self.changed_fields.push( _(label || k) );
        });
        return true; // self.form_topic.getForm().isDirty();
    },
    closing : function(mode){
        var self = this; 
        if( self.btn_save_form && !self.btn_save_form.hidden && self.is_dirty() ) {
            self.close_check(mode);
            return false;
        }
        return true;
    },
    close_check : function(mode){
        var self = this;
        var msg = _('Topic has changed but has not been saved (changed fields: %1). Save topic now?', self.changed_fields.join(', ') );
        Ext.Msg.show({
           title: _('Save Changes?'),
           msg: msg,
           buttons: mode=='destroy' ? Ext.Msg.YESNO : Ext.Msg.YESNOCANCEL,
           closable: false,
           modal: true,
           fn: function(btn){
               if( btn=='cancel' ) {
                   return;
               } 
               else if( btn=='yes' && mode=='destroy' ) {
                   self.save_topic({ return_on_save : true }); 
               }
               else if( btn=='yes' ) {
                   self.close_answer = 'yes';  // avoid firing again on destroy
                   self.save_topic({ close_on_save : true }); 
               }
               else {
                   self.close_answer = 'no';
                   if( mode!='destroy' ) self.destroy(); // if its a beforedestroy, the form is gone by now
               }
           },
           animEl: 'elId',
           icon: Ext.MessageBox.QUESTION
        });
    },
    set_original_record : function(data,retry){
        var self = this;
        if( retry == undefined ) retry=0;
        if( retry>10 ) return; // we're done
        setTimeout( function(){
            if( !self.form_topic ) return;
            if( self.form_topic.is_loaded ) {
                self.original_record = data || self.form_topic.getValues();
            } else {
                self.set_original_record(data,retry+1); // retry
            }
        }, 5000);
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

        if( self.form_topic ) self.remove( self.form_topic );
        self.form_topic = new Baseliner.TopicForm({ rec: rec, main: self, padding: 15, id_title: self.id_title });
        
        if( ! self.form_is_loaded ) {
            self.add( self.form_topic );
            self.set_original_record();
            self.getLayout().setActiveItem( self.form_topic );
            self.form_is_loaded = true;
        }

        // now show/hide buttons
        self.btn_save_form.show();

        if(self.topic_mid){
            if( self.permComment ) {
                self.btn_comment.show();
            };
            //Baseliner.TopicExtension.toolbar.length > 0 ? self.btn_detail.hide(): self.btn_detail.show();
            self.btn_detail.show();
            if( self.permDelete ) {
                self.btn_delete_form.show();
            }
            self.modified_on = rec.topic_data.modified_on_epoch;
        }else{
            self.btn_comment.hide();
            self.btn_detail.hide();
            self.btn_delete_form.hide();
        }
    },
    show_form : function(dontshow){
        var self = this;
        var ai = self.getLayout().activeItem;
        if( ai && self.form_topic && self.form_is_loaded && ai.id==self.form_topic.id ) return;
        if( !dontshow ) self.getLayout().setActiveItem( self.loading_panel );
        if( self!==undefined && self.topic_mid !== undefined ) {
            var info = Baseliner.tabInfo[self.id];
            if( info!=undefined ) info.params.swEdit = 1;
            self.btn_change_status.hide();
            self.btn_deploy.hide();
            if (!self.form_is_loaded){
                Baseliner.ajaxEval( '/topic/json', { topic_mid: self.topic_mid, topic_child_data : true }, function(rec) {
                    self.load_form( rec );
                });
            }else{
                if( !dontshow ) self.getLayout().setActiveItem( self.form_topic );
                self.btn_save_form.show();
                
                if(self.topic_mid){
                    if( self.permComment ) {
                        self.btn_comment.show();
                    };
                    self.btn_detail.show();
                    if( self.permDelete ) {
                        self.btn_delete_form.show();
                    }
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
                self.btn_deploy,
                '-',
                self.btn_change_status,
                self.btn_graph,
                self.btn_kanban
            ]
        });
        return tb;
    },
    show_kanban : function(){
        var self = this;
        if( self.kanban ) {
            self.getLayout().setActiveItem( self.kanban );
            return;
        }  
        Baseliner.ajaxEval('/topic/children', { mid: self.topic_mid, _whoami: 'show_kanban' }, function(res){
            var topics = res.children;
            self.kanban = new Baseliner.Kanban({ 
                //background: '#888',
                title: self.title,
                topics: topics
            });
            self.kanban.on('beforeclose', function(tabid){
                self.getLayout().setActiveItem( self.detail );
                self.btn_detail.toggle( true );
                self.kanban = null;
            });
            self.kanban.on('tab', function(tabid){
                self.getLayout().setActiveItem( self.detail );
                self.btn_detail.toggle( true );
                self.kanban = null;
            });
            self.add( self.kanban );
            self.getLayout().setActiveItem( self.kanban );
        });
    },
    show_detail : function(){
        var self = this;
        self.getLayout().setActiveItem( self.detail );
        var info = Baseliner.tabInfo[self.id];
        if( info!=undefined ) info.params.swEdit = 0;
        
        if(self.status_menu.items.length > 0){
            self.btn_change_status.show();
        }
        else{
            self.btn_change_status.hide();
        }
        if(self.menu_deploy.length > 0){
            self.btn_deploy.show();
        }
        else{
            self.btn_deploy.hide();
        }
        
        self.btn_save_form.hide();
        if( self.view_is_dirty ) {
            self.btn_detail.toggle(true);
            self.view_is_dirty = false;
            self.detail_reload();
        }
    },
    detail_reload : function(){
        var self = this;
        // using jquery cos the self.detail.load() method callback is not consistent in IE8
        $( self.detail.body.dom ).load( '/topic/view', 
            { topic_mid: self.topic_mid, ii: self.ii, html: 1, categoryId: self.new_category_id, topic_child_data : true },
            function( responseText, textStatus, req ){
                var success = textStatus == 'success';
                if( !success ) {
                    self.detail.update( responseText );
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
            });
        self.detail.body.setStyle('overflow', 'auto');
    },
    save_topic : function(opts){
        var self = this;
        self.form_topic.on_submit();
        if( !opts ) opts = {};
        
        var form_data = self.form_topic.getValues();
        self.original_record = form_data; // reset save status for is_dirty
        var form2 = self.form_topic.getForm();
        var action = form_data['topic_mid'] >= 0 ? 'update' : 'add';
        var custom_form = '';
        
        var do_submit = function(){
            self.getEl().mask(_("Processing.  Please wait"));
            Baseliner.ajax_json( 
                self.form_topic.url,
                Ext.apply({ action: action, form: custom_form, _cis: Ext.util.JSON.encode( self._cis ) }, form_data), 
                // success
                function(res){
                    self.getEl().unmask();
                    self.getTopToolbar().enable();
                    if( self.permDelete ) {
                        self.btn_delete_form.enable();
                    }                    
                    Baseliner.message(_('Success'), res.msg );
                    self.reload_parent_grid();
                    if( opts.close_on_save ) {
                        self.destroy();
                        return;
                    }
                    if( opts.return_on_save ) {
                        return;
                    }
                        
                    var mid = res.topic_mid;
                    form2.findField("topic_mid").setValue( mid );
                    var status_hidden_field = form2.findField("status");
                    var status_value = status_hidden_field.getValue();
                    
                    if ( res.return_options.reload == 1 ) {
                    // if ( status_value != res.topic_status && status_value != ''){
                        self.form_is_loaded = false;
                        self.view_is_dirty = true;                     
                        /*
                        var status_combo = form2.findField("status_new");
                        if( status_combo && status_combo.store ) {
                            status_hidden_field.setValue( status_combo.getValue() );
                            status_combo.store.load({ 
                                params: { 
                                    statusId: status_combo.getValue(),
                                    categoryId: form2.findField("category").getValue()
                                } 
                            }); 
                        }
                        */
                        self.show_form();
                    } else {
                        var store = form2.findField("status_new").getStore();
                        if(form2.findField("status").getValue()==''){
                            store.reload({
                                params:{    'categoryId': form2.findField("category").getValue(),
                                            //'statusId': form2.findField("status").getValue(),
                                            'statusId': res.topic_status,
                                            'statusName': form2.findField("status_new").getRawValue()
                                        }
                            });                            
                        }
                       
                        form2.findField("status").setValue(res.topic_status);
                        self.topic_mid = res.topic_mid;
                        if( self.permComment ) {
                            self.btn_comment.show();
                        };
                        self.getTopToolbar().enable();
                        self.btn_detail.show();
                        if( self.permDelete ) {
                            self.btn_delete_form.show();
                        }
                        
                        if(action == 'add'){
                            if ( !opts.no_refresh ) {
                                self.form_is_loaded = false;
                                self.show_form();
                                self.view_is_dirty = true; 
                            }
                            var tabpanel = Ext.getCmp('main-panel');
                            var objtab = tabpanel.getActiveTab();
                            var category = res.category;
                            var title = Baseliner.topic_title( res.topic_mid, category.name, category.color, null, self.id_field );
                            //objtab.setTitle( title );
                            var info = Baseliner.panel_info( objtab );
                            info.params.topic_mid = res.topic_mid;
                            info.title = title;
                            self.setTitle( title );    
                        }
                        self.view_is_dirty = true;
                        if( Ext.isFunction(opts.success) ) opts.success(res);
                        
                        self.modified_on = res.modified_on;
                        
                    }
                },
                // failure
                function(res){
                    self.getEl().unmask();
                    self.getTopToolbar().enable();
                    if( self.permDelete ) {
                        self.btn_delete_form.enable();
                    }
                    //if(res.fields_required){
                    //    var fields_required = self.check_required();
                    //    self.render_required(fields_required);
                    //    Baseliner.message(_('Error'), _('This fields are required: ') + res.fields_required.join(',') );
                    //}else{
                        // self.form_is_loaded = false;
                        // self.show_form();
                        // self.view_is_dirty = true;  
                        Baseliner.error(_('Error'), res.msg );
                    //}

                    
                    if( Ext.isFunction(opts.failure) ) opts.failure(res);
                }
            );
        };
        
        if ( self.form_topic.is_valid() ) {
            self.getTopToolbar().disable();
            self.btn_delete_form.disable();
            
            if(action == 'update'){
                var rel_signature = self.form_topic.rec ? self.form_topic.rec.rel_signature : '';
                Baseliner.ajaxEval( '/topic/check_modified_on/',{ topic_mid: self.topic_mid, modified: self.modified_on, rel_signature: rel_signature },
                    function(res) {
                        if ( res.success ) {
                            var msg_confirm = res.modified_before ? _("Topic was modified by %1 while you're editing %2 ago. Are you sure you want to overwrite the topic?", res.modified_before, res.modified_before_duration) 
                                              : res.modified_rel ? _("Topic relationships changed while you're editing. Are you sure you want to overwrite the topic?")
                                              : null;
                                
                            if (msg_confirm){
                                Ext.Msg.confirm( _('Confirmation'), msg_confirm,
                                    function(btn){ 
                                        if(btn=='yes') {
                                            do_submit();
                                        }else{
                                            self.getTopToolbar().enable();
                                            if( self.permDelete ) {
                                                self.btn_delete_form.enable();                                    
                                            }
                                        }
                                    }
                                );
                            } else{
                                do_submit();
                            }
                        } else {
                            Baseliner.error( _('Error'), res.msg );
                            self.getTopToolbar().enable();
                            if( self.permDelete ) {
                                self.btn_delete_form.enable();                              
                            }
                        }
                    }
                );            
            }else{
                do_submit();
            }
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
    },
    change_status: function(obj){
        var self = this;
        Baseliner.Topic.change_status_topic({ mid: self.topic_mid, new_status: obj.id_status_to, old_status: obj.id_status_from, 'this': self });
    }/*,
    check_required: function(){
        var fields_required = [];
        //var schResults = Ext.query("#ctrl_required");
        var schResults = Ext.query("*[id ^=ctrl_required]");
        if(schResults.length > 0){
            for(i=0;i<schResults.length;i++){
                if(schResults[i].value != '' && schResults[i].value != undefined){
                    fields_required.push(schResults[i].value);
                }
            }
        }
        return fields_required;
    }*/
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


Baseliner.Topic.change_status_topic = function(opts){
    var self = opts['this'];
    self.getEl().mask(_("Processing.  Please wait"));
    Baseliner.ajaxEval( '/topic/change_status',{ mid: opts.mid, new_status: opts.new_status, old_status: opts.old_status },
        function(res) {
            self.getEl().unmask();
            //if ( res.success ) {
                if(res.change_status_before){
                    Ext.Msg.confirm( _('Confirmation'), _('Topic changed status before. Do you  want to refresh the topic?'),
                        function(btn){ 
                            if(btn=='yes') {
                                Baseliner.refreshCurrentTab();
                            }
                        }
                    );                    
                }else{
                    Baseliner.message( _('Success'), res.msg );
                    if( Ext.isFunction(opts.success) ) opts.success(res);
                    Baseliner.refreshCurrentTab();
                }
            //} else {
            //    Baseliner.message( _('Error'), res.msg );
            //    if( Ext.isFunction(opts.failure) ) opts.failure(res);
            //}
        },
        function(res) {
            self.getEl().unmask();
            Baseliner.error( _('Error'), res.msg );
            if( Ext.isFunction(opts.failure) ) opts.failure(res);
        }        
    );
};


Baseliner.TopicCombo = Ext.extend( Ext.form.ComboBox, {
    minChars: 2,
    name: 'topic',
    // displayField: 'short_name',
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
        
        self.tpl = new Ext.XTemplate( '<tpl for=".">',
            '<div class="search-item">',
            '<span class="bl-label" style="background: {color}">{short_name}</span>',
            '<span style="padding-left:4px"><b>{title}</b></span>',
            '</div></tpl>' );
        
        Baseliner.TopicCombo.superclass.initComponent.call(this);
    }
});

Baseliner.TopicGrid = Ext.extend( Ext.grid.GridPanel, {
    constructor: function(c){  // needs to declare the selection model in a constructor, otherwise incompatible with DD
        var sm = c.sm || new Baseliner.CheckboxSelectionModel({
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
                        
                        var col_s = ck.split(',');
                        store_fields.push( col_s[0] || ck );
                        ct = { header: col_s[1] || _(ck), dataindex: col_s[0] || ck, renderer: render_text_field };
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
            height: 200,
            enableDragDrop: true,   
            pageSize: 10, // used by the combo             
            store: store,
            frame: true,
            bodyStyle: {
                'background-color': 'white',
                'overflow-y': 'auto' 
            },
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
            pageSize: parseInt(self.pageSize),
            singleMode: true, 
            fieldLabel: _('Topic'),
            name: 'topic',
            hiddenName: 'topic', 
            allowBlank: true,
            disabled: self.readOnly ? self.readOnly : false 
        });
        self.combo.on('beforequery', function(qe){ delete qe.combo.lastQuery });
        
        self.store.on('add', function(){ self.fireEvent( 'change', self ) });
        self.store.on('remove', function(){ self.fireEvent( 'change', self ) });

        var btn_delete = new Baseliner.Grid.Buttons.Delete({
            disabled: self.readOnly ? self.readOnly : false,
            handler: function() {
                var sm = self.getSelectionModel();
                if (sm.hasSelection()) {
                    Ext.each( sm.getSelections(), function( sel ){
                        self.getStore().remove( sel );
                    });
                } else {
                    Baseliner.error( _('ERROR'), _('Select at least one row'));    
                };                
            }
        });
        var btn_reload = new Ext.Button({
            disabled: self.readOnly ? self.readOnly : false,
            icon: '/static/images/icons/refresh.gif',
            handler: function(){ self.refresh() }
        });
        self.tbar = [ self.combo, btn_reload, btn_delete ];
        self.combo.on('select', function(combo,rec,ix) {
            if( combo.id != self.combo.id ) return; // strange bug with TopicGrid and CIGrid in the same page
            self.add_to_grid( rec.data );
        });
        self.ddGroup = 'bali-topic-grid-data-' + self.id;
        
        self.refresh(true);
        self.on("rowdblclick", function(grid, rowIndex, e ) {
            var r = grid.getStore().getAt(rowIndex);

            //var title = Baseliner.topic_title( r.get('mid'), _(r.get( 'categories' ).name), r.get('color') );
            var title = Baseliner.topic_title( r.get('mid'), _(r.get('name')), r.get('color') );
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
    get_save_data : function(){
        var self = this;
        var mids = [];
        self.store.each(function(row){
            mids.push( row.data.mid ); 
        });
        return mids;
    },
    add_to_grid : function(rec){
        var self = this;
        var f = self.store.find( 'mid', rec.mid );
        if( f != -1 ) {
            Baseliner.warning( _('Warning'), _('Row already exists: %1', rec.name + '(' + rec.mid + ')' ) );
            return;
        }
        var rec_with_data = Ext.apply(rec,rec.data);
        var r = new self.store.recordType( rec_with_data );
        self.store.add( r );
        self.store.commitChanges();
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
    }, 
    is_valid : function(){
        var self = this;
        return self.store.getCount() > 0 ;
    }   
});

Ext.form.Action.prototype.constructor = Ext.form.Action.prototype.constructor.createSequence(function() {
    Ext.applyIf(this.options, {
        submitEmptyText: false
    });
});

Baseliner.field_cache = {};

Baseliner.TopicForm = Ext.extend( Baseliner.FormPanel, {
    labelAlign: 'top',
    layout:'column',
    url:'/topic/update',
    autoHeight: true,
    overflow: 'hidden',
    form_columns: 12,
    is_loaded: true,
    id_title: null,
    //layout:'table',
    //layoutConfig: { columns: form_columns },
    //cls: 'bali-form-table',
    initComponent: function(){
        var self = this;
        var rec = self.rec;

        var form_is_loaded = false;
        var data = rec.topic_data;
        if( data == undefined ) data = {};
        self.on_submit_events = [];
        self.field_map = {};
        
        var unique_id_form = Ext.getCmp('main-panel').getActiveTab().id + '_form_topic';
        this.id = unique_id_form; 
        this.bodyStyle = { 'padding': '5px 50px 5px 10px' };
        this.items = [ { xtype: 'hidden', name: 'topic_mid', value: data ? data.topic_mid : -1 } ];
        
        Baseliner.TopicForm.superclass.initComponent.call(this);
        /*
        self.on('afterrender', function(){
            //self.body.setStyle('overflow', 'auto');
            self.ownerCt.doLayout();  // so we get a scrollbar from the parent, XXX consider putting this in parent
        });
        */

        self.render_fields(data);
    },
    on_submit : function(){
        var self = this;
        Ext.each( self.on_submit_events, function(ev) {
            ev();
        });
    },
    render_fields : function(data) {
        var self = this;
        var rec = self.rec;
        if( data === undefined ) {
            data = self.rec.topic_data;
        }
        if( rec.topic_meta == undefined ) return;
        ///*****************************************************************************************************************************
        var fields = rec.topic_meta;
        
        for( var i = 0; i < fields.length; i++ ) {
            var field = fields[i];
            self.field_map[ field.id_field ] = field;
            // rgo: use this to set a tooltip on the tab with the topic title, probably best if we
            //   get the ext id of the tab here then set the tooltip with bootstrap
            // if( field.meta_goal=='title' || ( field.id_field=='title' ) ) { 
            //     if( self.id_title ) {
            //         $( '#' + self.id_title ).attr('title', data[field.id_field]);
            //     }
            // }
            
            if( field.active!=undefined && ( !field.active || field.active=='false') ) continue;
            
            if( field.body ) {// some fields only have an html part
                var func = Baseliner.field_cache[ field.body[0] ];
                if( !func || field.body[2]>0 ) {
                    var func = Baseliner.eval_response( field.body[1],{},'',true );
                    Baseliner.field_cache[ field.body[0] ] = func;
                }
                if( !func ) continue; 
                var fieldlet = func({ 
                    form: self, topic_data: data, topic_meta:  field, value: '', 
                    _cis: rec._cis, id_panel: rec.id_panel, admin: rec.can_admin, 
                    html_buttons: rec.html_buttons 
                });
                
                if( !fieldlet ) continue; // invalid field?

                if( fieldlet.xtype == 'hidden' ) {
                    self.add( fieldlet );
                } else {
                    var all_hidden = true;
                    Ext.each( fieldlet, function(f){
                        if( f.hidden!=undefined && !f.hidden ) all_hidden = false;
                        f.origin = 'custom';
                        if (f.name == "title" || f.name == "category" || f.name == "status_new") f.system_force = true;
                    });
                    var colspan =  field.colspan || self.form_columns;
                    var cw = field.colWidth || ( colspan / self.form_columns );
                    var p_style = {};
                    if( Ext.isIE && !all_hidden ) p_style['margin-top'] = '8px';
                    p_style['padding-right'] = '10px';
                    var p_opts = { layout:'form', style: p_style, border: false, columnWidth: cw };
                    var p = new Ext.Container( p_opts );
                    // p.on('afterrender',function(){
                    //     if(field.readonly){
                    //         var mask = this.el.mask();
                    //         mask.setStyle('opacity', 0);
                    //         mask.setStyle('height', 5000);
                    //     };            
                    // });                    
                    if( fieldlet.items ) {
                        if( fieldlet.on_submit ) self.on_submit_events.push( fieldlet.on_submit );
                        p.add( fieldlet.items ); 
                        self.add ( p );
                    } else {
                        p.add( fieldlet ); 
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
        self.is_loaded = true;
    }, 
    is_ready : function(){  // if field has is_ready attribute and is true
        var self = this;
        if( !self.is_loaded ) return false;
        var flag = true;
        self.cascade(function(obj){
            if( obj.name!=undefined ) {
                if( obj.is_ready!=undefined && obj.is_ready===false ) {
                    // object has the is_ready property and the property is false (superbox.js)
                    flag = false;
                }
                else if( obj.store != undefined && obj.store.is_loaded!=undefined && !obj.store.is_loaded ) {
                    // object has a store (a Baseliner.JsonStore) and load has not finished
                    flag = false;
                }
            }
        });
        return flag;
    }
});

Baseliner.jobs_for_topic = function(args) {
    Baseliner.ci_call( args.mid, 'jobs', { no_rels: 1 }, function(res){
        var div = document.getElementById( args.render_to );
        var jh = '';
        if( div ) {
            Ext.each( res, function(job){
                //jh += Baseliner.tmpl( 'tmpl_topic_jobs', job ); 
                jh += function(){/*
                    <div style="margin-left: 20px">
                        <p><a href="javascript:Baseliner.addNewTab('/job/log/dashboard?mid=[%= mid %]&name=[%= name %]',
                            '[%= name %]')">
                                [%= name %] ([%= username%])
                           </a> 
                           - [%= _(status) %]  <small>[%= endtime %]</small>
                        </p>
                        <hr />
                    </div> 
                */}.tmpl( job );
            });
            div.innerHTML = res.length 
                ? jh 
                : '<span style="text-transform: uppercase; font-size: 10px; font-weight: bold; padding-left: 5px">' + _('No jobs found') + '</span>';
        }
    });
};

Baseliner.activity_for_topic = function(args) {
    Baseliner.ci_call( args.mid, 'activity', {}, function(res){
        var div = document.getElementById( args.render_to );
        var html = '';
        if( div ) {
            Ext.each( res, function(ev){
                html += function(){/*
                <div style="margin-left: 20px">
                    <p><img style="margin: 5px" width=16 src="/user/avatar/[%= username %]/image.png" />
                    [%= text %]<small>[%= ts %]</small></p>
                    <hr />
                </div> 
                */}.tmpl( ev );
            });
            div.innerHTML = res.length 
                ? html 
                : '<span style="text-transform: uppercase; font-size: 10px; font-weight: bold; padding-left: 5px">' + _('No activity found') + '</span>';
        }
    });
};

Baseliner.comments_for_topic = function(args) {
    Baseliner.ci_call( args.mid, 'comments', {}, function(res){
        var div = document.getElementById( args.render_to );
        var html = '';
        if( div ) {
            Ext.each( res, function(com){
                com.id_div_com = Ext.id();
                html += function(){/*
                <div style="margin-left: 20px" id="[%= id_div_com %]">  <!-- class 'well' -->

[%   if( content_type == 'code' ) { %]

                    <p><pre id="[%= id_div_com + '_ta' %]">[%= text %]</pre></p>

[%   } else { %]
                    <p>[%= text %]</p>
[%   } %]

                    <p><small><img style="margin: 0px 5px 2px 0px" width=16 src="/user/avatar/[%= created_by %]/image.png" />
                    <b>[%= created_by %]</b>, [%= created_on %]

[% if ( can_edit ) { %]

                    | <a href="javascript:Baseliner.Topic.comment_edit( [%= topic_mid %], [%= id %])">[%= _("edit") %]</a>
[% } %]
[% if ( can_delete ) { %]
                    | <a href="javascript:Baseliner.Topic.comment_delete([%= topic_mid %], [%= id %], '[%= id_div_com %]')">[%= _("delete") %]</a>

[% } %]
                    </small></p>
                    <hr />
                </div>
                */}.tmpl( com );
            });
            div.innerHTML = res.length 
                ? html 
                : '<span style="text-transform: uppercase; font-size: 10px; font-weight: bold; padding-left: 5px">' + _('No comments found') + '</span>';
        }
    });
};


