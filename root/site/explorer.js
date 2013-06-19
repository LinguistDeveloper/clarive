Baseliner.user_can_edit_ci = <% $c->model('Permissions')->user_has_any_action( action => 'action.ci.%', username=>$c->username ) ? 'true' : 'false' %>;
Baseliner.user_can_job = <% $c->model('Permissions')->user_projects( username=>$c->username ) ? 'true' : 'false' %>;
Baseliner.user_can_workspace = <% $c->model('Permissions')->user_has_any_action( action=>'action.home.view_workspace', username=>$c->username ) ? 'true' : 'false' %>;


Baseliner.tree_topic_style = [
    '<span unselectable="on" style="font-size:0px;',
    'padding: 8px 8px 0px 0px;',
    'margin : 0px 4px 0px 0px;',
    'border : 2px solid {0};',
    'background-color: transparent;',
    'color:{0};',
    'border-radius:0px"></span>'
].join('');

var base_menu_items = [ ];

// only one right click menu showed at once, so create a static entity
Baseliner.explorer_menu = new Ext.menu.Menu({
    items: base_menu_items,
    listeners: {
        itemclick: function(item) {
            switch (item.id) {
                case 'delete-node':
                    var n = item.parentMenu.contextNode;
                    if (n.parentNode) {
                        n.remove();
                    }
                    break;
            }
        }
    }
});

/*
 * Baseliner.TreeLoader
 *
 *   - manages node attribute url and params 
 *   - paging (TODO)
 *
 */

Baseliner.TreeLoader = Ext.extend( Ext.tree.TreeLoader, {
    constructor: function(c) {
        Baseliner.TreeLoader.superclass.constructor.call(this,c);
        var self = this;
        self.id = Ext.id();
        
        this.on("beforeload", function(loader, node) {
            // save params
            self.$baseParams = Ext.apply( {}, self.baseParams );
            self.$dataUrl = self.dataUrl;
            // take URL from a node attribute
            if( node.attributes.url != undefined ) {
                self.dataUrl = node.attributes.url;
            }
            // apply node params to this params
            self.baseParams = Ext.apply( {}, node.attributes.data, self.baseParams );
        });
        this.on("load", function(loader, node) {
            // reset params back
            self.baseParams = self.$baseParams;  
            self.dataUrl = self.$dataUrl;  
        });
    }
});


/*
 * Baseliner.TreeMultiTextNode
 *
 */

Baseliner.TreeMultiTextNode = Ext.extend( Ext.tree.TreeNodeUI, {
    getDDHandles : function(){
        var nodes = [this.iconNode, this.textNode, this.elNode];
        Ext.each( this.textNode.childNodes, function(n){ nodes.push(n) });
        return nodes;
    }
});

/*
 * Baseliner.Tree
 *
 * Features:
 *
 *   - context menu from node
 *   - drag and drop ready
 *   - paging (TODO)
 *
 */

