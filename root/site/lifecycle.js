Baseliner.lc = {
    dataUrl: '/lifecycle/tree'
};

var which_tree = function() {
    var loader = Baseliner.lifecycle.getLoader();
    var root = Baseliner.lifecycle.root;
    if( root.attributes.data == undefined ) root.attributes.data = {}; 
    root.attributes.data.favorites =  button_favorites.pressed;
    root.attributes.data.show_workspaces = button_workspaces.pressed;
    root.attributes.data.favorites =  button_favorites.pressed;
    Baseliner.lifecycle.getSelectionModel().clearSelections();
    refresh_lc();
};

var show_favorites = function() {
    which_tree();
};

var show_workspaces = function() {
    which_tree();
};

var add_workspace = function() {
    Baseliner.ajaxEval( '/comp/lifecycle/workspace_new.js', {}, function(){} );
};

var refresh_lc = function(){
    var sm = Baseliner.lifecycle.getSelectionModel();
    var node = sm.getSelectedNode();
    var loader = Baseliner.lifecycle.getLoader();
    loader.dataUrl = Baseliner.lc.dataUrl;
    if( node != undefined ) {
        var is = node.isExpanded();
        loader.load( node );
        if( is ) node.expand();
    } else {
        loader.load(Baseliner.lifecycle.root);
    }
};

var button_favorites = new Ext.Button({
    cls: 'x-btn-icon',
    icon: '/static/images/icons/favorites.gif',
    handler: show_favorites,
    pressed: false,
    toggleGroup: 'lc',
    enableToggle: true
});

var button_workspaces = new Ext.Button({
    cls: 'x-btn-icon',
    icon: '/static/images/icons/connect.png',
    handler: show_workspaces,
    toggleGroup: 'lc',
    pressed: false,
    enableToggle: true
});

var button_menu = new Ext.Button({
    menu: [
        { text: _('Add Workspace'), handler: add_workspace }
    ]
});

Baseliner.lc_tbar = new Ext.Toolbar({
    items: [
        { xtype:'button', 
            cls: 'x-btn-text-icon',
            icon: '/static/images/icons/refresh.gif',
            handler: refresh_lc        },
        button_favorites,
        button_workspaces,
        '->',
        button_menu
    ]
});

var base_menu_items = [ ];

var menu_favorite_add = {
    text: _('Add to Favorites...'),
    icon: '/static/images/icons/favorites.gif',
    handler: function(n) {
        var sm = Baseliner.lifecycle.getSelectionModel();
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
                    Baseliner.message( _('Favorite'), res.msg );
                }
            );
        }
    }
};

var menu_favorite_del = {
    text: _('Remove from Favorites'),
    icon: '/static/images/icons/favorites.gif',
    handler: function(n) {
        var sm = Baseliner.lifecycle.getSelectionModel();
        var node = sm.getSelectedNode();
        if( node != undefined ) {
            Baseliner.ajaxEval( '/lifecycle/favorite_del',
                { id: node.attributes.id_favorite },
                function(res) {
                    Baseliner.message( _('Favorite'), res.msg );
                    node.remove();
                }
            );
        }
    }
};

Baseliner.lc_menu = new Ext.menu.Menu({
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

// Main event that gets fired everytime a node is right-clicked
//    builds the menu from node attributes and base menu
var menu_click = function(node,event){
    node.select();
    if( node.attributes.menu != undefined ) {
        var m = Baseliner.lc_menu;
        m.removeAll(); 
        var node_menu = node.attributes.menu;
        var node_menu_items = new Array(); 
        // create js handlers for menu items
        for( var i = 0; i < node_menu.length; i++ ) {
            var menu_item = node_menu[i];
            menu_item.text = _( menu_item.text ); 
            var url = "";
            // component opener menu
            if( menu_item.comp != undefined ) {
                url = menu_item.comp.url; 
                menu_item.handler = function(item) {
                    Baseliner.add_tabcomp( item.url, _(menu_item.comp.title), item.node );
                };
            } else if( menu_item.eval != undefined ) {
                url = menu_item.eval.url; 
                menu_item.handler = function( item ) {
                    Baseliner.ajaxEval( item.url, item.node , function(comp) {
                        // no op
                        var x = 0;
                    });
                };
            }
            var item = new Ext.menu.Item(menu_item);
            node_menu_items.push( item );
            //item.node = node.attributes; // stash it here
            item.node = node; // stash it here, otherwise things get out of scope
            item.url  = url;
        }
        m.add( node_menu_items );
        if( node_menu_items.length > 0 ) m.add('-');
    } else {
        var m = Baseliner.lc_menu;
        m.removeAll(); 
    }
    // add base menu
    m.add( base_menu_items );
    if( node.attributes != undefined && node.attributes.id_favorite !=undefined ) 
        m.add( menu_favorite_del );
    else
        m.add( menu_favorite_add );
    Baseliner.lc_menu.showAt(event.xy);
}


Baseliner.lifecycle = new Ext.tree.TreePanel({
    region: 'west',
    split: true,
    collapsible: true,
    title: _("Lifecycle"),
    ddGroup: 'lifecycle_dd',
    width: 250,
    useArrows: true,
    autoScroll: true,
    animate: true,
    baseArgs: {
        singleClickExpand: true
    },
    containerScroll: true,
    listeners: { contextmenu: menu_click },
    rootVisible: false,
    dataUrl: Baseliner.lc.dataUrl,
    enableDD: true,
    tbar: Baseliner.lc_tbar,
    root: {
        nodeType: 'async',
        text: '/',
        draggable:false,
        id: '/'
    }
});

Baseliner.lifecycle.getLoader().on("beforeload", function(treeLoader, node) {
    //lifecycle.getLoader().baseParams.controller = 'xxxxxxxxxxxxxxx'; //node.attributes.category;
    var loader = Baseliner.lifecycle.getLoader();
    if( node.attributes.url != undefined ) {
        loader.dataUrl = node.attributes.url;
    }
    loader.baseParams = node.attributes.data;
});

Baseliner.lifecycle.on('dblclick', function(n, ev){ 
    //alert( JSON.stringify( n ) );
    if( n.attributes.data == undefined ) return;
    var c = n.attributes.data.click;
    if( c==undefined || c.url==undefined ) return;
    var params = n.attributes.data;
    if( params.tab_icon == undefined ) params.tab_icon = c.icon;
    if( c.type == 'comp' ) {
        Baseliner.add_tabcomp( c.url, _(c.title), params );
        ev.stopEvent();
    } else if( c.type == 'html' ) {
        Baseliner.add_tab( c.url, _(c.title), params );
        ev.stopEvent();
    } else {
        Baseliner.message( 'Invalid or missing click.type', '' );
    }
});

Baseliner.lifecycle.expand();
