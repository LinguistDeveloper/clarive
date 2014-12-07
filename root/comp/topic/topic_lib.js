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

Baseliner.topic_title = function( mid, category, color, literal_only, id, opts) {
    var uppers = category ? category.replace( /[^A-Z]/g, '' ) : '';
    var pad_for_tab = 'margin: 0 0 -3px 0; padding: 2px 4px 2px 4px; line-height: 12px;'; // so that tabs stay aligned
    if(!id) id = Ext.id();
    if (literal_only){
        return uppers + ' #' + mid;   
    }else if( opts && opts.new_tab ) {
        return String.format( '<span id="boot" style="background:transparent; margin-bottom: 0px"><span id="{4}" class="label" style="{3}; background-color:{0}">{1}: {2}</span></span>', color, _('New'), _(category), pad_for_tab, id )
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
        row = store.getAt( ix );
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


Baseliner.Topic.data_user_event = function( username ) {
    Baseliner.ajaxEval( '/topic/data_user_event/get', { username: username }, function(res) {
        if( res.failure ) {
            Baseliner.error( _('Error'), res.msg );
        } else {
            Ext.Msg.show({
                title:'Datos del usuario ' + username,
                msg: res.msg,
                buttons: Ext.Msg.OK,
                //icon: Ext.Msg.INFO
                icon: 'ext-mb-info'
            });
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
    /* rgo: works good, but we leave the old HtmlEditor for now TODO put CLEditor instead, with less buttons maybe?
    var comment_field = new Baseliner.CLEditor({
         listeners: { 'aftereditor': function(){ comment_field.cleditor.focus() } }
    });
    */
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
                       if( Ext.isFunction(cb)){
                            cb( res.id_com );
                       } else if(cb != null){
                            var my_self = Ext.getCmp(cb);
                            $( my_self.detail.body.dom ).load( '/topic/view', 
                                { topic_mid: my_self.topic_mid, ii: my_self.ii, html: 1, 
                                    categoryId: my_self.new_category_id, topic_child_data : true },
                                function( responseText, textStatus, req ){
                                    var success = textStatus == 'success';
                                    if( !success ) {
                                        my_self.detail.update( responseText );
                                        var layout = my_self.getLayout().setActiveItem( my_self.detail );
                                    } else {
                                        my_self.detail.body.parent().setStyle('width', null);
                                        my_self.detail.body.parent().parent().setStyle('width', null);
                                        my_self.detail.body.setStyle('width', null);
                                        my_self.detail.body.setStyle('height', null);
                                    }
                                });
                            my_self.detail.body.setStyle('overflow', 'auto');                           
                       }
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
        
        var obj_deploy_items_menu = Ext.util.JSON.decode(self.menu_deploy) || { menu: [] };

        self.menu_deploy = [];

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
        
        self.btn_docgen = new Ext.Toolbar.Button({
            icon:'/static/images/icons/document.png',
            tooltip: _('Generate Document'),
            handler: function(){ self.show_docgen() }, 
            hidden: self.viewDocs==undefined?true:!self.viewDocs
        });
            
        self.btn_kanban = new Ext.Toolbar.Button({
            icon:'/static/images/icons/kanban.png',
            cls: 'x-btn-icon',
            enableToggle: true, 
            tooltip: _('Open Kanban'),
            handler: function(){ self.show_kanban() }, 
            hidden: self.viewKanban==undefined?true:!self.viewKanban,
            allowDepress: false, toggleGroup: self.toggle_group
        });
            
        self.btn_graph = new Ext.Toolbar.Button({
            icon:'/static/images/ci/ci-grey.png',
            cls: 'x-btn-icon',
            tooltip: _('Open CI Graph'),
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
            self.setTitle( Baseliner.topic_title( params.topic_mid, params.category||params.category_name, params.category_color, null, self.id_title ) ) 
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
                self.btn_docgen,
                self.btn_graph,
                self.btn_kanban
            ]
        });
        return tb;
    },
    show_docgen : function(){
        var self = this;
        var url = String.format('/doc/topic:{0}/index.html', self.topic_mid );
        var win = window.open( url, '_blank' );
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
        if (self.topic_mid && self.swEdit==1){ self.swEdit = 0};
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
                if ( args.link == 1 ) {
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
                } else {
                    jh += function(){/*
                        <div style="margin-left: 20px">
                            <p>[%= name %] ([%= username%]) - [%= _(status) %]  <small>[%= endtime %]</small></p>
                        </div> 
                    */}.tmpl( job );                    
                }
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
                    <p>
                        <a href="javascript:Baseliner.Topic.data_user_event('[%= username %]')">
                            <img style="margin: 5px" width=16 src="/user/avatar/[%= username %]/image.png" />
                        </a>
                        [%= text %]&nbsp&nbsp
                        <small>
                            [%= ts %]
                        </small>
                    </p>
                <hr /></div> 
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
                com.parent = args.parent_id;
                html += function(){/*
                <div style="margin-left: 20px" id="[%= id_div_com %]">  <!-- class 'well' -->

[%   if( content_type == 'code' ) { %]

                    <p><pre id="[%= id_div_com + '_ta' %]">[%= text %]</pre></p>

[%   } else { %]
                    <p>[%= text %]</p>
[%   } %]

                    <p>
                    <a href="javascript:Baseliner.Topic.data_user_event('[%= created_by %]')">
                    <small><img style="margin: 0px 5px 2px 0px" width=16 src="/user/avatar/[%= created_by %]/image.png" /></a>
                    <b>[%= created_by %]</b>, [%= created_on %]

[% if ( can_edit ) { %]

                    | <a href="javascript:Baseliner.Topic.comment_edit( [%= topic_mid %], [%= id %], '[%= parent %]')">[%= _("edit") %]</a>
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

/* 
 *********************************************************************************
 * Topic Grid
 *********************************************************************************
 */
Baseliner.PagingToolbar = Ext.extend( Ext.PagingToolbar, {
    onLoad: function(store,r,o) {
        var p = this.getParams();
        if( o.params && o.params[p.start] ) {
            var st = o.params[p.start];
            var ap = Math.ceil((this.cursor+this.pageSize)/this.pageSize);
            if( ap > this.getPageData().pages ) { 
                delete o.params[p.start];
            }
        }
        Baseliner.PagingToolbar.superclass.onLoad.call(this,store,r,o);
    }
});

Baseliner.open_topic_grid = function(dir,title,mid){
   var gridp ={ tab_icon: '/static/images/icons/topic.png' } ;
   if( dir ) {
       gridp[ dir=='in' ? 'to_mid' : 'from_mid' ] = mid;
       gridp[ 'tab_icon' ] = '/static/images/icons/topic_' + dir + '.png';
   }
   Baseliner.add_tabcomp('/comp/topic/topic_grid.js',  _('#%1 %2', mid, shorten_title( title )), gridp ); 
};

Baseliner.open_monitor_query = function(q){
    Baseliner.add_tabcomp('/job/monitor', null, { query: q });
}
    
Cla.topic_grid = function(params){
    var ps_maxi = 25; //page_size for !mini mode
    var ps_mini = 50; //page_size for mini mode
    var ps = ps_maxi; // current page_size
    var filter_current;
    var stop_filters = false;
    var typeApplication = params.typeApplication; 
    var parse_typeApplication = (typeApplication != '') ? '/' + typeApplication : '';
    var query_id = params.query_id; 
    var id_project = params.id_project; 
    var id_report = params.id_report || params.id_report_rule;
    var report_type = params.report_type || 'topics';
    var custom_form_url = params.custom_form;
    var custom_form_data = params.custom_form_data || {};
    var report_rows = params.report_rows;
    var report_name = params.report_name;
    var fields = params.fields;
    var status_id = params.status_id;

    if(params.data_report){
     report_rows = params.data_report.report_rows;
     report_name = params.data_report.report_name;
     fields = params.data_report.fields;
    }
    
    var mini_mode = params.mini_mode==undefined ? Prefs.mini_mode : params.mini_mode;
    if( report_rows ) {
        ps_maxi=report_rows;
        ps_mini=report_rows;
        ps= parseInt(report_rows);
        mini_mode = params.mini_mode==undefined ? true : params.mini_mode;
    }
   
    var state_id =id_report ? 'topic-grid-'+id_report : 'topic-grid';
    //console.log( params );
    
    var base_params = { start: 0, limit: ps, typeApplication: typeApplication, 
        from_mid: params.from_mid,
        to_mid: params.to_mid,
        id_project: id_project ? id_project : undefined, 
        topic_list: params.topic_list ? params.topic_list : undefined,
        clear_filter: params.clear_filter ? params.clear_filter : undefined 
    };  // for store_topics

    // this grid may be limited for a given category category id 
    var category_id = params.category_id;
    if( category_id ) {
        params.id_category = category_id;
        base_params.categories = category_id;
    }
    base_params.statuses = status_id;
    
	var store_config;
    if( id_report ) {
        base_params.id_report = params.id_report;
        base_params.id_report_rule = params.id_report_rule;
		store_config = {
			baseParams: base_params,
			remoteSort: false,
			listeners: {
				'beforeload': function( obj, opt ) {
					if( opt !== undefined && opt.params !== undefined )
						filter_current = Baseliner.merge( filter_current, opt.params );
				}
			}
            ,
			sort: function(sorters, direction){
				var col;
				if( this.data.items.length > 0 ){
                     // console.log(sorters);
                     // console.dir(this.data);
					// console.log(this.data.items[0].data[sorters]);
					if(this.data.items[0].data[sorters] === '' ){
						var res = sorters.replace(/\_[^_]+$/,"");
                        sorters = res;
					}
				}
				this.superclass().sort.call(this, sorters, direction);
			}			
		};			
    }else{
		store_config = {
			baseParams: base_params,
			remoteSort: true,
			listeners: {
				'beforeload': function( obj, opt ) {
					if( opt !== undefined && opt.params !== undefined )
						filter_current = Baseliner.merge( filter_current, opt.params );
				}
			}
		};		
	}

    if( fields ) {
        //console.log('Add fields');
        //console.dir(fields);
        store_config.add_fields = fields.ids.map(function(r){ return Ext.isObject(r)?r:{ name: r } });
    }

    // Create store instances
    var store_category = new Baseliner.Topic.StoreCategory();
    //var store_label = new Baseliner.Topic.StoreLabel();
    var store_topics = new Baseliner.Topic.StoreList(store_config);
   
    store_topics.proxy.conn.timeout = 600000;
    var loading;
    store_topics.on('beforeload',function(){
        if( custom_form_url && custom_form.is_loaded ) {
            var fvalues = custom_form.getValues();
            store_topics.baseParams = Ext.apply(store_topics.baseParams, fvalues);
            store_topics.baseParams = Ext.apply(store_topics.baseParams, { meta: params });
        }
        //loading = new Ext.LoadMask(panel.el, {msg:"Please wait..."});
        //loading = Ext.Msg.wait(_('Loading'), _('Loading'), { modal: false } );
        /*
        loading = Ext.Msg.show({
                title : _('Loading'),
                msg : _('Loading'),
                buttons: false,
                closable:false,
                wait: true,
                modal: false,
                minWidth: Ext.Msg.minProgressWidth,
                waitConfig: {}
            });
            */
    });
    store_topics.on('load',function(s){
        if( loading ) loading.hide();
        // get extra data
        var cd = s.reader.jsonData.config;
        if( cd ) custom_form_data = cd;
    });
    
    var init_buttons = function(action) {
        btn_edit[ action ]();
        // btn_delete[ action ]();
    }
    
    var button_no_filter = new Ext.Button({
        icon:'/static/images/icons/clear-all.png',
        tooltip: _('Clear filters'),
        hidden: false,
        cls: 'x-btn-icon',
        disabled: false,
        handler: function(){
            selNodes = tree_filters.getChecked();
            stop_filters = true;  // avoid constant firing
            Ext.each(selNodes, function(node){
                if(node.attributes.checked3){
                    node.attributes.checked3 = -1;
                    node.getUI().toggleCheck(node.attributes.checked3);
                }
                else{
                    node.getUI().toggleCheck(true);
                }
            });
            stop_filters = false;
            loadfilters();
        }
    });
    
    //var button_create_view = new Ext.Button({
    //    icon:'/static/images/icons/add.gif',
    //    tooltip: _('Create view'),
    //    cls: 'x-btn-icon',
    //    disabled: false,
    //    handler: function(){
    //        add_view();
    //    }
    //});
    
    var button_create_view = new Baseliner.Grid.Buttons.Add({
        text:'',
        tooltip: _('Create view'),
        disabled: false,        
        handler: function() {
            add_view()
        }
    });     
    
    var button_delete_view = new Baseliner.Grid.Buttons.Delete({
        text: _(''),
        tooltip: _('Delete view'),
        cls: 'x-btn-icon',
        disabled: true,
        handler: function() {
            Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the views selected?'), 
                function(btn){ 
                    if(btn=='yes') {
                        var views_delete = new Array();
                        selNodes = tree_filters.getChecked();
                        Ext.each(selNodes, function(node){
                            var type = node.parentNode.attributes.id;
                            if(type !== 'V'){
                                return false;
                            }else{
                                if(!eval('node.attributes.default')){  //se pone eval, al parecer hay conflicto con I.E, palabra reservada default
                                    views_delete.push(node.attributes.idfilter);
                                    node.remove();
                                }
                            }
                        });
                        
                        Baseliner.ajaxEval( '/topic/view_filter?action=delete',{ ids_view: views_delete },
                            function(response) {
                                if ( response.success ) {
                                    Baseliner.message( _('Success'), response.msg );
                                    tree_filters.getLoader().load(tree_root);
                                    loadfilters();
                                    button_delete_view.disable();
                                } else {
                                    Baseliner.message( _('ERROR'), response.msg );
                                }
                            }
                        );
                    }
                }
            );
        }
    }); 
    
    
    var add_view = function() {
        var win;
        
        var title = 'Create view';
        
        var form_view = new Ext.FormPanel({
            frame: true,
            url: '/topic/view_filter',
            buttons: [
                {
                    text: _('Accept'),
                    type: 'submit',
                    handler: function() {
                        var form = form_view.getForm();
                        if (form.isValid()) {
                            form.submit({
                                params: {action: 'add', filter: Ext.util.JSON.encode( filter_current )},
                                success: function(f,a){
                                    Baseliner.message(_('Success'), a.result.msg );
                                    var parent_node = tree_filters.getNodeById('V');
                                    var ff;
                                    ff = form_view.getForm();
                                    var name = ff.findField("name").getValue();
                                    parent_node.appendChild({id:a.result.data.id, idfilter: a.result.data.idfilter, text:name, filter:  Ext.util.JSON.encode( filter_current ), 'default': false, cls: 'forum', iconCls: 'icon-no', checked: false, leaf: true});
                                    win.close();
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
                },
                {
                text: _('Close'),
                handler: function(){ 
                        win.close();
                    }
                }
            ],
            defaults: { anchor: '100%' },
            items: [
                {
                    xtype:'textfield',
                    fieldLabel: _('Name view'),
                    name: 'name',
                    //width: '100%',
                    allowBlank: false
                }
            ]
        });
        
        win = new Ext.Window({
            title: _(title),
            width: 550,
            autoHeight: true,
            items: form_view
        });
        win.show();     
    };
    
    var btn_add = new Baseliner.Grid.Buttons.Add({
        handler: function() {
            store_category.load({params:{action: 'create'}});
            add_topic();
        }       
    });
   
    var topic_create_for_category = function(args){
        Baseliner.add_tabcomp('/topic/view?swEdit=1', args.title , { 
            title: args.title, new_category_id: args.id,
            new_category_name: args.name, _parent_grid: grid_topics.id } );
    };

    var add_topic = function() {
        var win;
        if( category_id!=undefined ) {
            topic_create_for_category({ id: category_id });
            return;
        }
        var render_category = function(value,metadata,rec,rowIndex,colIndex,store){
            var color = rec.data.color;
            var ret = '<div id="boot"><span class="label" style="float:left;padding:2px 8px 2px 8px;background: '+ color + '">' + value + '</span></div>';
            return ret;
        };
        
        var topic_category_grid = new Ext.grid.GridPanel({
            store: store_category,
            height: 200,
            hideHeaders: true,
            viewConfig: {
                headersDisabled: true,
                enableRowBody: true,
                forceFit: true
            },
            columns: [
              { header: _('Name'), width: 200, dataIndex: 'name', renderer: render_category },
              { header: _('Description'), width: 450, dataIndex: 'description' }
        
            ]
        });
        
        topic_category_grid.on("rowdblclick", function(grid, rowIndex, e ) {
            var r = grid.getStore().getAt(rowIndex);
            topic_create_for_category({ id: r.get('id'), name: r.get('name') });
            win.close();
        });     
        
        var cat_title = _('Select a category');
        
        var form_topic = new Ext.FormPanel({
            frame: true,
            items: [
                topic_category_grid
            ]
        });

        win = new Ext.Window({
            title: cat_title,
            width: 550,
            autoHeight: true,
            closeAction: 'close',
            modal: true,
            items: form_topic
        });
        win.show();     
    };
    
    
    var make_title = function(){
        var title = [];
        if( report_name ) {
            return report_name; 
        }
        var selNodes = tree_filters.getChecked();
        Ext.each(selNodes, function(node){
            //var type = node.parentNode.attributes.id;
            title.push(node.text);
        }); 
        return title.length > 0 ? title.join(', ') : _('(no filter)');
    };

    var form_report = new Ext.form.FormPanel({
        url: '/topic/report_html', renderTo:'run-panel', style:{ display: 'none'},
        items: [
           { xtype:'hidden', name:'data_json'},
           { xtype:'hidden', name:'title' },
           { xtype:'hidden', name:'rows' },
           { xtype:'hidden', name:'total_rows' }
        ]
    });
    
    var form_report_submit = function(args) {
        var data = { rows:[], columns:[] };
        // find current columns
        var cfg = grid_topics.getColumnModel().config;
        
        if( !args.store_data ) { 
            var row=0, col=0;
            var gv = grid_topics.getView();
            for( var row=0; row<9999; row++ ) {
                if( !gv.getRow(row) ) break;
                var d = {};
                for( var col=0; col<9999; col++ ) {
                    if( !cfg[col] ) break;
                    if( cfg[col].hidden || cfg[col]._checker ) continue; 
                    var cell = gv.getCell(row,col); 
                    if( !cell ) break;
                    //console.log( cell.innerHTML );
                    var text = args.no_html ? $(cell.innerHTML).text() : cell.innerHTML;
                    text = text.replace(/^\s+/,'');
                    text = text.replace(/\s+$/,'');
                    d[ cfg[col].dataIndex ] = text;
                }
                data.rows.push( d ); 
            }
        } else {
            // get the grid store data
            store_topics.each( function(rec) {
                var d = rec.data;
                var topic_name = String.format('{0} #{1}', d.category_name, d.topic_mid )
                d.topic_name = topic_name;
                data.rows.push( d ); 
            });
        }
        
        for( var i=0; i<cfg.length; i++ ) {
            //console.log( cfg[i] );
            if( ! cfg[i].hidden && ! cfg[i]._checker ) 
                data.columns.push({ id: cfg[i].dataIndex, name: cfg[i].report_header || cfg[i].header });
        }
        
        // report so that it opens cleanly in another window/download
        var form = form_report.getForm(); 
        form.findField('data_json').setValue( Ext.util.JSON.encode( data ) );
        form.findField('title').setValue( make_title() );
        form.findField('rows').setValue( store_topics.getCount() );
        form.findField('total_rows').setValue( store_topics.getTotalCount() );
        var el = form.getEl().dom;
        var target = document.createAttribute("target");
        target.nodeValue = args.target || "_blank";
        el.setAttributeNode(target);
        el.action = args.url;
        el.submit(); 
    };

    var btn_html = {
        icon: '/static/images/icons/html.png',
        text: _('HTML Report'),
        handler: function() {
            form_report_submit({ url: '/topic/report_html' });
        }
    };

    var btn_yaml = {
        icon: '/static/images/icons/yaml.png',
        text: _('YAML'),
        handler: function() {
            form_report_submit({ no_html: true, url: '/topic/report_yaml' });
        }
    };

    var btn_csv = {
        icon: '/static/images/icons/csv.png',
        text: _('CSV'),
        handler: function() {
            form_report_submit({ no_html: true, url: '/topic/report_csv', target: 'FrameDownload' });
        }
    };

    var btn_reports = new Ext.Button({
        icon: '/static/images/icons/exports.png',
        iconCls: 'x-btn-icon',
        menu: [ btn_html, btn_csv, btn_yaml ]
    });
    
    var btn_edit = new Baseliner.Grid.Buttons.Edit({
        disabled: true,
        handler: function() {
            var sm = grid_topics.getSelectionModel();
                if (sm.hasSelection()) {
                    Ext.each( sm.getSelections(), function(r) {
                        Baseliner.show_topic_from_row( r, grid_topics );
                    });
                } else {
                    Baseliner.message( _('ERROR'), _('Select at least one row'));    
                };
        }
    });
    
    var btn_clear_state = new Ext.Button({
        icon: '/static/images/icons/reset-grey.png',
        tooltip: _('Reset Grid Columns'),
        iconCls: 'x-btn-icon',
        handler: function(){
            // deletes 
            var cp=new Ext.state.CookieProvider();
            Ext.state.Manager.setProvider(cp);
            Ext.state.Manager.clear( state_id );
            Baseliner.refreshCurrentTab();
        }
    });
    
    // var btn_delete = new Baseliner.Grid.Buttons.Delete({
    //     disabled: true,
    //     handler: function() {
    //         var sm = grid_topics.getSelectionModel();
    //         var sel = sm.getSelected();
    //         var topic_names=[];
    //         var topic_mids=[];
    //         Ext.each( sm.getSelections(), function(sel){
    //             topic_names.push( sel.data.category_name + ' #' + sel.data.topic_mid );
    //             topic_mids.push( sel.data.topic_mid );
    //         });
    //         if( topic_names.length > 0 ) {
    //             var names = topic_names.slice(0,10).join(',');
    //             if( topic_names.length > 10 ) {
    //                 names += _(' (and %1 more)', topic_names.length-10 );
    //             }
    //             Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the topic(s)') + ': <br /><b>' + names + '</b>?', 
    //                 function(btn){ 
    //                     if(btn=='yes') {
    //                         Baseliner.Topic.delete_topic({ topic_mids: topic_mids, success: function(){ 
    //                             grid_topics.getStore().remove(sm.getSelections());
    //                             init_buttons('disable') 
    //                         }});
    //                     }
    //                 }
    //             );
    //         }
    //     }
    // });
    
    var btn_mini = new Ext.Toolbar.Button({
        icon:'/static/images/icons/updown_.gif',
        cls: 'x-btn-text-icon',
        enableToggle: true, pressed: mini_mode || false, allowDepress: true,
        handler: function() {
            Prefs.mini_mode = btn_mini.pressed;
            if( btn_mini.pressed && ptool.pageSize == ps_maxi ) {
                ptool.pageSize =  ps_mini;
                store_topics.baseParams.limit = ps_mini;
                ps = ps_mini;
                ps_plugin.setValue( ps_mini );
            }
            else if( !btn_mini.pressed && ptool.pageSize == ps_mini ) {
                ptool.pageSize =  ps_maxi;
                store_topics.baseParams.limit = ps_maxi;
                ps = ps_maxi;
                ps_plugin.setValue( ps_maxi );
            }
            //store_topics.reload();
            ptool.doRefresh();
        }       
    }); 
    
    var btn_kanban = new Ext.Toolbar.Button({
        icon:'/static/images/icons/kanban.png',
        cls: 'x-btn-text-icon',
        //enableToggle: true,
        pressed: false,
        handler: function(){
            // kanban fullscreen 
            var mids = [];
            var sm = grid_topics.getSelectionModel();
            if (sm.hasSelection()) {
                Ext.each( sm.getSelections(), function(r) {
                    mids.push( r.get('topic_mid') );
                });
            } else {
               store_topics.each( function(r){
                    mids.push( r.get('topic_mid') );
               });
            }
            var kanban = new Baseliner.Kanban({ topics: mids });
            kanban.fullscreen();
        }
    }); 
    
    var btn_custom = new Ext.Button({
        icon: '/static/images/icons/table_edit.png',
        iconCls: 'x-btn-icon',
        enableToggle: true, 
        pressed: false,
        text: _('Customize'),
        hidden: custom_form_url ? false : true,
        handler: function(){
            if( !custom_form.is_loaded ) {
                Baseliner.ajax_json( custom_form_url, { data: custom_form_data }, function(comp){
                    custom_form.is_loaded = true;
                    custom_form.removeAll();
                    custom_form.add( comp );
                    custom_form.doLayout();
                    panel.doLayout();
                });
            }
            if( this.pressed ) { 
                custom_panel.show(); 
                custom_panel.expand();
            } else {
                custom_panel.hide(); 
                custom_panel.collapse();
            }
            panel.doLayout();
        }
    });
    
    var custom_form = new Baseliner.FormPanel({ 
        frame: true, forceFit: true, defaults: { msgTarget: 'under', anchor:'100%' },
        hidden: false,
        labelWidth: 150,
        labelAlign: 'right',
        autoScroll: true,
        bodyStyle: { padding: '4px', "background-color": '#eee' }
    });
    var custom_panel = new Ext.Panel({ 
        region: 'south', layout:'fit',
        hidden: true,
        height: 200,
        items: custom_form
    });
    
    
    var render_id = function(value,metadata,rec,rowIndex,colIndex,store) {
        return "<div style='font-weight:bold; font-size: 14px; color: #808080'> #" + value + "</div>" ;
    };

    function returnOpposite(hexcolor) {
        var r = parseInt(hexcolor.substr(0,2),16);
        var g = parseInt(hexcolor.substr(2,2),16);
        var b = parseInt(hexcolor.substr(4,2),16);
        var yiq = ((r*299)+(g*587)+(b*114))/1000;
        return (yiq >= 128) ? '#000000' : '#FFFFFF';
    }


    
    var body_mini_tpl = function(){/*
                  <span style='font-weight:[%=font_weight%]; font-size: 12px; cursor: pointer; [%=strike%]' 
                  onclick='javascript:Baseliner.show_topic_colored([%=mid%],"[%=category_name%]","[%=category_color%]", "[%=id%]");'>[%=value%][%=folders%] </span>
          */}.tmpl();
    
    var body_tpl = function(){/* 
                <span style='font-weight:[%=font_weight%]; font-size: 14px; cursor: pointer; [%=strike%]' 
                onclick='javascript:Baseliner.show_topic_colored([%=mid%],"[%=category_name%]","[%=category_color%]", "[%=id%]")'>[%=value%] </span>
                        <br><div style='margin-top: 5px'><span style="font-weight:bold;color:#111;">[%= ago %]</span> <font color='333'>[%= new Date(modified_on).format(Prefs.js_dtd_format) %]</font>[%=folders%]
                        <a href='javascript:Baseliner.open_monitor_query("[%=current_job%]")'>[%=current_job%] </a><font color='808080'></br>[%=who%] </font ></div> 
           */}.tmpl();

    var render_title = function(value,metadata,rec,rowIndex,colIndex,store) {
        if ( !rec.json[this.dataIndex] ) {
            var str = this.dataIndex;
            var res = str.replace('_' +  this.alias,"");
            value = rec.json[res];
        };      
        
        var mid = rec.data.topic_mid;
        var category_name = rec.data.category_name;
        var category_color = rec.data.category_color;
        var date_modified_on = rec.data.modified_on ? rec.data.modified_on : '';
        // var date_modified_on = rec.data.modified_on ? rec.data.modified_on.dateFormat('M j, Y, g:i a') : '';
        var modified_by = rec.data.modified_by;
        
        //#######################################Ñapa
        if ( rec.json['mid_' + this.alias] ){
            mid = rec.json['mid_' + this.alias];
            category_name = rec.json['category_name_' + this.alias];
            category_color = rec.json['category_color_' + this.alias];
            // var modified_on_to_date = new Date(rec.json['modified_on_' + this.alias]);
            // date_modified_on = modified_on_to_date.dateFormat('M j, Y, g:i a');
            // date_modified_on = modified_on_to_date.dateFormat('M j, Y, g:i a');
            modified_by = rec.json['modified_by_' + this.alias];
        }
        //#######################################
        
        var tag_color_html;
        tag_color_html = '';
        var strike = ( rec.data.is_closed ? 'text-decoration: line-through' : '' );
        var font_weight = rec.data.user_seen===true ? 'normal' : 'bold';

        // folders tags
        var folders;
        if( rec.data.directory && rec.data.directory.length>0 ) {
            folders = '<span id="boot" style="background: transparent"><span class="label topictag">' + rec.data.directory.join('</span><span class="label topictag">') + '</span></span>';
        } else {
            folders = '';
        }

        if(rec.data.labels){
            tag_color_html = "";
            for(i=0;i<rec.data.labels.length;i++){
                if (rec.data.labels[i] != " "){
                    var label = rec.data.labels[i].split(';');
                    var label_name = label[1];
                    var label_color = label[2];
                    tag_color_html = tag_color_html
                        //+ "<div id='boot'><span class='label' style='font-family:Helvetica Neue,Helvetica,Arial,sans-serif;font-size: xx-small; font-weight:bolder;float:left;padding:1px 4px 1px 4px;margin-right:4px;color:"
                        + "<span style='font-family:Helvetica Neue,Helvetica,Arial,sans-serif;font-size: xx-small; font-weight:bolder;float:left;padding:1px 4px 1px 4px;margin-right:4px;-webkit-border-radius: 3px;-moz-border-radius: 3px;border-radius: 3px;"
                        + "color: #fff;background-color:" + label_color + "'>" + label_name + "</span>";
                }
            }
        }
        
        // rowbody: 
        if(btn_mini.pressed){
            return tag_color_html + body_mini_tpl({ 
                        value: value, 
                        strike: strike,
                        modified_on: date_modified_on, 
                        who: _('by %1', modified_by||_('internal')), 
                        ago: Cla.moment(date_modified_on).fromNow(),
                        mid: mid,
                        category_name: category_name,
                        category_color: category_color,
                        id: grid_topics.id, 
                        font_weight: font_weight, 
                        folders: folders, 
                        current_job: rec.data.current_job });                        
        }else{
            return tag_color_html + body_tpl({ 
                        value: value, 
                        strike: strike,
                        modified_on: date_modified_on, 
                        who: _('by %1', modified_by||_('internal')), 
                        ago: Cla.moment(date_modified_on).fromNow(),
                        mid: mid,
                        category_name: category_name, 
                        category_color: category_color, 
                        id: grid_topics.id, 
                        font_weight: font_weight, 
                        folders: folders, 
                        current_job: rec.data.current_job });                        
        }
        
    };
    
    var render_title_comprimido = function(value,metadata,rec,rowIndex,colIndex,store) {
        var tag_color_html = '';
        var strike = ( rec.data.is_closed ? 'text-decoration: line-through' : '' );
        
        if(rec.data.labels){
            for(i=0;i<rec.data.labels.length;i++){
                var label = rec.data.labels[i].split(';');
                var label_name = label[1];
                var label_color = label[2];
                tag_color_html = tag_color_html + "<div id='boot'><span class='label' style='font-size: 9px; float:left;padding:1px 4px 1px 4px;margin-right:4px;color:#" + returnOpposite(label_color) + ";background-color:#" + label_color + "'>" + label_name + "</span></div>";                
            }
        }
        return tag_color_html + "<div style='font-weight:bold; font-size: 14px; "+strike+"' >" + value + "</div>";
    };  
    
    var render_ci = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( !value ) return '';
        var arr=[];
        
        // if ( !rec.json[this.dataIndex] ) {
        //     var str = this.dataIndex;
        //     var res = str.replace('_' +  this.alias,"");
        //     value = rec.json[res];
        // };      

        Ext.each( value, function(v){
            arr.push( typeof v=='object' ? v.moniker ? v.moniker : v.name : v );
        });
        return arr.join('\n');
    };

    var render_file = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( !value ) return '';
        var arr=[];
        
        // if ( !rec.json[this.dataIndex] ) {
        //     var str = this.dataIndex;
        //     var res = str.replace('_' +  this.alias,"");
        //     value = rec.json[res];
        // };      

        Ext.each( value, function(v){
            arr.push( typeof v=='object' ? v.moniker ? v.moniker : v.name : v );
        });
        return arr.join('<br>');
    };
    
    var render_revision = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( !value ) return '';
        var arr=[];
        
        // if ( !rec.json[this.dataIndex] ) {
        //     var str = this.dataIndex;
        //     var res = str.replace('_' +  this.alias,"");
        //     value = rec.json[res];
        // };      

        Ext.each( value, function(v){
            arr.push( typeof v=='object' ? v.name : v );
        });
        return arr.join('<br>');
    };
    
    // calendar meta_type, a little table precompiled
    var html_cal = function(){/*
         <table style="background: transparent">
         <tbody>
         <tr>
            <td style="font-size:9px; font-weight: bold">[%= slotname %]: </td>
            [% if(start_date) { %]
            <td style="font-size:9px">[%= start_date + ' (' + _('start') + ')' %]</td>
            [% } if(plan_start_date) { %]
            <td style="font-size:9px">[%= plan_start_date + ' (' + _('planned start') + ')' %]</td>
            [% } if(end_date) { %]
            <td style="font-size:9px">[%= end_date + ' (' + _('end') + ')'%]</td>
            [% } if(plan_end_date) { %]
            <td style="font-size:9px">[%= plan_end_date + ' (' + _('planned end') + ')'%]</td>
            [% } %]
         </tr>
         </tbody>
         </table>
    */}.tmpl();
    var render_cal = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( typeof value != 'object' ) return '';
        var arr=[];
        for( var slot in value ) {
            var cal = value[slot];
            if( !cal ) continue;
            // if(cal.start_date) cal.start_date = Date.parseDate(cal.start_date,'d/m/Y H:i:s').format( Prefs.js_date_format );
            // if(cal.plan_start_date) cal.plan_start_date = Date.parseDate(cal.plan_start_date,'d/m/Y H:i:s').format( Prefs.js_date_format );
            // if(cal.end_date) cal.end_date = Date.parseDate(cal.end_date,'d/m/Y H:i:s').format( Prefs.js_date_format );
            // if(cal.plan_end_date) cal.plan_end_date = Date.parseDate(cal.plan_end_date,'d/m/Y H:i:s').format( Prefs.js_date_format );
            arr.push( html_cal(cal) );
        }
        return arr.join('\n');
    };
    var render_custom_data = function(data_key, value,metadata,rec,rowIndex,colIndex,store) {
        var arr=[];
        Ext.each( value, function(v){
            try {
                eval('var xx= v.'+data_key);
                arr.push(xx);
            } catch(e) {};
        });
        return arr.join('<br>');
    };

    var render_number = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( !value || value == undefined || value == ' ') return '';
        return parseFloat(value);
    };

    var render_date = function(value,metadata,rec,rowIndex,colIndex,store) {
        if ( !rec.json[this.dataIndex] ) {
            var str = this.dataIndex;
            var res = str.replace('_' +  this.alias,"");
            value = rec.json[res];
        };          
        if( !value || value == undefined ) return '';
        return value;
        //var value_to_date = new Date(value);
        //return value_to_date.dateFormat('d/m/Y');
        var date;
        if (value.getMonth) {
            date = value;
        }else{
            var dateStr= value;
            if (dateStr == '' || dateStr == undefined) return '';
            var a=dateStr.split(" ");
            var d=a[0].split("-");
            var t=a[1].split(":");
            date = new Date(d[0],(d[1]-1),d[2],t[0],t[1],t[2]);
        }
        return date.dateFormat('d/m/Y');
    };
    
    var render_bool = function(value,metadata,rec,rowIndex,colIndex,store) {
        if ( !rec.json[this.dataIndex] ) {
            var str = this.dataIndex;
            var res = str.replace('_' +  this.alias,"");
            value = rec.json[res];
        };          
        if( !value ) return '';
        return '<input type="checkbox" '+ ( value ? 'checked' : '' ) + '></input>'; 
    };
    
    var render_user = function(value,metadata,rec,rowIndex,colIndex,store) {
        // if ( !rec.json[this.dataIndex] ) {
        //     var str = this.dataIndex;
        //     var res = str.replace('_' +  this.alias,"");
        //     value = rec.json[res];
        // };          
        // if( value == undefined ) return '';
        var user_list = value.join();
        return user_list; 
    };
    
    var render_topic_rel = function(value,metadata,rec,rowIndex,colIndex,store) {
        var arr = [];
        
        
        if ( !rec.json[this.dataIndex] ) {
            var str = this.dataIndex;
            var res = str.replace('_' +  this.alias,"");
            value = rec.json[res];
        };
        
        if ( !value || value == undefined ) return '';
        //if( !value  ) return '';
        
        //#################################################Ñapa 
        if ( value[0] && !value[0].mid ) {
            var str = this.dataIndex;
            var res = str.replace('_' +  this.alias,"");
            value = rec.json[res];
        };
        //#####################################################
        
        Ext.each( value, function(topic){
            arr.push( Baseliner.topic_name({
                link: true,
                parent_id: grid_topics.id,
                mid: topic.mid, 
                mini: btn_mini.pressed,
                size: btn_mini.pressed ? '9' : '11',
                category_name: topic.category.name,
                category_color: topic.category.color,
                //category_icon: topic.category.icon,
                is_changeset: topic.is_changeset,
                is_release: topic.is_release
            }) ); 
        });
        return arr.join("<br>");
    }
    
    var shorten_title = function(t){
        if( !t || t.length==0 ) {
            t = '';
        } else if( t.length > 12 ) {
            t = t.substring(0,12) + '\u2026'; 
        } 
        return t;
    }
    var render_actions = function(value,metadata,rec,rowIndex,colIndex,store) {
        var actions_html = new Array();
        var swGo = false;
        actions_html.push("<span id='boot' style='background: transparent'>");
        
        var ref_html = function(dir, refs){
            var img = dir =='in' ? 'referenced_in' : 'references_out';
            var ret = [];
            // open children
            ret.push("<a href='#' onclick='javascript:Baseliner.open_topic_grid(\""+dir+"\", \""+rec.data.title+"\", "+rec.data.topic_mid+"); return false'>");
            ret.push("<span class='label' style='cursor:pointer; color:#333; borderx: 1px #2ECC71 solid; padding-left: 0px; background-color: transparent; font-size:10px; margin-top:0px'>");
            ret.push("<img src='/static/images/icons/"+img+".png'>");
            ret.push( refs.length );
            ret.push("</span>");
            ret.push("</a>&nbsp;");           
            return ret.join('');
        }
        if( Ext.isArray( rec.data.references_out ) && rec.data.references_out.length > 0 ) {
            swGo = true;
            actions_html.push( ref_html( 'out', rec.data.references_out ) );
        }
        if(rec.data.numcomment){
            swGo = true;
            actions_html.push("<span style='float: right; color: #808080'><img border=0 src='/static/images/icons/comment_blue.gif' /> ");
            actions_html.push('<span style="font-size:9px">' + rec.data.numcomment + '</span>&nbsp;');
            actions_html.push("</span>");
        }
        if(rec.data.num_file){
            swGo = true;
            actions_html.push("<span style='float: right; color: #808080'><img border=0 src='/static/images/icons/paperclip.gif' /> ");
            actions_html.push('<span style="font-size:9px">' + rec.data.num_file + '</span>&nbsp;');
            actions_html.push("</span>");           
        }
        if( Ext.isArray( rec.data.referenced_in ) && rec.data.referenced_in.length > 0 ) {
            if( swGo && !btn_mini.pressed )  actions_html.push( '<br>' );
            swGo = true;
            actions_html.push( ref_html( 'in', rec.data.referenced_in ) );
        }
        
        actions_html.push("</span>");
        var str = swGo ? actions_html.join(""):'';
        return str;
    };
    
    var render_project = function(value,metadata,rec,rowIndex,colIndex,store){
        var tag_project_html = '';
        if(rec.data.projects){
            for(i=0;i<rec.data.projects.length;i++){
                var project = rec.data.projects[i].split(';');
                var project_name = project[1];              
                tag_project_html = tag_project_html ? tag_project_html + ',' + project_name: project_name;
            }
        }
        return tag_project_html;
    };

    var render_status = function(value,metadata,rec,rowIndex,colIndex,store){
        if ( !rec.json[this.dataIndex] ) {
            var str = this.dataIndex;
            var res = str.replace('_' +  this.alias,"");
            value = rec.json[res];
        };          
        //////////if(rec.json[this.dataIndex + '_' + this.alias]){
        //////////  value = rec.json[this.dataIndex + '_' + this.alias];
        //////////}     
        var size = btn_mini.pressed ? '8' : '8';
        var ret = String.format(
            '<b><span class="bali-topic-status" style="font-size: {0}px;">{1}</span></b>',
             size, value );
           //+ '<div id="boot"><span class="label" style="float:left;padding:2px 8px 2px 8px;background:#ddd;color:#222;font-weight:normal;text-transform:lowercase;text-shadow:none;"><small>' + value + '</small></span></div>'
        return ret;
    };

    var render_progress = function(value,metadata,rec,rowIndex,colIndex,store){
        if ( !rec.json[this.dataIndex] ) {
            var str = this.dataIndex;
            var res = str.replace('_' +  this.alias,"");
            value = rec.json[res];
        };          
        if( value==undefined || value == 0 ) return '';
        if( rec.data.category_status_type == 'I'  ) return '';  // no progress if its in a initial state

        var cls = ( value < 20 ? 'danger' : ( value < 40 ? 'warning' : ( value < 80 ? 'info' : 'success' ) ) );
        var ret =  [
            '<span id="boot">',
            '<div class="progress progress-'+ cls +'" style="height: 8px">',
                '<div class="bar" style="width: '+value+'%">',
                '</div>',
            '</div>',
            '</span>'
        ].join('');
        return ret;
    };

    var topic_name_too_narrow = false;
    var render_topic_name = function(value,metadata,rec,rowIndex,colIndex,store){
        var d = rec.data;
        //var hc = grid_topics.view.getHeaderCell(colIndex);
        //var too_short = (hc && $(hc).width() < 80) ? true : false;
        return Baseliner.topic_name({
            link: true,
            parent_id: grid_topics.id,
            mid: d.topic_mid || d.mid, 
            mini: btn_mini.pressed,
            size: btn_mini.pressed ? '9' : '11',
            category_name: (topic_name_too_narrow ? '' : d.category_name),
            category_color:  d.category_color,
            category_icon: d.category_icon,
            is_changeset: d.is_changeset,
            is_release: d.is_release
        });
    };
    
    var render_default = function(value,metadata,rec,rowIndex,colIndex,store){
        //console.dir(rec);
        if ( !rec.json[this.dataIndex] ) {
            var str = this.dataIndex;
            if ( str ) {   
                var res = str.replace('_' +  this.alias,"");
                value = rec.json[res];
            }
        };
        if (rec.json[this.dataIndex]) value = rec.json[this.dataIndex];
        var render_obj = [];
        if (value instanceof Array){
            for (var i=0; i<value.length;i++){
                if (typeof(value[i]) == 'object') {
                    var tmp_obj = [];
                    for (var j in value[i] ){
                        console.log(value[i][j]);
                        tmp_obj.push(j + ': ' + value[i][j]);
                    }
                    render_obj.push(tmp_obj.join(';'));
                    //return JSON.stringify(value[i]);
                }else{
                    render_obj.push(value[i]);
                }
            }
            return render_obj.join("<br>");
        }else{
            return value;    
        }
    };  

    var search_field = new Baseliner.SearchField({
        store: store_topics,
        params: {start: 0 },
        emptyText: _('<Enter your search string>')
    });

    //var pager_tool = new Ext.ux.ProgressBarPager();

    var ps_plugin = new Ext.ux.PageSizePlugin({
        editable: false,
        width: 90,
        data: [
            ['5', 5], ['10', 10], ['15', 15], ['20', 20], ['25', 25], ['50', 50],
            ['100', 100], ['200',200], ['500', 500], ['1000', 1000], [_('all rows'), 10000000000 ]
        ],
        beforeText: _('Show'),
        afterText: _('rows/page'),
        value: ps,
        listeners: {
            'select':function(c,rec) {
                ps = rec.data.value;
                if( rec.data.value < 0 ) {
                    ptool.afterTextItem.hide();
                } else {
                    ptool.afterTextItem.show();
                }
            }
        },
        forceSelection: true
    });

    var ptool = new Baseliner.PagingToolbar({            
        store: store_topics,
        pageSize: ps,
        plugins:[
            ps_plugin,
            //pager_tool
            new Ext.ux.ProgressBarPager()
        ],
        displayInfo: true,
        displayMsg: _('Rows {0} - {1} of {2}'),
        emptyMsg: _('There are no rows available')
    });

    var check_sm = new Ext.grid.CheckboxSelectionModel({
        _checker: true,
        singleSelect: false,
        sortable: false,
        checkOnly: true
    });

    var dragger = {     
        header : '',
        id : 'dragger',
        menuDisabled : true,
        fixed : true,
        hideable: false,
        dataIndex: '', 
        width: 7, 
        sortable: false,
        renderer: function(v,m,rec){
            var div = document.createElement('div');
            div.innerHTML = 'abc';
            m.tdCls = m.tdCls + ' dragger-target';
            return ' '; //'<div>aaa</div>';
        }
    };
    
    var force_fit = true;
    
    var type_filters ={
        string: 'string',
        number: 'numeric',
        date: 'date',
        status: 'list',
        ci: 'list'
    }
    var fields_filter = [];
    
    var columns = [];
    var col_map = {
        //topic_name : { header: _('ID'), sortable: true, dataIndex: 'topic_name', width: 90, sortable: true, renderer: render_topic_name },
		topic_name : { header: _('ID'), sortable: true, dataIndex: 'topic_mid', width: 90, sortable: true, renderer: render_topic_name, hidden: report_type != 'topics'?true:false },
        category_name : { header: _('Category'), sortable: true, dataIndex: 'category_name', hidden: true, width: 80, sortable: true, renderer: render_default },
        category_status_name : { header: _('Status'), sortable: true, dataIndex: 'category_status_name', width: 50, renderer: render_status },
        title : { header: _('Title'), dataIndex: 'title', width: 250, sortable: true, renderer: render_title},
        progress : { header: _('%'), dataIndex: 'progress', width: 25, sortable: true, hidden: true, renderer: render_progress },
        numcomment : { header: _('Info'), report_header: _('Comments'), sortable: true, dataIndex: 'numcomment', width: 45, renderer: render_actions },         
        ago : { header: _('When'), report_header: _('When'), sortable: true, dataIndex: 'modified_on', width: 40, renderer: Baseliner.render_ago },         
        projects : { header: _('Projects'), dataIndex: 'projects', sortable: true, width: 60, renderer: render_project },
        topic_mid : { header: _('MID'), hidden: true, sortable: true, dataIndex: 'topic_mid', renderer: render_default},    
        moniker : { header: _('Moniker'), hidden: true, sortable: true, dataIndex: 'moniker', renderer: render_default},    
        cis_out : { header: _('CIs Referenced'), hidden: true, sortable: false, dataIndex: 'cis_out', renderer: render_default},    
        cis_in : { header: _('CIs Referenced In'), hidden: true, sortable: false, dataIndex: 'cis_in', renderer: render_default},    
        references_out : { header: _('References'), hidden: true, sortable: false, dataIndex: 'references_out', renderer: render_default},    
        references_in : { header: _('Referenced In'), hidden: true, sortable: false, dataIndex: 'referenced_in', renderer: render_default},    
        assignee : { header: _('Assigned To'), hidden: true, sortable: true, dataIndex: 'assignee', renderer: render_default},
        current_job : { header: _('Current Job'), hidden: true, sortable: true, dataIndex: 'current_job', renderer: render_default},
        modified_by : { header: _('Modified By'), hidden: true, sortable: true, dataIndex: 'modified_by', renderer: render_default },
        modified_on : { header: _('Modified On'), hidden: true, sortable: true, dataIndex: 'modified_on', renderer: render_date },
        created_on : { header: _('Created On'), width: 80, hidden: true, sortable: true, dataIndex: 'created_on', renderer: render_date },
        created_by : { header: _('Created By'), width: 40, hidden: true, sortable: true, dataIndex: 'created_by', renderer: render_default}
    };
    var gridlets = {
    };
    var meta_types = {
        custom_data : { sortable: true, width: 100, renderer: render_custom_data  },
        number : { sortable: true, width: 100, renderer: render_number  },
        job_id : { sortable: true, width: 100, hidden: true  },
        calendar : { sortable: true, width: 250, renderer: render_cal  },
        date : { sortable: true, width: 100, renderer: render_date  },
        bool : { sortable: true, width: 100, renderer: render_bool  },
        ci : { sortable: true, width: 100, renderer: render_ci  },
        project : { sortable: true, width: 100, renderer: render_ci  },
        topic : { sortable: true, width: 100, renderer: render_topic_rel  },
        release : { sortable: true, width: 100, renderer: render_topic_rel  },
        user : { sortable: true, width: 100, renderer: render_user  },
        file: { sortable: false, width: 150, renderer: render_file},
        revision: { sortable: false, width: 150, renderer: render_revision}
    };

    if( fields ) {
        force_fit = false;
        columns = [ dragger, check_sm, col_map['topic_name'] ];
        Ext.each( fields.columns, function(r){ 
            // r.meta_type, r.id, r.as, r.width, r.header
            //console.log('cols');
        
            if(r.filter){
                var filter_params = {type: type_filters[r.filter.type], dataIndex: r.category ? r.id + '_' + r.category : r.id};
                //var filter_params = {type: type_filters[r.filter.type], dataIndex: r.id};
                
                //console.dir(filter_params);
                switch (filter_params.type){
                    case 'date':   
                        //filter_params.dateFormat = 'Y-m-d';
                        filter_params.beforeText = _('Before');
                        filter_params.afterText = _('After'); 
                        filter_params.onText = _('On'); 
                        break;
                    case 'numeric':
                        filter_params.menuItemCfgs = {
                            emptyText: _('Enter Number...')
                        }
                        break;
                    case 'string':
                        filter_params.emptyText = _('Enter Text...');
                        break;
                    case 'list':
                        if (r.filter.options){
                            if(r.filter.options.length == 1 && r.filter.values[0] == -1){
                                filter_params.type = 'string';
                                filter_params.emptyText = _('Enter mid...');
                                break;                      
                            }else{
                                var options = [];
                                for(i=0;i<r.filter.options.length;i++){
                                    if(r.filter.values[i] == '') r.filter.values[i] = -1;
                                    options.push( [ r.filter.values[i],r.filter.options[i] ]);
                                }
                                filter_params.options = options;
                            }
                        }else{
                            filter_params = undefined;
                        }
                }
                if(filter_params) {
                    fields_filter.push(filter_params);
                }
            }
            
            var col = gridlets[ r.gridlet ] || col_map[ r.id ] || meta_types[ r.meta_type ] || {
                dataIndex: r.category ? r.id + '_' + r.category : r.id,
                //dataIndex: r.id,
                hidden: false, width: 80, sortable: true,
                renderer: render_default
            };
            
            col = Ext.apply({},col);  // clone the column
            //col.dataIndex = r.id;
            col.dataIndex =  r.category ? r.id + '_' + r.category : r.id;
            //if( !col.dataIndex ) col.dataIndex = r.id;
            
            if( r.meta_type == 'custom_data' && r.data_key ) {
                var dk = r.data_key;
                col.renderer = function(v,m,row,ri){ return render_custom_data(dk,v,m,row,ri) };
            }
            col.hidden = false;
            
            col.alias = r.category;
            col.header = _(r.header || r.as || r.text || r.id);
            col.width = r.width || col.width;
            
            //console.log(col);
            columns.push( col );
                        if (r.ci_columns) {
                if (typeof r.ci_columns === 'string'){
                    var ci_col = {
                        //dataIndex: r.category ? r.ci_columns + '_' + r.category : r.ci_columns,
                        header: r.category + ': ' + r.ci_columns,
                        dataIndex: r.category ? r.id + '_' + r.category + '_' + r.ci_columns : r.category + '_' + r.ci_columns,
                        //dataIndex: r.id,
                        hidden: false, width: 80, sortable: true,
                        renderer: render_default
                    };
                    //console.dir( ci_col );
                    columns.push( ci_col );
                }
                else{
                    for(i=0;i<r.ci_columns.length;i++){
                        var ci_col = {
                            //dataIndex: r.category ? r.ci_columns + '_' + r.category : r.ci_columns,
                            header: r.category + ': ' + r.ci_columns[i],
                            dataIndex: r.category ? r.id + '_' + r.category + '_' + r.ci_columns[i] : r.category + '_' + r.ci_columns[i],
                            //dataIndex: r.id,
                            hidden: false, width: 80, sortable: true,
                            renderer: render_default
                        };
                        //console.dir( ci_col );
                        columns.push( ci_col );
                   }
                }

            }
        });
        //console.dir(columns);
    } else {
         columns = [ dragger, check_sm ];
         var cols = ['topic_name', 'category_name', 'category_status_name', 'ago', 'title', 'progress',
            'numcomment', 'projects', 'topic_mid', 'moniker', 'cis_out', 'cis_in', 'references_out',
            'references_in', 'assignee', 'modified_by', 'modified_on', 'created_on', 'created_by', 'current_job'];
         Ext.each( cols, function(col){
             columns.push( col_map[col] );
         });
    }
    
    var filters = new Ext.ux.grid.GridFilters({
        menuFilterText: _('Filters'),
        encode: true,
        local: false,
        filters: fields_filter
    });
    
    // toolbar
    var tbar=[ search_field ];
    if( !typeApplication ) {
        tbar = tbar.concat([ btn_add, btn_edit, btn_custom ]);
    }
    tbar = tbar.concat([ '->', btn_clear_state, btn_reports, btn_kanban, btn_mini ]);
    
    var grid_topics = new Ext.grid.GridPanel({
        region: 'center',
        //title: _('Topics'),
        //header: false,
        plugins: [filters],     
        stripeRows: true,
        autoScroll: true,
        stateful: true,
        stateId: state_id, 
        //enableHdMenu: false,
        store: store_topics,
        //enableDragDrop: true,
        dropable: true,
        autoSizeColumns: true,
        deferredRender: true,
        ddGroup: 'explorer_dd',
        viewConfig: {forceFit: force_fit},
        sm: !typeApplication ? check_sm : null,
        //loadMask:'true',
        columns: columns,
        tbar: tbar,      
        bbar: ptool
    });
    
//    grid_topics.on('rowclick', function(grid, rowIndex, columnIndex, e) {
//        //init_buttons('enable');
//    });
    
    grid_topics.on('cellclick', function(grid, rowIndex, columnIndex, e) {
        if(columnIndex == 1){
            topicsSelected();
        }
    });
    
    grid_topics.on('headerclick', function(grid, columnIndex, e) {
        if(columnIndex == 1){
            topicsSelected();
        }
    });
    
    grid_topics.on('columnresize', function(ix,newSize){
        if( newSize < 80 ) {
            topic_name_too_narrow = true;
        } else {
            topic_name_too_narrow = false;
        }
    });
    // determine if too narrow
    //var ixi = grid_topics.getColumnModel().findColumnIndex('topic_name');
	var ixi = grid_topics.getColumnModel().findColumnIndex('topic_mid');
    if( ixi ) {
        topic_name_too_narrow = grid_topics.getColumnModel().getColumnWidth(ixi) < 80;
    }

/*
    node: Ext.tree.AsyncTreeNode
    allowChildren: true
    attributes: Object
    attributes: 
        calevent: Object
        children: Array[1]
        data:
            click: Object
            topic_mid: "67183"
        expandable: true
        icon: "/static/images/icons/topic.png"
        iconCls: "no-icon"
        id: "xnode-2696"
        leaf: false
        loader: Baseliner.TreeLoader.Ext.extend.constructor
        text: "<span unselectable="on" style="font-size:0px;padding: 8px 8px 0px 0px;margin : 0px 4px 0px 0px;border : 2px solid #20bcff;background-color: transparent;color:#20bcff;border-radius:0px"></span><b>Funcionalidad #67183</b>: NAT:BIZTALK"
        topic_name: 
            category_color: "#20bcff"
            category_name: "Funcionalidad"
            is_changeset: "0"
            is_release: "0"
            mid: "67183"
        url: "/lifecycle/tree_topic_get_files"
    childNodes: Array[0]
    childrenRendered: false
    disabled: false
    draggable: true
    events: Object
    expanded: false
    firstChild: null
    hidden: false
    id: "xnode-2696"
    isTarget: true
    lastChild: null
    leaf: false
    listeners: undefined
    loaded: false
    loading: false
    nextSibling: null
    ownerTree: sb
    parentNode: Ext.tree.AsyncTreeNode
    previousSibling: Ext.tree.AsyncTreeNode
    rendered: true
    text: "<span unselectable="on" style="font-size:0px;padding: 8px 8px 0px 0px;margin : 0px 4px 0px 0px;border : 2px solid #20bcff;background-color: transparent;color:#20bcff;border-radius:0px"></span><b>Funcionalidad #67183</b>: NAT:BIZTALK"
    ui: sb
*/

    // count() is a slow business, so we defer it to after it's all loaded
    //   we also recount on every page, so that we can reset paging on results changing (TODO?)
    var deferred_count = function(st,r,o){
        var lq = st.reader.jsonData.last_query;
        if( !lq ) return;
        Cla.ajax_json('/topic/grid_count', { lq: lq }, function(res){
            if( st.totalLength != res.count ) {
                st.totalLength = res.count;
                st.baseParams.last_count = res.count;
                ptool.onLoad(st,r,o);
            }
        });
    }
    grid_topics.store.on('load', function(st,r,o) {
        deferred_count(st,r,o);
        for( var ix=0; ix < grid_topics.store.getCount(); ix++ ) {
            //var rec = grid_topics.store.getAt( ix );
            var cell = grid_topics.view.getCell( ix, 0 );
            var el = Ext.fly( cell );
            el.setStyle( 'background-color', '#ddd' );
            new Ext.dd.DragZone( el, {
                ddGroup: 'explorer_dd',
                index: ix,
                getDragData: function(e){
                    var sourceEl = e.getTarget();
                    var data = grid_topics.store.getAt( this.index ).data;
                    var d = sourceEl.cloneNode(true);
                    d.id = Ext.id();
                    var mid = data.topic_mid;
                    // TODO create topic node using the original data from attributes
                      // inject into loader? Loader.newNode or something?
                    var text = String.format('<span unselectable="on" style="font-size:0px;padding: 8px 8px 0px 0px;margin : 0px 4px 0px 0px;border : 2px solid #{1};background-color: transparent;color:#{1};border-radius:0px"></span><b>{0}</b>{2}', data.topic_name, data.category_color, '' );
                    d.innerHTML = text;
                    //text = data.topic_name;
                    var node = {
                            contains: Ext.emptyFn,
                            text: text,
                            leaf: true,
                            parentNode: Ext.emptyFn,
                            attributes: {
                                text: text,
                                icon: "/static/images/icons/topic.png",
                                iconCls: "no-icon",
                                leaf: true,
                                data: {
                                    topic_mid: mid
                                },
                                topic_name: {
                                    category_color: data.category_color,
                                    category_name: data.category_name,
                                    is_changeset: data.is_changeset,
                                    is_release: data.is_release,
                                    mid: mid
                                }
                            }
                        };
                    return {
                        ddel: d,
                        sourceEl: sourceEl,
                        repairXY: Ext.fly(sourceEl).getXY(),
                        node: node,
                        sourceStore: null,
                        draggedRecord: { }
                    };
                }
            });
        }
    });

    function topicsSelected(){
        var topics_checked = getTopics();
        if (topics_checked.length > 0 ){
            var sw_edit;
            check_sm.each(function(rec){
                sw_edit = (rec.get('sw_edit'));
            });       
            init_buttons('enable');
        }else{
            if(topics_checked.length == 0){
                init_buttons('disable');
            }
        }
    }
    function getTopics(){
        var topics_checked = new Array();
        check_sm.each(function(rec){
            topics_checked.push(rec.get('topic_mid'));
        });
        return topics_checked
    }   

    grid_topics.on("rowdblclick", function(grid, rowIndex, e ) {
        var r = grid.getStore().getAt(rowIndex);

        if ( report_type == 'custom' ) {
            Baseliner.openLogTab(r.data.job_id, r.data.nombre_job);
        } else {
            Baseliner.show_topic_from_row( r, grid_topics );
        }
    });
    
    grid_topics.on( 'render', function(){
        var el = grid_topics.getView().el.dom.childNodes[0].childNodes[1];
        var grid_topics_dt = new Baseliner.DropTarget(el, {
            comp: grid_topics,
            ddGroup: 'explorer_dd',
            copy: true,
            notifyDrop: function(dd, e, id) {
                var n = dd.dragData.node;
                var s = grid_topics.store;
                var add_node = function(node) {
                    var data = node.attributes.data;
                    // determine the row
                    var t = Ext.lib.Event.getTarget(e);
                    var rindex = grid_topics.getView().findRowIndex(t);
                    if (rindex === false ) return false;
                    var row = s.getAt( rindex );
                    var swSave = true;
                    var projects = row.get('projects');
                    if( typeof projects != 'object' ) projects = new Array();
                    for (i=0;i<projects.length;i++) {
                        var project = projects[i].split(';');
                        var project_name = project[1];
                        if(project_name == data.project){
                            swSave = false;
                            break;
                        }
                    }

                    //if( projects.name.indexOf( data.project ) == -1 ) {
                    if( swSave ) {
                        row.beginEdit();
                        
                        projects.push( data.id_project + ';' + data.project );
                        row.set('projects', projects );
                        row.endEdit();
                        row.commit();
                        
                        Baseliner.ajaxEval( '/topic/update_project',{ id_project: data.id_project, topic_mid: row.get('topic_mid') },
                            function(response) {
                                if ( response.success ) {
                                    //store_label.load();
                                    Baseliner.message( _('Success'), response.msg );
                                    //init_buttons('disable');
                                } else {
                                    //Baseliner.message( _('ERROR'), response.msg );
                                    Ext.Msg.show({
                                        title: _('Information'), 
                                        msg: response.msg , 
                                        buttons: Ext.Msg.OK, 
                                        icon: Ext.Msg.INFO
                                    });
                                }
                            }
                        
                        );
                    } else {
                        Baseliner.message( _('Warning'), _('Project %1 is already assigned', data.project));
                    }
                    
                };
                
                var add_label = function(node) {
                    var text = node.attributes.text;
                    // determine the row
                    var t = Ext.lib.Event.getTarget(e);
                    var rindex = grid_topics.getView().findRowIndex(t);
                    if (rindex === false ) return false;
                    var row = s.getAt( rindex );
                    var swSave = true;
                    var labels = row.get('labels');
                    if( typeof labels != 'object' ) labels = new Array();
                    for (i=0;i<labels.length;i++) {
                        var label = labels[i].split(';');
                        var label_name = label[1];
                        if(label_name == text){
                            swSave = false;
                            break;
                        }
                    }

                    //if( projects.name.indexOf( data.project ) == -1 ) {
                    if( swSave ) {
                        row.beginEdit();
                        
                        labels.push( node.attributes.idfilter + ';' + text + ';' + node.attributes.color );
                        row.set('labels', labels );
                        row.endEdit();
                        row.commit();
                        
                        var label_ids = new Array();
                        for(i=0;i<labels.length;i++){
                            var label = labels[i].split(';');
                            label_ids.push(label[0]);
                        }
                        Baseliner.ajaxEval( '/topic/update_topic_labels',{ topic_mid: row.get('topic_mid'), label_ids: label_ids },
                            function(response) {
                                if ( response.success ) {
                                    //store_label.load();
                                    Baseliner.message( _('Success'), response.msg );
                                    //init_buttons('disable');
                                } else {
                                    //Baseliner.message( _('ERROR'), response.msg );
                                    Ext.Msg.show({
                                        title: _('Information'), 
                                        msg: response.msg , 
                                        buttons: Ext.Msg.OK, 
                                        icon: Ext.Msg.INFO
                                    });
                                }
                            }
                        
                        );
                    } else {
                        Baseliner.message( _('Warning'), _('Label %1 is already assigned', text));
                    }
                    
                };              
                
                var attr = n.attributes;
                if(attr.data){
                    if( typeof attr.data.id_project == 'undefined' ) {  // is a project?
                        //Baseliner.message( _('Error'), _('Node is not a project'));
                    } else {
                        add_node(n);
                    }
                }
                else{
                    if(n.parentNode.attributes.id == 'L'){
                        add_label(n);
                    }else{
                        //Baseliner.message( _('Error'), _('Node is not a label'));
                    }
                    
                }
                // multiple? Ext.each(dd.dragData.selections, add_node );
                return (true); 
             }
        });
        
    }); 

   
    var render_color = function(value,metadata,rec,rowIndex,colIndex,store) {
        return "<div width='15' style='border:1px solid #cccccc;background-color:" + value + "'>&nbsp;</div>" ;
    };  

    function loadfilters( unselected_node ){
        var labels_checked = new Array();
        var statuses_checked = new Array();
        var categories_checked = new Array();
        var priorities_checked = new Array();
        var type;
        var selected_views = { };
        
        selNodes = tree_filters.getChecked();
        if( selNodes.length > 0 ) button_no_filter.enable();
          else button_no_filter.disable();
          

        for( var i=0; i<selNodes.length; i++ ) {
            var node = selNodes[ i ];
            type = node.parentNode.attributes.id;
            //if (type == 'C') console.log(node);
            var node_value = node.attributes.checked3 == -1 ? -1 * (node.attributes.idfilter) : node.attributes.idfilter;
            switch (type){
                //Views
                case 'V':   
                            var d = Ext.util.JSON.decode(node.attributes.filter);
                            if( d.query !=undefined && selected_views.query !=undefined ) {
                                d.query = d.query + ' ' + selected_views.query;
                            }
                            selected_views = Baseliner.merge(selected_views, d );
                            break;
                //Labels
                case 'L':   labels_checked.push(node_value);
                            //labels_checked.push(node.attributes.idfilter);
                            break;
                //Statuses
                case 'S':   statuses_checked.push(node_value);
                            //statuses_checked.push(node.attributes.idfilter);
                            break;
                //Categories
                case 'C':   categories_checked.push(node_value);
                            //categories_checked.push(node.attributes.idfilter);
                            break;
                //Priorities
                case 'P':   priorities_checked.push(node_value);
                            //priorities_checked.push(node.attributes.idfilter);
                            break;
            }
        }
        filtrar_topics(selected_views, labels_checked, categories_checked, statuses_checked, priorities_checked, unselected_node);
    }
    
    function filtrar_topics(selected_views, labels_checked, categories_checked, statuses_checked, priorities_checked, unselected_node){
        // copy baseParams for merging
        var bp = store_topics.baseParams;
        var base_params;
        if( bp !== undefined )
            base_params= { start: bp.start, limit: ps, sort: bp.sort, dir: bp.dir, typeApplication: typeApplication, topic_list: params.topic_list, id_project: id_project ? id_project : undefined, categories: category_id ? category_id : undefined, statuses: status_id, clear_filter: params.clear_filter  };        // object for merging with views 
        var selected_filters = {labels: labels_checked, categories: categories_checked, statuses: statuses_checked, priorities: priorities_checked};
        

        // merge selected filters with views
        var merge_filters = Baseliner.merge( selected_views, selected_filters);
        // now merge baseparams (query, limit and start) over the resulting filters
        var filter_final = Baseliner.merge( merge_filters, base_params );
        // query and unselected
        
        
        //if( unselected_node != undefined ) {
        //    var unselected_type = unselected_node.parentNode.attributes.id;
        //    var unselected_filter = Ext.util.JSON.decode(unselected_node.attributes.filter);
        //    if( unselected_type == 'V' ) {
        //        if( bp.query == unselected_filter.query ) {
        //            filter_final.query = '';
        //        } else {
        //            filter_final.query = bp.query.replace( unselected_filter.query, '' );
                    filter_final.query = bp.query;
                    //filter_final.query = filter_final.query.replace( /^ +/, '' );
                    //filter_final.query = filter_final.query.replace( / +$/, '' );
        //        }
        //    }
        //}
        //else if( selected_views.query != undefined  && bp.query != undefined ) {
        //    //filter_final.query = bp.query + ' ' + selected_views.query;
        //}

        //if( base_params.query !== filter_final.query ) {
            //delete filter_final['query'];    
        //}
        //console.dir(filter_final);
        
        if (statuses_checked.length == 0) filter_final.clear_filter = 1
        
        store_topics.baseParams = filter_final;
        search_field.setValue( filter_final.query );
        store_topics.load();
        filter_current = filter_final;
    };


    var tree_root = new Ext.tree.AsyncTreeNode({
                text: 'Filters',
                expanded: true
            });

    var tree_filters = {};
    
    function checkchange(node_selected, checked) {
        var type = node_selected.parentNode.attributes.id;
        if (!changing  ) {
            //if (type != 'V') {
                changing = true;
                var c3 = node_selected.attributes.checked3;
                node_selected.getUI().toggleCheck( c3 );
                changing = false;
            //}
        
        
            if( stop_filters ) return;
            
            var swDisable = true;
            var selNodes = tree_filters.getChecked();
            var tot_view_defaults = 1;
            //Ext.each(selNodes, function(node){
            //  
            //  var type = node.parentNode.attributes.id;
            //  if(type == 'V'){
            //      //if(!eval('node.attributes.default')){   //Eval, I.E
            //      if(!node.attributes['default']){   // I.E 8.0
            //          button_delete_view.enable();
            //          swDisable = false;
            //          return false;
            //      }else{
            //          if(selNodes.length == tot_view_defaults){
            //              swDisable = true;
            //          }else{
            //              swDisable = false;
            //          }
            //      }
            //  }else{
            //      swDisable = true;
            //  }
            //});
            
            if (swDisable)
                button_delete_view.disable();
                
            if( checked ) {
                loadfilters();
            } else {
                loadfilters( node_selected );
            }
        }
    }
    
    if( !id_report ) {
        var id_collapse = Ext.id();
        tree_filters = new Ext.tree.TreePanel({
            region : 'east',
            header: false,
            hidden: !!id_report,
            width: 210,
            split: true,
            collapsible: true,
            tbar: [
                button_no_filter, '->',
                //button_create_view,
                //button_delete_view,
                '<div class="x-tool x-tool-expand-west" style="margin:-2px -4px 0px 0px" id="'+id_collapse+'"></div>'
            ],
            dataUrl: "/topic/filters_list" + parse_typeApplication,
            split: true,
            colapsible: true,
            useArrows: true,
            animate: true,
            autoScroll: true,
            rootVisible: false,
            root: tree_root,
            enableDrag: true,
            enableDrop: false,
            ddGroup: 'explorer_dd',
            listeners: {
                'checkchange': checkchange
            }       
        });
        
        tree_filters.getLoader().on("beforeload", function(treeLoader, node) {
            var loader = tree_filters.getLoader();
            if(category_id){
                loader.baseParams = {category_id: category_id}; 
            }
            if(status_id){
                loader.baseParams = {status_id: status_id}; 
            }       
            
        }); 
        
        var changing = false;
        
        tree_filters.on('beforechildrenrendered', function(node){
            /* Changing node text
            node.setText( String.format('<span>{0}</span><span style="float:right; margin-right:1px">{1}</span>',
                node.text,
                '<img src="/static/images/icons/config.gif" onclick="Baseliner.aaa()" />'  )
            );
            */
            if(node.attributes.id == 'C' || node.attributes.id == 'L'){
                node.eachChild(function(n) {
                    //console.log(n.getUI());
                    var color = n.attributes.color;
                    if( ! color ) color = '#999';
                    var style = document.createElement('style');
                    var head = document.getElementsByTagName('head')[0];
                    var rules = document.createTextNode(
                        '.forum.dinamic' + n.id + ' a span { margin-left: 5px; padding: 1px 4px 2px;;-webkit-border-radius: 3px;-moz-border-radius: 3px;border-radius: 3px;color: #fff;' 
                         + ';background: ' + color +
                        ';font-family:Helvetica Neue,Helvetica,Arial,sans-serif;font-size: xx-small; font-weight:bolder;}'
                    );
                    style.type = 'text/css';
                    if(style.styleSheet) {
                        style.styleSheet.cssText = rules.nodeValue;
                    } else {
                        style.appendChild(rules);
                    }
                    head.appendChild(style);
                    n.attributes.cls = 'forum dinamic' + n.id;
                });
            }
        });
        
        // expand the whole tree
        tree_filters.getLoader().on( 'load', function(){
            tree_root.expandChildNodes();

            // draw the collapse button onclick event 
            var el_collapse = Ext.get( id_collapse );
            if( el_collapse ){
                el_collapse.dom.onclick = function(){ 
                    panel.body.dom.style.overflow = 'hidden'; // collapsing shows overflow, so we hide it
                    tree_filters.collapse();
                };
            }
            // select filter for current category
            //////if( params.id_category ){
            //////    var chi = tree_filters.root.findChild('idfilter', params.id_category, true );
            //////    if( chi ) chi.getUI().toggleCheck(true);
            //////
            //////}
        });
            
    } // if !id_report
        
    var panel = new Ext.Panel({
        layout : "border",
        defaults: {layout:'fit'},
        title: _('Topics'),
        //tab_icon: '/static/images/icons/topic.png',
        items : [
            grid_topics,
            custom_panel,
            tree_filters  // show only if not report
        ]
    });
    /* change style for 'Topics' tab! */
    if( params.tabTopic_force==1 ) {
        panel.tab_icon = ''; // removes icon 
        panel.title_force = '<span style="margin-left:10px;margin-right:10px;height: 13px"><img src="/static/images/icons/topic.png" /></span>'; // removes title
    }
        
    grid_topics.on('afterrender', function(){
        grid_topics.loadMask = new Ext.LoadMask(grid_topics.bwrap, { msg: _('Loading'), store: store_topics });
        store_topics.load({
            params: {
                start:0 , limit: ps,
                topic_list: params.topic_list,
                query_id: params.query_id, 
                typeApplication: typeApplication
            }
        });
    });
    //store_label.load();
    
    panel.print_hook = function(){
        return { title: grid_topics.title, id: Baseliner.grid_scroller( grid_topics ).id };
    };

    return panel;
}