Baseliner.Tree = Ext.extend( Ext.tree.TreePanel, {
    useArrows: true,
    autoScroll: true,
    animate: true,
    enableDD: true,
    containerScroll: true,
    rootVisible: false,
    constructor: function(c){
        var self = this;
        
        Baseliner.Tree.superclass.constructor.call(this, Ext.apply({
            loader: new Baseliner.TreeLoader({ 
                        dataUrl: c.dataUrl,
                        requestMethod: this.requestMethod, 
                        baseParams: c.baseParams }),
            root: { nodeType: 'async', text: '/', draggable: false, id: '/' }
        }, c) );
        
        self.on('contextmenu', self.menu_click );
        self.on('beforenodedrop', self.drop_handler );
        self.on('dblclick', function(n, ev){     
            if( n.leaf ) 
                self.click_handler({ node: n });
        });
    },
    drop_handler : function(e) {
        var self = this;
        // from node:1 , to_node:2
        e.cancel = true;
        e.dropStatus = true;
        var n1 = e.source.dragData.node;
        var n2 = e.target;
        if( n1 == undefined || n2 == undefined ) return false;
        
        var node_data1 = n1.attributes.data;
        var node_data2 = n2.attributes.data;
        if( node_data1 == undefined ) node_data1={};
        if( node_data2 == undefined ) return false;
        if( node_data2.on_drop != undefined ) {
            var on_drop = node_data2.on_drop;
            if( on_drop.url != undefined ) {
                var p = { tree: self, node1: n1, node2: n2, id_file: node_data1.id_file  };
                if( n2.parentNode && n2.parentNode.attributes.data ) 
                    p.id_project = n2.parentNode.attributes.data.id_project
                        
                Baseliner.ajaxEval( on_drop.url, p, function(res){
                    if( res ) {
                        if( res.success ) {
                            Baseliner.message(  _('Drop'), res.msg );
                            //e.target.appendChild( n1 );
                            //e.target.expand();
                            self.refresh_node( e.target );
                        } else {
                            Baseliner.message( _('Drop'), res.msg );
                            //Ext.Msg.alert( _('Error'), res.msg );
                            return false;
                        }
                    } else {
                        return true;
                    }
                });
            }else{
                if(on_drop.handler != undefined ){
                    eval(on_drop.handler + '(n1, n2);');                
                }
            }
        }
        return true;
    },
    click_handler: function(item){
        var n = item.node;
        var c = n.attributes.data.click;
        var params = n.attributes.data;
        
        if(n.attributes.text == _('Topics')){
            params.id_project = n.parentNode.attributes.data.id_project;
        }
        if( params.tab_icon == undefined ) params.tab_icon = c.icon;

        if( c.type == 'comp' ) {
            Baseliner.add_tabcomp( c.url, _(c.title), params );
        } else if( c.type == 'html' ) {
            Baseliner.add_tab( c.url, _(c.title), params );
        } else if( c.type == 'iframe' ) {
            Baseliner.add_iframe( c.url, _(c.title), params );
        } else {
            Baseliner.message( 'Invalid or missing click.type', '' );
        }
    },
    refresh : function(){
        var self = this;
        var sm = self.getSelectionModel();
        var node = sm.getSelectedNode();
        if( node )
            self.refresh_node( node );
        else 
            self.refresh_all();
    },
    refresh_all : function(){
        var self = this;
        this.loader.load(self.root);
    },
    refresh_node : function(node){
        var self = this;
        if( node != undefined ) {
            var is = node.isExpanded();
            self.loader.load( node );
            if( is ) node.expand();
        }
    }
});

