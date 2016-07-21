Baseliner.user_can_edit_ci = <% $c->model('Permissions')->user_has_any_action( action => 'action.ci.%', username=>$c->username ) ? 'true' : 'false' %>;
Baseliner.user_can_projects = <% $c->model('Permissions')->user_projects( username=>$c->username ) ? 'true' : 'false' %>;
Baseliner.user_can_workspace = <% $c->model('Permissions')->user_has_any_action( action=>'action.home.view_workspace', username=>$c->username ) ? 'true' : 'false' %>;
Baseliner.user_can_releases = <% $c->model('Permissions')->user_has_any_action( action=>'action.home.view_releases', username=>$c->username ) ? 'true' : 'false' %>;
Baseliner.user_can_reports = <% $c->model('Permissions')->user_has_any_action( action=>'action.reports.view', username=>$c->username ) ? 'true' : 'false' %>;
Baseliner.user_can_dashboards = <% $c->model('Permissions')->user_has_any_action( action=>'action.dashboards.view', username=>$c->username ) ? 'true' : 'false' %>;

var base_menu_items = [ ];

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
        
        self.on("beforeload", function(loader, node) {
            // save params
            self.$baseParams = Ext.apply( {}, self.baseParams );
            self.$dataUrl = self.dataUrl;
            // take URL from a node attribute
            if( node.attributes.url != undefined ) {
                self.dataUrl = node.attributes.url;
            }
            // apply node params to this params
            self.baseParams = Ext.apply( { '_bali_notify_valid_session': true }, node.attributes.data, self.baseParams );
        });
        self.on("load", function(loader, node) {
            // reset params back
            self.baseParams = self.$baseParams;  
            self.dataUrl = self.$dataUrl;
        });
        self.on("loadexception", function(loader, node, res) {
            var obj = {};
            try {
                obj = Ext.util.JSON.decode( res.responseText );
            } catch(e){
                obj = {};
            }
            if( ! Ext.isObject(obj) ) obj={};
            if( res.status == 401 || obj.logged_out ) {
                Baseliner.login({ no_reload: 1, on_login: function(){ 
                    loader.load( node );
                }});
            } else if( ! obj.success )  {
                Baseliner.error( _('Error'), obj.msg || res.responseText );
            } else if( res.status == 0 ) {
                alert( _('Server not available') );  // an alert does not ask for images from the server
            } else {
                // may be a programming error in the js side (treeloader event?), no message to show
                Baseliner.error( _('Unknown Error'), _('Contact your administrator') );
            }

            self.baseParams = self.$baseParams;  
            self.dataUrl = self.$dataUrl;  
        });
    }
});


/*
 * Baseliner.TreeMultiTextNode
 *
 */

