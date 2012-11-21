Baseliner.lc = {
    dataUrl: '/lifecycle/tree'
};

var which_tree = function() {
    var loader = Baseliner.lifecycle.getLoader();
    var root = Baseliner.lifecycle.root;
    if( root.attributes.data == undefined ) root.attributes.data = {}; 
    root.attributes.data.favorites =  button_favorites.pressed;
    root.attributes.data.show_workspaces = button_workspaces.pressed;
    root.attributes.data.show_ci = button_ci.pressed;
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

var show_ci = function() {
    which_tree();
};

var add_workspace = function() {
    Baseliner.ajaxEval( '/comp/lifecycle/workspace_new.js', {}, function(){} );
};

var refresh_node = function(node){
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

var refresh_lc = function(){
    var sm = Baseliner.lifecycle.getSelectionModel();
    var node = sm.getSelectedNode();
    refresh_node( node );
};

var button_projects = new Ext.Button({
    cls: 'x-btn-icon',
    icon: '/static/images/icons/project.png',
    handler: show_favorites,
    tooltip: _('Projects'),
    pressed: true,
    toggleGroup: 'lc',
    allowDepress: false,
    enableToggle: true
});

var button_favorites = new Ext.Button({
    cls: 'x-btn-icon',
    icon: '/static/images/icons/star-gray.png',
    tooltip: _('Favorites'),
    handler: show_favorites,
    pressed: false,
    allowDepress: false,
    toggleGroup: 'lc',
    enableToggle: true
});

var button_workspaces = new Ext.Button({
    cls: 'x-btn-icon',
    icon: '/static/images/icons/workspaces.png',
    handler: show_workspaces,
    tooltip: _('Workspaces'),
    toggleGroup: 'lc',
    pressed: false,
    allowDepress: false,
    enableToggle: true
});

var button_ci = new Ext.Button({
    cls: 'x-btn-icon',
    icon: '/static/images/ci/ci-grey.png',
    handler: show_ci,
    tooltip: _('Configuration Items'),
    toggleGroup: 'lc',
    pressed: false,
    allowDepress: false,
% if ( !$c->model('Permissions')->user_has_action( action=>'action.lc.ic_editor', username=>$c->username ) ) {
    hidden: true,    
% }
    enableToggle: true
});

var button_menu = new Ext.Button({
    //cls: 'x-btn-icon',
    //icon: '/static/images/icons/config.gif',
    tooltip: _('Config'),
    menu: [
        { text: _('Add Workspace'), handler: add_workspace }
    ]
});

Baseliner.lc_tbar = new Ext.Toolbar({
    items: [
        { xtype:'button', 
            cls: 'x-btn-text-icon',
            icon: '/static/images/icons/refresh-grey.gif',
            handler: refresh_lc        },
        button_projects,
        button_favorites,
        button_workspaces,
        button_ci,
        '->',
        button_menu,
        '<div class="x-tool x-tool-expand-east" style="margin:-2px -4px 0px 0px" onclick="Baseliner.lifecycle.collapse()"></div>'
        //{ xtype:'button', iconCls:'x-btn-icon x-tool x-tool-expand-east', handler:function(){ Baseliner.lifecycle.collapse() } }
    ]
});

var base_menu_items = [ ];

var menu_favorite_add = {
    text: _('Add to Favorites...'),
    icon: '/static/images/icons/favorite.png',
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

var menu_refresh = {
    text: _('Refresh Node'),
    cls: 'x-btn-text-icon',
    icon: '/static/images/icons/refresh.gif',
    handler: refresh_lc 
};

var menu_prueba_add = {
    text: _('Add to Prueba...'),
    icon: '/static/images/icons/favorite.png',
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
    icon: '/static/images/icons/favorite.png',
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

var menu_favorite_rename = {
    text: _('Rename'),
    icon: '/static/images/icons/rename.gif',
    handler: function(n) {
        var sm = Baseliner.lifecycle.getSelectionModel();
        var node = sm.getSelectedNode();
        if( node ) {
            Ext.Msg.prompt(_('Rename'), _('New name:'), function(btn, text){
                if( btn == 'ok' ) {
                    Baseliner.ajaxEval( '/lifecycle/favorite_rename',
                        { id: node.attributes.id_favorite, text: text },
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


function new_folder(node){
    var btn_cerrar = new Ext.Toolbar.Button({
        text: _('Close'),
        width: 50,
        handler: function() {
            win.close();
        }
    })
    
    var btn_grabar = new Ext.Toolbar.Button({
        text: _('Save'),
        width: 50,
        handler: function(){
            var form = form_folder.getForm();
            var data = node.attributes.data;

            if (form.isValid()) {
                form.submit({
                    params: { parent_id: data.id_directory, project_id: data.id_project },
                    success: function(f,a){
                        Baseliner.message(_('Success'), a.result.msg );
                        if(node.isExpanded()){
                            var data_attributes = {
                                id_directory: a.result.directory_id,
                                id_project: data.id_project,
                                type: 'directory',
                                on_drop: {
                                    handler: 'move_item'
                                }
                            };
                            var menu_new_folder = [{
                                                        text: _('New Folder'),
                                                        icon: '/static/images/icons/folder_new.gif',
                                                        eval:   {
                                                                handler: 'new_folder'
                                                        }
                                                    },
                                                    {
                                                        text: _('Delete Folder'),
                                                        icon: '/static/images/icons/folder_delete.gif',
                                                        eval:   {
                                                                handler: 'delete_folder'
                                                        }
                                                    }                                                    
                                                    ];
                            
                            
                            node.appendChild({ text:a.result.folder, icon: '/static/images/icons/folder.gif', data: data_attributes, menu: menu_new_folder, leaf: false});
                        };
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
    })    
    
    var form_folder = new Ext.FormPanel({
						    name: form_folder,
						    url: '/fileversion/new_folder',
						    frame: true,
						    buttons: [btn_grabar, btn_cerrar],
						    defaults:{anchor:'100%'},
						    items   : [
									    { fieldLabel: _('Folder'), name: 'folder', xtype: 'textfield', allowBlank:false}
								    ]
	});
    
    var win = new Ext.Window({
        title: _('New Folder'),
        width: 300,
        autoHeight: true,
        modal: true,
        items: form_folder
    });
    
    win.show();  
}

function delete_folder(node){
    Baseliner.ajaxEval( '/fileversion/delete_folder',{ id_directory: node.attributes.data.id_directory },
        function(response) {
            if ( response.success ) {
                Baseliner.message( _('Success'), response.msg );
                refresh_node(node.parentNode);
                //node.remove();
            } else {
                Baseliner.message( _('ERROR'), response.msg );
            }
        }
    
    );    
}

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

var click_handler = function(item){
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
};
// Main event that gets fired everytime a node is right-clicked
//    builds the menu from node attributes and base menu
var menu_click = function(node,event){
    node.select();
    
    // menus and click events go in here
    if( node.attributes.menu || ( node.attributes.data && node.attributes.data.click ) ) {

        var m = Baseliner.lc_menu;
        m.removeAll(); 
        var node_menu_items = new Array(); 

        // click turns into a menu-item Open...
        var click = node.attributes.data.click;
        if( click != undefined && click.url != undefined ) {
            var menu_item = new Ext.menu.Item({
                text: _( 'Open...' ),
                icon: '/static/images/icons/tab.png',
                node: node,
                handler: click_handler
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
        var m = Baseliner.lc_menu;
        m.removeAll(); 
    }
    // add base menu
    m.add( base_menu_items );
    if( node.attributes != undefined && node.attributes.id_favorite !=undefined ) {
        m.add( menu_favorite_del );
        m.add( menu_favorite_rename );
    } else {
        m.add( menu_favorite_add );
    }
    if( Baseliner.DEBUG ) {
        m.add({ text: _('Properties'), icon:'/static/images/icons/properties.png', handler: function(n){
            var sm = Baseliner.lifecycle.getSelectionModel();
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
    m.add( menu_refresh );
    Baseliner.lc_menu.showAt(event.xy);
}

function move_item(node_data1, node_data2){
    if(node_data2.attributes.data.type != 'file'){
        node_data2.appendChild( node_data1 );

        data_from = node_data1.attributes.data;
        data_to = node_data2.attributes.data;
        Baseliner.ajaxEval( '/fileversion/move_' + data_from.type,{ from_file: data_from.id_file,
                                                                    from_directory: data_from.id_directory,
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

var drop_handler = function(e) {
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
            var id_project = n2.parentNode.attributes.data.id_project
            Baseliner.ajaxEval( on_drop.url, { id_file: node_data1.id_file, id_project: id_project  }, function(res){
                if( res.success ) {
                    Baseliner.message(  _('Drop'), res.msg );
                    //e.target.appendChild( n1 );
                    //e.target.expand();
                    refresh_node( e.target );
                } else {
                    Baseliner.message( _('Drop'), res.msg );
                    //Ext.Msg.alert( _('Error'), res.msg );
                    return false;
                }
            });
        }else{
            if(on_drop.handler != undefined ){
                eval(on_drop.handler + '(n1, n2);');                
            }
        }
    }
    return true;
};

Baseliner.lifecycle = new Ext.tree.TreePanel({
    region: 'west',
    split: true,
    collapsible: true,
    title: _("Navigator"),
    header: false,
    width: 250,
    useArrows: true,
    autoScroll: true,
    animate: true,
    enableDD: true,
    ddGroup: 'lifecycle_dd',
    listeners: {
        beforenodedrop: { fn: drop_handler },
        contextmenu: menu_click
    },
    containerScroll: true,
    rootVisible: false,
    dataUrl: Baseliner.lc.dataUrl,
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
    
Baseliner.lc_topic_style = [
    '<span style="font-size:0px;',
    'padding: 8px 8px 0px 0px;',
    'margin : 0px 4px 0px 0px;',
    'border : 2px solid {0};',
    'background-color: transparent;',
    'color:{0};',
    'border-radius:0px"></span>'
].join('');

Baseliner.lifecycle.on('beforechildrenrendered', function(node){
    node.eachChild(function(n) {
        if(n.attributes.topic_name ) {
            var tn = n.attributes.topic_name;
            n.setIconCls('no-icon');

            if( !tn.category_color ) 
                tn.category_color = '#999';
            //tn.style = 'font-size:10px';
            //tn.style = String.format('font-size:9px; margin: 2px 2px 2px 2px; border: 1px solid {0};background-color: #fff;color:{0}', tn.category_color);
            //tn.style = String.format('font-size:9px; margin: 2px 2px 2px 2px; border: 1px solid {0};background-color: #fff;color:{0}', tn.category_color);
            var span = String.format( Baseliner.lc_topic_style, tn.category_color );

            //tn.mini = true;
            //var tn_span = Baseliner.topic_name(tn);

            n.setText( String.format( '{0}<b>{1} #{2}</b>: {3}', span, tn.category_name, tn.mid, n.text ) );

            /* n.setText( String.format('<span id="boot"><span class="label" style="font-size:10px;background-color:{0}">#{1}</span></span> {2}',
                n.attributes.topic_name.category_color, n.attributes.topic_name.mid, n.text ) ); */
        }
    });
});

//Baseliner.lifecycle.on('dblclick', function(n, ev){

Baseliner.lifecycle.on('dblclick', function(n, ev){     
    if( n.leaf ) 
        click_handler({ node: n });
});

Baseliner.lifecycle.expand();