Baseliner.ExplorerTree = Ext.extend( Baseliner.Tree, {
    ddGroup: 'explorer_dd',
    initComponent : function(){
        var self = this;
        
        Baseliner.ExplorerTree.superclass.initComponent.call(this);
        
        self.addEvents( 'favorite_added' );
        
        self.on('beforechildrenrendered', function(node){
            node.eachChild(function(n) {
                if(n.attributes.topic_name ) {
                    var tn = n.attributes.topic_name;
                    n.setIconCls('no-icon');  // no icon on this node

                    if( !tn.category_color ) 
                        tn.category_color = '#999';
                    //tn.style = 'font-size:10px';
                    //tn.style = String.format('font-size:9px; margin: 2px 2px 2px 2px; border: 1px solid {0};background-color: #fff;color:{0}', tn.category_color);
                    //tn.style = String.format('font-size:9px; margin: 2px 2px 2px 2px; border: 1px solid {0};background-color: #fff;color:{0}', tn.category_color);
                    var span = String.format( Baseliner.tree_topic_style, tn.category_color );

                    //tn.mini = true;
                    //var tn_span = Baseliner.topic_name(tn);

                    n.setText( String.format( '{0}<b>{1} #{2}</b>: {3}', span, tn.category_name, tn.mid, n.text ) );
                    n.ui = new Baseliner.TreeMultiTextNode( n );

                    /* n.setText( String.format('<span id="boot"><span class="label" style="font-size:10px;background-color:{0}">#{1}</span></span> {2}',
                        n.attributes.topic_name.category_color, n.attributes.topic_name.mid, n.text ) ); */
                }
            });
        });
    },
    menu_favorite_add : function(){
        var self = this;
        return {
            text: _('Add to Favorites...'),
            icon: '/static/images/icons/favorite.png',
            handler: function(n) {
                var sm = self.getSelectionModel();
                var node = sm.getSelectedNode();
                if( node != undefined ) {
                    var name = new Array();
                    node.bubble( function(pnode){
                       if( pnode.text != '/' && pnode.text != undefined ) 
                          name.unshift( pnode.text ); 
                    });
                    Baseliner.ajaxEval( '/lifecycle/favorite_add',
                        {
                            text: name.join(':'),
                            url: node.attributes.url,
                            icon: node.attributes.icon,
                            data: Ext.encode( node.attributes.data ),
                            menu: Ext.encode( node.attributes.menu )
                        },
                        function(res) {
                            self.fireEvent( 'favorite_added', res );
                            Baseliner.message( _('Favorite'), res.msg );
                        }
                    );
                }
            }
        };
    },
    menu_favorite_del : function(){
        var self = this;
        return {
            text: _('Remove from Favorites'),
            icon: '/static/images/icons/favorite.png',
            handler: function(n) {
                var sm = self.getSelectionModel();
                var node = sm.getSelectedNode();
                if( node != undefined ) {
                    Baseliner.ajaxEval( '/lifecycle/favorite_del',
                        { id: node.attributes.id_favorite, favorite_folder: node.attributes.favorite_folder, id_folder: node.attributes.id_folder },
                        function(res) {
                            Baseliner.message( _('Favorite'), res.msg );
                            node.remove();
                        }
                    );
                }
            }
        };
    },
    menu_favorite_rename : function(){
        var self = this;
        return {
            text: _('Rename'),
            icon: '/static/images/icons/rename.gif',
            handler: function(n) {
                var sm = self.getSelectionModel();
                var node = sm.getSelectedNode();
                if( node ) {
                    Ext.Msg.prompt(_('Rename'), _('New name:'), function(btn, text){
                        if( btn == 'ok' ) {
                            Baseliner.ajaxEval( '/lifecycle/favorite_rename',
                                { id: node.attributes.id_favorite, favorite_folder: node.attributes.favorite_folder, id_folder: node.attributes.id_folder, text: text },
                                function(res) {
                                    Baseliner.message( _('Favorite'), res.msg );
                                    if( res.success ) node.setText( text );
                                }
                            );
                        }
                    }, this, false, node.text );
                }
            }
        };
    },
    menu_click : function(node,event){
        var self = this;
        node.select();
        
        // menus and click events go in here
        if( node.attributes.menu || ( node.attributes.data && node.attributes.data.click ) ) {

            var m = Baseliner.explorer_menu;
            m.removeAll(); 
            var node_menu_items = new Array(); 

            // click turns into a menu-item Open...
            var click = node.attributes.data.click;
            if( click != undefined && click.url != undefined ) {
                var menu_item = new Ext.menu.Item({
                    text: _( 'Open...' ),
                    icon: '/static/images/icons/tab.png',
                    node: node,
                    handler: self.click_handler
                });
                node_menu_items.push( menu_item );
            }

            if( node.attributes.menu ) {
                var node_menu = node.attributes.menu;
                // create js handlers for menu items
                for( var i = 0; i < node_menu.length; i++ ) {
                    var menu_item = node_menu[i];
                    menu_item.text = _( menu_item.text ); 
                    var url = "";
                    // component opener menu
                    if( menu_item.comp != undefined ) {
                        url = menu_item.comp.url;
                        menu_item.click_data = { action: menu_item.comp }; // need this before to preserve scope
                        menu_item.handler = function(item) {
                            item.click_data.node = item.node;   
                            var d = { node: item.node, action: menu_item.comp };
                            Baseliner.add_tabcomp( item.url, _(menu_item.comp.title), d );
                        };
                    } else if( menu_item.page != undefined ) {
                        url = menu_item.page.url;
                        menu_item.click_data = { action: menu_item.page }; // need this before to preserve scope
                        menu_item.handler = function(item) {
                            item.click_data.node = item.node;   
                            var d = { node: item.node, action: menu_item.page, tab_icon: menu_item.icon };
                            Baseliner.add_tab( item.url, _(menu_item.page.title), d );
                        };
                    } else if( menu_item.eval != undefined ) {
                        url = menu_item.eval.url;
                        menu_item.click_data = { action: menu_item.eval }; // need this before to preserve scope
                        menu_item.handler = function( item ) {
                            item.click_data.node = item.node;
                            //Preguntar comportamiento a rodrigo, accion cliente ¿?
                            //***************************************************************************************
                            if(item.eval.handler){
                                eval(item.eval.handler + '(item.node);');
                            }
                            else{
                                Baseliner.ajaxEval( item.url, item.click_data , function(comp) {
                                    // no op
                                    var x = 0;
                                });
                            }
                        };
                    }
                    var item = new Ext.menu.Item(menu_item);
                    node_menu_items.push( item );
                    //item.node = node.attributes; // stash it here
                    item.node = node; // stash it here, otherwise things get out of scope
                    item.url  = url;
                }
            }
            m.add( node_menu_items );
            if( node_menu_items.length > 0 ) m.add('-');
        } else {
            var m = Baseliner.explorer_menu;
            m.removeAll(); 
        }
        // add base menu
        m.add( base_menu_items );
        if( node.attributes != undefined && node.attributes.id_favorite !=undefined ) {
            m.add( this.menu_favorite_del() );
            m.add( this.menu_favorite_rename() );
        } else {
            m.add( this.menu_favorite_add() );
        }
        if( Baseliner.DEBUG ) {
            m.add({ text: _('Properties'), icon:'/static/images/icons/properties.png', handler: function(n){
                var sm = self.getSelectionModel();
                var node = sm.getSelectedNode();
                var d = node.attributes;
                var loader = d.loader;
                delete d['loader'];
                var de = new Baseliner.DataEditor({ data: { id: node.id, attributes: d, text: node.text } });
                var dump_win = new Ext.Window({ width: 800, height: 400, layout:'fit', items:de });
                dump_win.show();
                de.on('destroy', function(){ dump_win.close() });
                //node.attributes.loader = loader;
            }});
        }
        m.add({
            text: _('Refresh Node'),
            cls: 'x-btn-text-icon',
            icon: '/static/images/icons/refresh.gif',
            handler: function() { self.refresh() }
        });
        Baseliner.explorer_menu.showAt(event.xy);
    }
});