Baseliner.class_name = function(v){
    if( typeof(v) == 'object' && v.constructor!=undefined ) {
        var results = (/function (.{1,})\(/).exec( v.constructor.toString() );
        if(results && results.length>1) {
            return results[1];
        } else {
            results = (/\[object (.{1,})\]/).exec( v.constructor.toString() );
            return (results && results.length>1) ? results[1] : '';
        }
    } else {
        return typeof v ;
    }

};
Baseliner.TreeMultiTextNode = Ext.extend( Ext.tree.TreeNodeUI, {
    getDDHandles : function(){ // drag and drop
        var nodes = [this.iconNode, this.textNode, this.elNode];
        if( this.textNode == undefined || this.textNode.childNodes == undefined ) 
             return nodes;
        var recurse_children = function(par) {
            if( !par ) return;
            var nodelist = par.childNodes;
            if( !nodelist ) return;
            //var imax = ( Ext.isIE71 || Ext.isIE81 ) ? 2 : nodelist.length;
            for( var i=0; i < nodelist.length; i++) {
                var cn = Baseliner.class_name( nodelist[i] );
                if( ! ( cn=='Text' && Ext.isIE ) ) 
                    nodes.push( nodelist[i] );
                recurse_children( nodelist[i] );
            }
        }
        recurse_children( this.textNode );
        //this.textNode.childNodes.each(function(){ alert(1) });
        //Ext.each( this.textNode.childNodes, function(n){ nodes.push(n) });
        return nodes;
    }
});

Baseliner.ExplorerTree = Ext.extend( Baseliner.Tree, {
    ddGroup: 'explorer_dd',
    initComponent : function(){
        var self = this;
        self.tool_bar = Ext.getCmp('tool_bar');

        Baseliner.ExplorerTree.superclass.initComponent.call(this);
        
        self.on("activate", function (p){
            if(self.onload){
                self.onload();    
            }
        });

        self.on('beforeexpandnode', function(node, deep, anim) { 
            // self.tool_bar.disable_all();
            node.attributes.is_refreshing = true;
        });

        self.on('beforeload', function(node) { 
            self.tool_bar.disable_all();
            node.attributes.is_refreshing = true;
        });

        self.on('expandnode', function(node, deep, anim) { 
            // self.tool_bar.enable_all();
            node.attributes.is_refreshing = false;
        });

        self.on('load', function(node, deep, anim) { 
            self.tool_bar.enable_all();
            //node.attributes.is_refreshing = false;
        });

        self.on('beforerefresh', function(node) { 
            self.tool_bar.disable_all();
            //node.attributes.is_refreshing = true;
        });

        self.on('afterrefresh', function(node) {
            self.tool_bar.enable_all();
            //node.attributes.is_refreshing = true;
        });
        
        self.loader.on('loadexception', function(loader, node, res) {
            self.tool_bar.enable_all();
        });

        self.addEvents( 'favorite_added' );
        
    },
    menu_favorite_add : function(){
        var self = this;
        return {
            text: _('Add to Favorites...'),
            icon: '/static/images/icons/favorite_grey.svg',
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
            icon: '/static/images/icons/delete.svg',
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
            icon: '/static/images/icons/item_rename.svg',
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
        var tree_menu = new Ext.menu.Menu({
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
        if( node.attributes.menu || ( node.attributes.data && node.attributes.data.click ) ) {
            tree_menu.removeAll(); 
            var node_menu_items = new Array(); 

            // click turns into a menu-item Open...
            var click = node.attributes.data.click;
            if( click != undefined && click.url != undefined ) {
                var menu_item = new Ext.menu.Item({
                    text: _( 'Open...' ),
                    icon: '/static/images/icons/open.svg',
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
                            var d = menu_item.comp.data ||{ node: item.node, action: menu_item.comp };
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
                            else if( item.eval.url ) {
                                var params = Ext.apply({ data:node.attributes.data },item.eval.data||item.click_data);
                                Baseliner.ajaxEval( item.eval.url, params , function(comp) { });
                            } 
                            else{
                                // TODO this is not used anywhere? can't access
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
            tree_menu.add( node_menu_items );
            if( node_menu_items.length > 0 ) tree_menu.add('-');
        } else {
            var m = new Ext.menu.Menu({
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
        }
        // add search box
        if( node.attributes && node.attributes.has_query && node.isExpanded()) {
            var query = node.attributes.data.query;
            var query_box = new Baseliner.SearchSimple({ 
                width: 180,
                value: query, 
                iconCls: 'no-icon',
                handler: function(){
                    var t = this.getValue();
                    $( "[parent-node-props='"+node.id+"']" ).remove(); // remove search indicator
                    if( !t || !t.length ) {
                        delete node.attributes.data.query;
                        this.triggers[0].hide();
                    } else {
                        node.attributes.data.query = t;
                        // indicator that a search is in effect 
                        var nel = node.ui.getTextEl();
                        if( nel ) {
                            var badge = '<span class="badge" style="font-size: 9px; background-color: #bbb;"><img style="width: 12px; height: 12px; margin-right: 4px;" src="/static/images/icons/search-small-white.svg" />'+t+'</span>';
                            nel.insertAdjacentHTML( 'afterEnd', '<span id="boot" parent-node-props="'+node.id+'" style="margin: 0px 0px 0px 4px; background: transparent">'+badge+'</span>');
                        }
                        this.triggers[0].show();
                    }
                    self.refresh();
                    tree_menu.hide();
                }
            });
            tree_menu.add(query_box);
        }
        if( node.attributes != undefined && node.attributes.id_favorite !=undefined ) {
            tree_menu.add( this.menu_favorite_del() );
            tree_menu.add( this.menu_favorite_rename() );
        } else {
            tree_menu.add( this.menu_favorite_add() );
        }
        if( Baseliner.DEBUG ) {
            tree_menu.add({ text: _('Properties'), icon:'/static/images/icons/properties.svg', handler: function(n){
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
        tree_menu.add({
            xtype: 'menuitem',
            text: _('Refresh Node'),
            cls: 'x-btn-text-icon',
            icon: '/static/images/icons/refresh.svg',
            handler: function() {
                self.refresh();
            }
        });
        tree_menu.showAt(event.xy);
    }
});

Baseliner.gen_btn_listener = function() {
    return {
        'toggle': function(btn, pressed){
            btn.one_click = pressed ? 1 : 0;
        },
        'click': function(btn){
            if( btn.one_click >= 2 ) {
                btn.refresh_all(function(){btn.enable();});
            }
            btn.one_click = btn.one_click >= 1 ? 2 : 0;
            return true;
        }
    }
}

/*
 *
 *  Baseliner.Explorer - main left card panel
 *
 *
 */

Baseliner.Explorer = Ext.extend( Ext.Panel, {
    id: 'explorer',
    layout: 'card',
    region: 'west',
    activeItem: 0,
    split: true,
    header: false,
    title: _("Explorer"),  // not shown by default
    width: 250,
    initComponent: function(){
        var self = this;

        var show_projects = function(callback) {
            if( !self.$tree_projects ) {
                self.$tree_projects = new Baseliner.ExplorerTree({ dataUrl : '/lifecycle/tree' })
                self.$tree_projects.on('favorite_added', function() { if( self.$tree_favorites ) self.$tree_favorites.refresh() });
                self.add( self.$tree_projects );
            }
            self.getLayout().setActiveItem( self.$tree_projects );
            self.$tree_projects.onload = callback;     
        };

        var show_favorites = function(callback,switch_on_empty) {
            if( !self.$tree_favorites ) {
                self.$tree_favorites = new Baseliner.ExplorerTree({ dataUrl : '/lifecycle/tree' , baseParams: { favorites: true } });
                self.add( self.$tree_favorites );
            }
            self.getLayout().setActiveItem( self.$tree_favorites );
            self.$tree_favorites.onload = callback;
            if( switch_on_empty ) {
                self.$tree_favorites.on('load', function(){
                    // if we don't have any favorites, switch to the projects view
                    if( self.$tree_favorites.root && !self.$tree_favorites.root.hasChildNodes() ) {
                        show_projects(function(){button_projects.enable();});
                        button_projects.toggle(true);
                    }
                });
            };
        };

        var show_workspaces = function(callback) {
            if( !self.$tree_workspaces ) {
                self.$tree_workspaces = new Baseliner.ExplorerTree({ dataUrl : '/lifecycle/tree', baseParams: { show_workspaces: true } });
                self.add( self.$tree_workspaces );
                self.$tree_workspaces.on('favorite_added', function() { self.$tree_favorites.refresh() } );
            }
            self.getLayout().setActiveItem( self.$tree_workspaces );
            self.$tree_workspaces.onload = callback;
        };

        var show_ci = function(callback) {
            if( !self.$tree_ci ) {
                self.$tree_ci = new Baseliner.ExplorerTree({ dataUrl : '/lifecycle/tree', enableDD:false, baseParams: { show_ci: true }  });
                self.add( self.$tree_ci );
                self.$tree_ci.on('favorite_added', function() { self.$tree_favorites.refresh() } );
            }
            self.getLayout().setActiveItem( self.$tree_ci );
            self.$tree_ci.onload = callback;
        };
        
        var show_releases = function(callback) {
            if( !self.$tree_releases ) {
                self.$tree_releases = new Baseliner.ExplorerTree({ dataUrl : '/lifecycle/tree', baseParams: { show_releases: true } });
                self.add( self.$tree_releases );
                self.$tree_releases.on('favorite_added', function() { self.$tree_favorites.refresh() } );
            }
            self.getLayout().setActiveItem( self.$tree_releases );
            self.$tree_releases.onload = callback;
        };
        
        var show_reports = function(callback) {
            if( !self.$tree_reports ) {
                self.$tree_reports = new Baseliner.ExplorerTree({ dataUrl : '/ci/report/report_list', baseParams: { show_reports: true } });
                self.add( self.$tree_reports );
                self.$tree_reports.on('favorite_added', function() { self.$tree_favorites.refresh() } );
            }
            self.getLayout().setActiveItem( self.$tree_reports );
            self.$tree_reports.onload = callback;
        };
        
        var show_dashboards = function(callback) {
            if( !self.$tree_dashboards ) {
                self.$tree_dashboards = new Baseliner.ExplorerTree({ dataUrl : '/dashboard/dashboard_list', enableDD:false, baseParams: { ordered: true, show_reports: true } });
                self.add( self.$tree_dashboards );
                self.$tree_dashboards.on('favorite_added', function() { self.$tree_favorites.refresh() } );
            }
            self.getLayout().setActiveItem( self.$tree_dashboards );
            self.$tree_dashboards.onload = callback;
        };
        

        var button_projects = new Ext.Button({
            cls: 'x-btn-icon',
            icon: '/static/images/icons/project_grey.svg',
            handler: function(){
                this.disable();
                var that = this;
                show_projects(function(){that.enable();});
            },
            tooltip: _('Projects'),
            pressed: false,
            toggleGroup: 'explorer-card',
            allowDepress: false,
            hidden: ! Baseliner.user_can_projects,
            enableToggle: true,
            refresh_all: function(callback){
                if( self.$tree_projects ) self.$tree_projects.refresh_all(callback);
            },
            listeners: Baseliner.gen_btn_listener()
        });

        var button_favorites = new Ext.Button({
            cls: 'x-btn-icon',
            icon: '/static/images/icons/favorite_grey.svg',
            tooltip: _('Favorites'),
            handler: function(){
                var that = this;
                show_favorites(function(){ that.enable();});
            },
            pressed: true,
            allowDepress: false,
            toggleGroup: 'explorer-card',
            enableToggle: true,
            refresh_all: function(callback){
                if( self.$tree_favorites ) self.$tree_favorites.refresh_all(callback);
            },
            listeners: Baseliner.gen_btn_listener()
        });

        var button_workspaces = new Ext.Button({
            cls: 'x-btn-icon',
            icon: '/static/images/icons/connect.svg',
            handler: function(){
                this.disable();
                var that = this;
                show_workspaces(function(){that.enable();});
            },
            tooltip: _('Workspaces'),
            toggleGroup: 'explorer-card',
            pressed: false,
            allowDepress: false,
            enableToggle: true,
            //hidden: ! Baseliner.user_can_workspace,
            hidden: true, // XXX workspaces not ready for primetime
            refresh_all: function(callback){
                if( self.$tree_workspaces ) self.$tree_workspaces.refresh_all(callback);
            },
            listeners: Baseliner.gen_btn_listener()
        });

        var button_ci = new Ext.Button({
            cls: 'x-btn-icon ui-explorer-ci',
            icon: '/static/images/icons/class_grey.svg',
            handler: function(){
                this.disable();
                var that = this;
                show_ci(function(){that.enable();});
            },
            tooltip: _('Configuration Items'),
            toggleGroup: 'explorer-card',
            pressed: false,
            allowDepress: false,
            hidden: ! Baseliner.user_can_edit_ci,
            enableToggle: true,
            refresh_all: function(callback){
                if( self.$tree_ci ) self.$tree_ci.refresh_all(callback);
            },
            listeners: Baseliner.gen_btn_listener()
        });
        
        var button_releases = new Ext.Button({
            cls: 'x-btn-icon',
            icon: '/static/images/icons/release_explorer.svg',
            handler: function(){
                this.disable();
                var that = this;
                show_releases(function(){that.enable();});
            },
            id: 'explorer-releases',
            tooltip: _('Releases'),
            toggleGroup: 'explorer-card',
            pressed: false,
            allowDepress: false,
            hidden: ! Baseliner.user_can_releases,
            enableToggle: true,
            refresh_all: function(callback){
                if( self.$tree_releases ) self.$tree_releases.refresh_all(callback);
            },
            listeners: Baseliner.gen_btn_listener()
        });        

        var button_search_folders = new Ext.Button({
            cls: 'x-btn-icon ui-explorer-reports',
            icon: '/static/images/icons/report.svg',
            handler: function(){
                this.disable();
                var that = this;
                show_reports(function(){that.enable();});
            },
            tooltip: _('Reports'),
            toggleGroup: 'explorer-card',
            pressed: false,
            allowDepress: false,
            hidden: ! Baseliner.user_can_reports,
            enableToggle: true,
            refresh_all: function(callback){
                if( self.$tree_reports ) self.$tree_reports.refresh_all(callback);
            },
            listeners: Baseliner.gen_btn_listener()
        });        

        var button_dashboards = new Ext.Button({
            cls: 'x-btn-icon ui-explorer-dashboards',
            icon: '/static/images/icons/dashboard_grey.svg',
            handler: function(){
                this.disable();
                var that = this;
                show_dashboards(function(){that.enable();});
            },
            tooltip: _('Dashboards'),
            toggleGroup: 'explorer-card',
            pressed: false,
            allowDepress: false,
            hidden: ! Baseliner.user_can_dashboards,
            enableToggle: true,
            refresh_all: function(callback){
                if( self.$tree_dashboards ) self.$tree_dashboards.refresh_all(callback);
            },
            listeners: Baseliner.gen_btn_listener()
        });        

	var button_collapseall = new Ext.Button({
	    cls: 'x-btn-icon',
            icon: '/static/images/icons/collapseall.svg',
            handler: function(){
                if( self.$tree_releases ) self.$tree_releases.collapseAll();
                if( self.$tree_ci ) self.$tree_ci.collapseAll();
                if( self.$tree_workspaces ) self.$tree_workspaces.collapseAll();
                if( self.$tree_favorites ) self.$tree_favorites.collapseAll();
                if( self.$tree_projects ) self.$tree_projects.collapseAll();
                if( self.$tree_reports )  self.$tree_reports.collapseAll();
                this.enable();
            },
            tooltip: _('Collapse All'),
            refresh_all: function(callback){
                if( self.$tree_releases ) self.$tree_releases.refresh_all(callback);
                if( self.$tree_ci ) self.$tree_ci.refresh_all(callback);
                if( self.$tree_workspaces ) self.$tree_workspaces.refresh_all(callback);
                if( self.$tree_favorites ) self.$tree_favorites.refresh_all(callback);
                if( self.$tree_projects ) self.$tree_projects.refresh_all(callback);
                if( self.$tree_reports ) self.$tree_reports.refresh_all(callback);
            },
            listeners: Baseliner.gen_btn_listener()
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
                            icon: '/static/images/icons/favorite_new.svg'
                        },
                        function(res) {
                            Baseliner.message( _('Favorite'), res.msg );
                            if( res.success ) {
                                var new_node = self.$tree_favorites.getLoader().createNode({
                                    text: folder + ' ('+res.id_folder+')',
                                    icon: '/static/images/icons/favorite_new.svg',
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
            tooltip: _('Config'),
            menu: [
                { text: _('Add Favorite Folder'), icon: '/static/images/icons/favorite_new.svg', handler: add_to_fav_folder }
            ]
        });

        var button_collapse = new Ext.Component({
            cls: 'x-tool x-tool-expand-east', 
            style: 'margin: -2px 0px 0px 0px',
            //hidden; true,
            listeners: {
                'afterrender': function(d){
                    d.el.on('click', function(){
                        self.collapse();
                    });
                }
            }
        });

        var button_refresh = new Ext.Button({
            cls: 'x-btn-icon',
            tooltip: _('Refresh All Nodes'),
            icon: '/static/images/icons/refresh.svg',
            id: 'button_refresh',
            handler: function(){
                var that = this;
                self.current_tree().refresh_all(function(){that.enable();});
            }
        });
        var refresh_count = 0;
        var tool_bar = new Ext.Toolbar({
            items: [
                button_refresh,
                button_projects,
                button_releases,
                button_favorites,
                button_workspaces,
                button_ci,
                button_search_folders,
                button_dashboards,
                '->',
                button_menu,
                button_collapseall,        
                button_collapse,
                ' '
            ],
            id: 'tool_bar',
            
            enable_all: function() {
                refresh_count--;
                if ( refresh_count <= 0 ) {
                    refresh_count = 0;
                    button_refresh.setIcon( IC('refresh.svg') );
                    tool_bar.enable();
                }
            },
            disable_all: function() {
                refresh_count++;
                button_refresh.setIcon('/static/images/loading-fast.gif');
                // alert('dis:' + refresh_count);
                tool_bar.disable();
            }

        });
        self.tbar = tool_bar;


        Baseliner.Explorer.superclass.initComponent.call(this);
        self.on('afterrender', function(){ show_favorites(function() { button_favorites.enable(); },true); button_collapse.hide(); });
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
                params: { parent_id: data.id_folder, project_id: data.id_project },
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
    Baseliner.ajaxEval( '/fileversion/delete_folder',{ id_folder: node.attributes.data.id_folder },
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

Baseliner.remove_folder_item = function(node_data1, node_data2){
    if(node_data1.attributes.data.topic_mid ) {
        Baseliner.ajaxEval( '/fileversion/remove_topic',{ topic_mid: node_data1.attributes.data.topic_mid,
                                                          id_folder: node_data1.attributes.id_folder },
            function(response) {
                if ( response.success ) {
                    //var explorer = node_data1.ownerTree;
                    //explorer.refresh_node( node_data1.parentNode );
                    node_data1.remove();
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

// Main event that gets fired everytime a node is right-clicked
//    builds the menu from node attributes and base menu
Baseliner.move_folder_item = function(node_data1, node_data2){
    if(node_data2.attributes.data.type != 'file'){
        node_data2.appendChild( node_data1 );

        data_from = node_data1.attributes.data;
        data_to = node_data2.attributes.data;
        data_from_type = data_from.type || 'topic';
        // /fileversion/move_file, /fileversion/move_topic, /fileversion/move_directory
        Baseliner.ajaxEval( '/fileversion/move_' + data_from_type,{ from_file: data_from.id_file,
                                                                    from_directory: node_data1.attributes.id_folder || data_from.id_folder,
                                                                    parent_folder: node_data1.attributes.parent_folder || data_from.parent_folder,
                                                                    from_topic_mid: data_from.topic_mid,
                                                                    to_directory: data_to.id_folder,
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
    var id_folder = n.attributes.data.id_folder;
    Baseliner.ajaxEval( '/fileversion/topics_for_folder', { id_folder: id_folder }, function(res){
        Baseliner.add_tabcomp('/comp/topic/topic_grid.js', _('Topics: %1', name), { topic_list: res.topics, tab_icon: '/static/images/icons/topic.svg' });
    });
}

Baseliner.open_topic_grid_from_release = function(n){
    var name = n.attributes.data.click.title;
    var id_release = n.attributes.data.topic_mid;
    //console.dir(n);
    Baseliner.ajaxEval( '/lifecycle/topics_for_release', { id_release: id_release }, function(res){
        Baseliner.add_tabcomp('/comp/topic/topic_grid.js', _('Related: %1', name), { clear_filter: 1, topic_list: res.topics, tab_icon: '/static/images/icons/topic.svg' });
    });
}

Baseliner.open_apply_filter_from_release = function(n){
    var name = n.attributes.data.click.title;
    var id_release = n.attributes.data.topic_mid;
    var win;
    var treeRoot = new Ext.tree.AsyncTreeNode({
        draggable: false,
        checked: false
    });

    var tree_filters = new Ext.tree.TreePanel({
        border: false,
        dataUrl : '/ci/report/report_list',
        useArrows: true,
        animate: true,
        enableDD: true,
        containerScroll: true,
        rootVisible: false,
        root: treeRoot
    });
    
    tree_filters.on('dblclick', function(n, ev){
        Baseliner.ajaxEval( '/lifecycle/topics_for_release', { id_release: id_release, id_report: n.attributes.data.id_report }, function(res){
            Baseliner.ajaxEval( '/comp/lifecycle/report_run.js', { 
                id_report: n.attributes.data.id_report, 
                report_name: _('%1: %2', name, n.attributes.data.report_name), //n.attributes.data.report_name, 
                report_rows: n.attributes.data.report_rows, 
                hide_tree: n.attributes.data.hide_tree, 
                topic_list: res.topics,
                tab_icon: '/static/images/icons/topic.svg' }, 
                function(res){
                    //N/D
            });
        });         
        win.close();
    });
    
    var title = _('Select a filter');
    
    var form_filters = new Ext.FormPanel({
        padding: 10,
        border: false,
        frame: false,
        autoScroll: true,
        height: 400,
        items: [
            tree_filters
        ]
    });

    win = new Ext.Window({
        title: title,
        width: 550,
        closeAction: 'close',
        modal: true,
        items: form_filters
    });
    win.show();     
}

Baseliner.open_kanban_from_folder = function(n){
    var name = n.text;
    var id_folder = n.attributes.data.id_folder;
    Baseliner.ajaxEval( '/fileversion/topics_for_folder', { id_folder: id_folder }, function(res){
        if( ! res.topics || res.topics.length < 1 ) {
            Baseliner.message( _('Kanban'), _('Folder does not contain any topics') );
            return;
        }
        var kanban = new Baseliner.Kanban({ topics: res.topics }); 
        kanban.goto_tab();
    });
}

Baseliner.new_search = function(n){
    var node = n;
    Baseliner.ajaxEval( '/comp/lifecycle/report_edit.js', {node: node, is_new: true }, function(res){});
}

Baseliner.edit_search = function(n){
    var node = n;
    Baseliner.ajaxEval( '/comp/lifecycle/report_edit.js', {node: node }, function(res){});
}

Baseliner.delete_search = function(n){
    var node = n;
    if( ! node.attributes.mid){
        node.attributes.mid = node.attributes.data.id_report;
    }
    Baseliner.confirm( _('Are you sure you want to delete the search %1?', n.text), function(){
        Baseliner.ci_call( node.attributes.mid, 'report_update', { action:'delete' }, 
            function(response) {
                if ( response.success ) {
                    Baseliner.message( _('Success'), response.msg );
                    node.remove();
                } else {
                    Baseliner.message( _('ERROR'), response.msg );
                }
            }
        );    
    });
}

Baseliner.download_specifications = function(n){
    var name = n.attributes.data.click.title;
    name = name.replace(/#+/g, '');
    name = name.replace(/\s+/g, '_');
    var id_release = n.attributes.data.topic_mid;
    Baseliner.ajaxEval( '/lifecycle/check_download_specifications', {id_release: id_release, name_r: name }, function(res){
        var fd = document.all.FD || document.all.FrameDownload;
        fd.src =  '/lifecycle/get_specifications?id_release='+id_release+'&name='+name;
    }, function (res) {
        Baseliner.warning( _('Warning'), res.msg );
    });
}
