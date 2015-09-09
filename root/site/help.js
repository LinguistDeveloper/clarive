/****** Baseliner Help context methods *******/
Baseliner.help_show = function(params) {
    if( Baseliner.help_win != undefined ) Baseliner.help_win.close();
    var treeRoot = new Ext.tree.AsyncTreeNode({
        draggable: false,
        checked: false
    });
    var docs_tree = new Baseliner.Tree({
        region: 'west', width: 300,
        border: false,
        dataUrl : '/help/docs_tree',
        useArrows: true,
        animate: true,
        containerScroll: true,
        rootVisible: false,
        root: treeRoot
    });
    docs_tree.on('click', function(node){
        var attr = node.attributes;
        var data = attr.data;
        doc_reader.update('<img src="/static/images/loading.gif" />');
        Cla.ajax_json('/help/get_doc', { path: data.path }, function(res){
            var data = res.data;
            var html = function(){/*
                <div id="boot" class="help-doc">
                <p>
                <h1>[%= title %]
                <span class="label">[%= uniq_id %]</span>
                </h1>
                </p>
                <hr />
                [%= html %]
                </div>
            */}.tmpl(data);
            doc_reader.update(html);
            doc_reader.doLayout();
        });
    });
    var doc_reader = new Ext.Panel({
        region: 'center', bodyStyle: 'padding: 20px 20px 20px 20px;',
        autoScroll: true,
    });
    var search_box = new Baseliner.SearchSimple({ 
        width: 140,
        handler: function(){
            var t = search_box.getValue();
            docs_tree.baseParams.query = t;
            docs_tree.reload();
        }
    });

    var btn_refresh = new Ext.Button({ icon: IC('refresh'), handler: function(){
        docs_tree.reload();
    }});

    Baseliner.help_win = new Cla.Window({
        id: 'clarive-help-win',
        height: 750,
        width: 1000,
        //top: 20, left: 3,
        autoScroll: true,
        title: _('Help'),
        titleCollapse: true,
        closeAction: 'destroy',
        layout: 'border',
        tbar: [
            btn_refresh, search_box
        ],
        items: [ docs_tree, doc_reader ]
    });
        //Baseliner.help_win.getEl().fadeOut('l', { duration: .5 });
        //Baseliner.help_win.hide();
    Baseliner.help_win.show();
};

Baseliner.help_show_orig = function(params) {
    if( Baseliner.help_win != undefined ) Baseliner.help_win.close();
    Baseliner.help_win = new Ext.Window({
        id: 'baseliner-help-win',
        height: 600,
        top: 20, left: 3,
        autoScroll:true,
        width: (params.width!=undefined?params.width: 350),
        width: (params.height!=undefined?params.height: 500),
        maximizable: true,
        title: _('Help') + ': ' + params.title,
        titleCollapse: true,
        closeAction: 'destroy',
        html: params.html?params.html:params.text
    });
        //Baseliner.help_win.getEl().fadeOut('l', { duration: .5 });
        //Baseliner.help_win.hide();
    Baseliner.help_win.show();
};
Baseliner.help_on = function() {
    //Baseliner.help_button.setIcon('/static/images/icons/lightbulb.png');
    Baseliner.help_button.setIconClass('help-on');
};
Baseliner.help_off = function() {
    //Baseliner.help_button.setIcon('/static/images/icons/lightbulb_off.png');
    Baseliner.help_button.setIconClass('help-off');
};
Baseliner.help_handler = function(params) {
    if( params.key != undefined ) {  // load by help key
        Baseliner.ajaxEval( '/help/load', params, function(res) {
            Baseliner.help_show(res);
        });
    } else if( params.path != undefined ) {
        var req = Ext.Ajax.request({
            url: '/help/load',
            params: params,
            success: function(res) {
                var body = res.responseText;
                Baseliner.help_show({ title: params.title, html: body });
            }
        });
    } else if( params.text != undefined ) {
        Baseliner.help_show( params );
    } else {
        Ext.Msg.alert( _('Help'), _('Help not available for this item.') );
    }
};
Baseliner.help_push = function(params) {
    try {  // Ext 2.x does not have a find
        var items = Baseliner.help_menu.find( 'text', params.title );
        //alert( JSON.stringify( items ));
        if( items!=undefined && items.length > 0 ) return;
    } catch(e) { }
    Baseliner.help_button.show();
    Baseliner.help_menu.addMenuItem({
        text: params.title,
        handler: function() { Baseliner.help_handler(params) },
        icon: (params.icon!=undefined ? params.icon : '/static/images/icons/help.png')
    });
    Baseliner.help_on();
};