/*
 *
 *  Baseliner.Explorer - main left card panel
 *
 *
 */

Baseliner.Explorer = Ext.extend( Ext.Panel, {
    layout: 'card',
    region: 'west',
    activeItem: 0,
    split: true,
    header: false,
    title: _("Explorer"),  // not shown by default
    width: 250,
    constructor: function(c){
        // collapsible not working in default attributes
        Baseliner.Explorer.superclass.constructor.call(this,Ext.apply({ collapsible: true }, c ));
    },
    initComponent: function(){
        var self = this;

        
        var show_projects = function() {
            if( !self.$tree_projects ) {
                self.$tree_projects = new Baseliner.ExplorerTree({ dataUrl : '/lifecycle/tree' })
                self.$tree_projects.on('favorite_added', function() { if( self.$tree_favorites ) self.$tree_favorites.refresh() });
                self.add( self.$tree_projects );
            }
            self.getLayout().setActiveItem( self.$tree_projects );
        };

        var show_favorites = function() {
            if( !self.$tree_favorites ) {
                self.$tree_favorites = new Baseliner.ExplorerTree({ dataUrl : '/lifecycle/tree' , baseParams: { favorites: true } });
                self.add( self.$tree_favorites );
            }
            self.getLayout().setActiveItem( self.$tree_favorites );
        };

        var show_workspaces = function() {
            if( !self.$tree_workspaces ) {
                self.$tree_workspaces = new Baseliner.ExplorerTree({ dataUrl : '/lifecycle/tree', baseParams: { show_workspaces: true } });
                self.add( self.$tree_workspaces );
                self.$tree_workspaces.on('favorite_added', function() { self.$tree_favorites.refresh() } );
            }
            self.getLayout().setActiveItem( self.$tree_workspaces );
        };

        var show_ci = function() {
            if( !self.$tree_ci ) {
                self.$tree_ci = new Baseliner.ExplorerTree({ dataUrl : '/lifecycle/tree', baseParams: { show_ci: true }  });
                self.add( self.$tree_ci );
                self.$tree_ci.on('favorite_added', function() { self.$tree_favorites.refresh() } );
            }
            self.getLayout().setActiveItem( self.$tree_ci );
        };

        var button_projects = new Ext.Button({
            cls: 'x-btn-icon',
            icon: '/static/images/icons/project.png',
            handler: show_projects,
            tooltip: _('Projects'),
            pressed: false,
            toggleGroup: 'explorer-card',
            allowDepress: false,
            hidden: ! Baseliner.user_can_job,
            enableToggle: true
        });

        var button_favorites = new Ext.Button({
            cls: 'x-btn-icon',
            icon: '/static/images/icons/star-gray.png',
            tooltip: _('Favorites'),
            handler: show_favorites,
            pressed: true,
            allowDepress: false,
            toggleGroup: 'explorer-card',
            enableToggle: true
        });

        var button_workspaces = new Ext.Button({
            cls: 'x-btn-icon',
            icon: '/static/images/icons/workspaces.png',
            handler: show_workspaces,
            tooltip: _('Workspaces'),
            toggleGroup: 'explorer-card',
            pressed: false,
            allowDepress: false,
            enableToggle: true,
            hidden: ! Baseliner.user_can_workspace,
        });

        var button_ci = new Ext.Button({
            cls: 'x-btn-icon',
            icon: '/static/images/ci/ci-grey.png',
            handler: show_ci,
            tooltip: _('Configuration Items'),
            toggleGroup: 'explorer-card',
            pressed: false,
            allowDepress: false,
            hidden: ! Baseliner.user_can_edit_ci,
            enableToggle: true
        });

        var add_to_fav_folder = function() {
            Ext.Msg.prompt(_('Favorite'), _('Folder name:'), function(btn, folder){
                if( btn == 'ok' ) {
                    var on_drop = { url: '/comp/lifecycle/add_to_fav_folder.js' };
                    Baseliner.ajaxEval( '/lifecycle/favorite_add',
                        {
                            text: folder,
                            id_folder: folder,
                            data: Ext.util.JSON.encode({ on_drop: on_drop }),
                            icon: '/static/images/icons/favorite.png'
                        },
                        function(res) {
                            Baseliner.message( _('Favorite'), res.msg );
                            if( res.success ) {
                                var new_node = self.$tree_favorites.getLoader().createNode({
                                    text: folder + ' ('+res.id_folder+')',
                                    icon: '/static/images/icons/favorite.png',
                                    data: { on_drop: on_drop },
                                    url: '/lifecycle/tree_favorite_folder?id_folder=' + res.id_folder
                                });
                                self.$tree_favorites.root.appendChild( new_node );
                            }
                        }
                    );
                }
            });
        };

        var add_workspace = function() {
            Baseliner.ajaxEval( '/comp/lifecycle/workspace_new.js', {}, function(){} );
        };

        var button_menu = new Ext.Button({
            //cls: 'x-btn-icon',
            //icon: '/static/images/icons/config.gif',
            tooltip: _('Config'),
            menu: [
                { text: _('Add Favorite Folder'), icon: '/static/images/icons/favorite.png', handler: add_to_fav_folder }
            ]
            // menu: [
            //     { text: _('Add Favorite Folder'), icon: '/static/images/icons/favorite.png', handler: add_to_fav_folder },
            //     { text: _('Add Workspace'), handler: add_workspace }
            // ]
        });

        self.tbar = new Ext.Toolbar({
            items: [
                {   xtype:'button', 
                    cls: 'x-btn-text-icon',
                    icon: '/static/images/icons/refresh-grey.gif',
                    handler: function(){
                        self.current_tree().refresh();
                    }
                },
                button_projects,
                button_favorites,
                button_workspaces,
                button_ci,
                '->',
                button_menu,
                new Ext.Component({
                    cls: 'x-tool x-tool-expand-east', 
                    style: 'margin: -2px 0px 0px 0px',
                    listeners: {
                        'afterrender': function(d){
                            d.el.on('click', function(){
                                self.collapse();
                            });
                        }
                    }
                })
            ]
        });

        Baseliner.Explorer.superclass.initComponent.call(this);
        self.on('afterrender', function(){ show_favorites() });
    },
    current_tree : function(){
        return this.getLayout().activeItem;
    }
});


