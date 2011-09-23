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
                    loader.load( node );
                } else {
                    loader.load(Baseliner.lifecycle.root);
                }
            }
        }
    ]
});

var menu_items = [
        {
            text: _('Add to Favorites'), handler: function(n) {
                Baseliner.message( _('Favorite'), _('Added') );
            }
        }
    ];
Baseliner.lc_menu = new Ext.menu.Menu({
    items: menu_items,
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
    if( node.attributes != undefined ) {
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
