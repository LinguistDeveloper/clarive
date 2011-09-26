Baseliner.lc = {
    dataUrl: '/lifecycle/tree'
};

Baseliner.lc_tbar = new Ext.Toolbar({
    items: [
        { xtype:'button', 
            cls: 'x-btn-text-icon',
            icon: '/static/images/icons/refresh.gif',
            handler: function(){
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
            }
        }
    ]
});

var base_menu_items = [
        {
            text: _('Add to Favorites'), handler: function(n) {
                Baseliner.message( _('Favorite'), _('Added') );
            }
        }
    ];
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
        m.add( base_menu_items );
    } else {
        var m = Baseliner.lc_menu;
        m.removeAll(); 
        m.add( base_menu_items );
    }
    Baseliner.lc_menu.showAt(event.xy);
}


Baseliner.lifecycle = new Ext.tree.TreePanel({
    region: 'west',
    split: true,
    collapsible: true,
    title: _("Lifecycle"),
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
    console.log( n.attributes.data );
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