/* ------------- Folder Functions ------------- */

Baseliner.TextFieldWin = Ext.extend( Ext.Window, {
    modal: true, 
    autoHeight: true, 
    width: 300,
    constructor: function(c){
        Baseliner.TextFieldWin.superclass.constructor.call(this, c);
    },
    initComponent: function(){
        var self = this;
        self.addEvents('saved','save_error');
        Baseliner.TextFieldWin.superclass.initComponent.call(this);
        
        var btn_cerrar = new Ext.Toolbar.Button({
            text: _('Close'),
            width: 50,
            handler: function() { self.close(); }
        });
        var btn_grabar = new Ext.Toolbar.Button({
            text: _('Save'),
            width: 50,
            handler: function(){self.submit_form()}
        });
        
        self.text_field = new Ext.form.TextField({
            fieldLabel: self.field_label,
            name: 'name',
            value: self.default_text, allowBlank: false
        });
        
        self.form_folder = new Ext.FormPanel({
                                name: self.form_folder,
                                url: self.url,
                                frame: true,
                                keys: [{ key: Ext.EventObject.ENTER, fn: function(){self.submit_form()} }],
                                buttons: [btn_grabar, btn_cerrar],
                                defaults:{anchor:'100%'},
                                items: self.text_field
        });
        self.text_field.on('afterrender', function(){ 
            setTimeout(function(){
                self.text_field.focus(true);
            },200);
        });
        
        self.add( self.form_folder );
    },
    value : function(v){
        if( v )
            this.text_field.setValue( v );
        return this.text_field.getValue(); 
    },
    submit_form : function(){
        var self = this;
        var form = self.form_folder.getForm();
        var data = self.data;

        if (form.isValid()) {
            form.submit({
                params: { parent_id: data.id_directory, project_id: data.id_project },
                success: function(f,a){
                    Baseliner.message(_('Success'), a.result.msg );
                    self.fireEvent('saved', a.result, self);
                    if( self.close_on_save ) 
                        self.close();
                },
                failure: function(f,a){
                    Baseliner.error( _('Error'), _(a.result.msg) );
                    self.fireEvent('save_error', a.result, self);
                }
            });
        }
    }
});

