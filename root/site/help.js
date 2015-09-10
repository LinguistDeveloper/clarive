/****** Clarive Help context methods *******/
Cla.help_show = function(params) {
    if( Cla.help_win != undefined ) Cla.help_win.close();

    var treeRoot = new Ext.tree.AsyncTreeNode({ draggable: false, checked: false });
    var docs_tree = new Cla.Tree({
        region: 'west', width: 300,
        border: false,
        dataUrl : '/help/docs_tree',
        useArrows: true,
        animate: true,
        containerScroll: true,
        rootVisible: false,
        root: treeRoot
    });

    var goto_doc = function(path, opts){
        if( !opts ) opts={};
        Cla.help_win.mask();
        Cla.ajax_json('/help/get_doc', { path: path }, function(res){
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
            $(doc_reader.el.dom).find('a').each(function(){
                var link = $(this);
                $(this).on('click', function(){
                    var href = this.href;
                    if( !href || href.lenght==0 ) return false;
                    var rr = href.match(/\/\/[^\/]+\/(.+)$/);
                    if( rr && rr[1] ) {
                        goto_doc( rr[1] + '.markdown' );
                    }
                    return false;
                });
            });
            Cla.help_win.unmask();
            if( ! opts.from_hist ) Cla.help_win.history_push( path );
        });
    };
    docs_tree.getLoader().on('beforeload', function(lo){
        Cla.help_win.mask();
    });
    docs_tree.getLoader().on('load', function(lo){
        Cla.help_win.unmask();
        if( lo.baseParams.query ){
            var docs = [];
            docs_tree.root.cascade(function(nd){
                if( ! nd.isLeaf() ) return;
                docs.push({ 
                    title: nd.attributes.text, 
                    found: nd.attributes.search_results.found, 
                    matches: nd.attributes.search_results.matches, 
                    path: nd.attributes.path, 
                    data: nd.attributes.data
                });
            });
            var html ='';
            Ext.each( docs.sort(function(a,b){ return b.matches > a.matches }) , function(doc){
                html += function(){/*
                   <div class="help-search-result" style="cursor: pointer;" path="[%= data.path %]">
                       <h3>[%= title %]</h3>
                       <p style="color: #3070c0">[%= data.path %]</p>
                       <p>[%= found %]</p>
                       <hr />
                   </div>
                */}.tmpl(doc);
            });
            doc_reader.update( '<div id="boot">' + html + '</div>' );
            $('.help-search-result').click(function(){
                var path = $(this).attr('path');
                goto_doc( path );
            });
        }
    });
    docs_tree.on('click', function(node){
        var attr = node.attributes;
        var data = attr.data;
        goto_doc( data.path );
    });
    var doc_reader = new Ext.Panel({
        region: 'center', bodyStyle: 'padding: 20px 20px 20px 20px;',
        autoScroll: true,
    });
    var search_box = new Baseliner.SearchSimple({ 
        width: 240,
        handler: function(){
            var query = search_box.getValue();
            var t = query ? query : '';
            var lo = docs_tree.getLoader();
            lo.baseParams = { query: t };
            lo.load(docs_tree.root);
        }
    });

    var btn_refresh = new Ext.Button({ icon: IC('refresh'), handler: function(){
        docs_tree.refresh();
    }});

    var btn_left = new Ext.Button({ icon: IC('arrow_left.gif'), disabled: true, handler: function(){
        check_btns();
        if( Cla.help_win.history_curr <= 0 )  return;
        var path = Cla.help_win.history[ --Cla.help_win.history_curr ];
        if( path ) goto_doc( path, { from_hist : true } ); 
        check_btns();
    }});
    var btn_right = new Ext.Button({ icon: IC('arrow_right.gif'), disabled: true, handler: function(){
        check_btns();
        if( Cla.help_win.history_curr >= Cla.help_win.history.length ) return;
        var path = Cla.help_win.history[ ++Cla.help_win.history_curr ];
        if( path ) goto_doc( path, { from_hist : true } ); 
        check_btns();
    }});
    var check_btns = function(){
        if( Cla.help_win.history_curr <= 0 )  {
            btn_left.disable();
        } else {
            btn_left.enable();
        }
        if( Cla.help_win.history_curr >= Cla.help_win.history.length-1 ) {
            btn_right.disable();
        } else {
            btn_right.enable();
        }
    }

    Cla.help_win = new Cla.Window({
        id: 'clarive-help-win',
        height: 750,
        width: 1000,
        //top: 20, left: 3,
        autoScroll: true,
        title: _('Help'),
        titleCollapse: true,
        closeAction: 'destroy',
        layout: 'border',
        history: [],
        history_curr: -1,
        tbar: [
            btn_refresh, search_box, '->', btn_left, btn_right
        ],
        items: [ docs_tree, doc_reader ]
    });
    Cla.help_win.mask = function(){
        Cla.help_win.body.mask( String.format('<img src="{0}" />', '/static/images/loading.gif' ) ).setHeight(9999);
    }
    Cla.help_win.unmask = function(){
        Cla.help_win.body.unmask();
    }
    Cla.help_win.history_push = function(path){
        if( Cla.help_win.history[Cla.help_win.history.length-1] != path ) {// avoid dups
            Cla.help_win.history.push( path );
        }
        Cla.help_win.history_curr = Cla.help_win.history.length-1;
        check_btns();
    }
        //Cla.help_win.getEl().fadeOut('l', { duration: .5 });
        //Cla.help_win.hide();
    Cla.help_win.show();
    //treeRoot.expand();
};

Cla.help_show_orig = function(params) {
    if( Cla.help_win != undefined ) Cla.help_win.close();
    Cla.help_win = new Ext.Window({
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
        //Cla.help_win.getEl().fadeOut('l', { duration: .5 });
        //Cla.help_win.hide();
    Cla.help_win.show();
};
Cla.help_on = function() {
    //Cla.help_button.setIcon('/static/images/icons/lightbulb.png');
    Cla.help_button.setIconClass('help-on');
};
Cla.help_off = function() {
    //Cla.help_button.setIcon('/static/images/icons/lightbulb_off.png');
    Cla.help_button.setIconClass('help-off');
};
Cla.help_handler = function(params) {
    if( params.key != undefined ) {  // load by help key
        Cla.ajaxEval( '/help/load', params, function(res) {
            Cla.help_show(res);
        });
    } else if( params.path != undefined ) {
        var req = Ext.Ajax.request({
            url: '/help/load',
            params: params,
            success: function(res) {
                var body = res.responseText;
                Cla.help_show({ title: params.title, html: body });
            }
        });
    } else if( params.text != undefined ) {
        Cla.help_show( params );
    } else {
        Ext.Msg.alert( _('Help'), _('Help not available for this item.') );
    }
};
Cla.help_push = function(params) {
    try {  // Ext 2.x does not have a find
        var items = Cla.help_menu.find( 'text', params.title );
        //alert( JSON.stringify( items ));
        if( items!=undefined && items.length > 0 ) return;
    } catch(e) { }
    Cla.help_button.show();
    Cla.help_menu.addMenuItem({
        text: params.title,
        handler: function() { Cla.help_handler(params) },
        icon: (params.icon!=undefined ? params.icon : '/static/images/icons/help.png')
    });
    Cla.help_on();
};