Baseliner.new_folder = function(node){
    var win = new Baseliner.TextFieldWin({
        title: _('New Folder'),
        field_label: _('Name'),
        url:'/fileversion/new_folder',
        data: node.attributes.data
    });
    
    win.on('saved', function(res){
        if(node.isExpanded()){
            if( res.node ) 
                node.appendChild( res.node );
        };
    });
    win.show();
};

Baseliner.rename_folder = function(node){
    var win = new Baseliner.TextFieldWin({
        title: _('Rename Folder'),
        field_label: _('Name'),
        url:'/fileversion/rename_folder',
        close_on_save: true,
        default_text: node.text,
        data: node.attributes.data
    });
    win.on('saved', function(res){
        node.setText( res.name );
    });
    win.show();
};

Baseliner.delete_folder = function(node){
    Baseliner.ajaxEval( '/fileversion/delete_folder',{ id_directory: node.attributes.data.id_directory },
        function(response) {
            if ( response.success ) {
                Baseliner.message( _('Success'), response.msg );
                node.remove();
                //refresh_node(node.parentNode);  // XXX now it's a method not global func
            } else {
                Baseliner.message( _('ERROR'), response.msg );
            }
        }
    
    );    
};

// Main event that gets fired everytime a node is right-clicked
//    builds the menu from node attributes and base menu
Baseliner.move_folder_item = function(node_data1, node_data2){
    if(node_data2.attributes.data.type != 'file'){
        node_data2.appendChild( node_data1 );

        data_from = node_data1.attributes.data;
        data_to = node_data2.attributes.data;
        data_from_type = data_from.type || 'topic';
        Baseliner.ajaxEval( '/fileversion/move_' + data_from_type,{ from_file: data_from.id_file,
                                                                    from_directory: data_from.id_directory,
                                                                    from_topic_mid: data_from.topic_mid,
                                                                    to_directory: data_to.id_directory,
                                                                    project: data_to.id_project},
            function(response) {
                if ( response.success ) {
                    Baseliner.message( _('Success'), response.msg );
                } else {
                    Baseliner.message( _('ERROR'), response.msg );
                }
            }
        
        );    
    }else{
        Baseliner.message( _('ERROR'), _('Error moving file') );
    }
}

Baseliner.open_topic_grid_from_folder = function(n){
    var name = n.text;
    var id_directory = n.attributes.data.id_directory;
    Baseliner.ajaxEval( '/fileversion/topics_for_folder', { id_directory: id_directory }, function(res){
        Baseliner.add_tabcomp('/comp/topic/topic_grid.js', _('Topics: %1', name), { topic_list: res.topics, tab_icon: '/static/images/icons/topic.png' });
    });
}

Baseliner.open_kanban_from_folder = function(n){
    var name = n.text;
    var id_directory = n.attributes.data.id_directory;
    Baseliner.ajaxEval( '/fileversion/topics_for_folder', { id_directory: id_directory }, function(res){
        if( ! res.topics || res.topics.length < 1 ) {
            Baseliner.message( _('Kanban'), _('Folder does not contain any topics') );
            return;
        }
        var store_topics = new Baseliner.Topic.StoreList({
            baseParams: { start: 0, topic_list: res.topics }
        });
        store_topics.load();
        store_topics.on('load', function(){
            Baseliner.kanban_from_store({ store: store_topics }); 
        });
    });
}
