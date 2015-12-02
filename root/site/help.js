/****** Clarive Help context methods *******/
Cla.help_show = function(params) {
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
        help_win.mask();
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
            doc_reader.is_loaded = true;
            help_win.setTitle( data.title || path );
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
            help_win.unmask();
            if( ! opts.from_hist ) help_win.history_push( path );
        });
    };
    docs_tree.getLoader().on('beforeload', function(lo){
        help_win.mask();
    });
    docs_tree.getLoader().on('load', function(lo){
        help_win.unmask();
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
            doc_reader.is_loaded = true;
        }
        else if( params && params.path!=undefined ) {
            goto_doc(params.path);
            params.path = undefined;
        }
        else {
            do_intro_doc();
        }
        $('.help-search-result').click(function(){
            var path = $(this).attr('path');
            goto_doc( path );
            return false;
        });
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
    var do_intro_doc = function(){
        var html_chi='';
        html_chi_tpl = function(){/*
            [% if( node.leaf ) { %]
                <li class="square" style="margin-left: [%= depth * 12 %]px">
                <a href="#" class="help-search-result" path="[%= node.attributes.data.path %]">
                    [%= node.text %]
                </a>
                </li>
            [% } else { %]
                <h[%= depth>=4?5:depth+1 %] style="margin-left: [%= depth * 8 %]px">[%= node.text %]</h[%= depth>=4?5:depth+1 %]>
            [% } %]
        */};
        treeRoot.cascade(function(node){
            var dep = node.getDepth();
            html_chi += html_chi_tpl.tmpl({ node: node, depth: dep });
        });
        var html = function(){/*
             <div id="boot">
                 <h1>Clarive Help</h1>
                 <hr />
                 [%= chi %]
             </div>
        */}.tmpl({ chi: html_chi });
        doc_reader.update(html);
        doc_reader.is_loaded = true;
        help_win.setTitle( _('Help') );
    };
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

    var btn_home = new Ext.Button({ icon: IC('home.gif'), tooltip: _('Show Help Index'), handler: function(){
        search_box.setValue('');
        docs_tree.getLoader().baseParams.query = '';
        docs_tree.getLoader().load(docs_tree.root);
        //docs_tree.refresh();
    }});

    var btn_refresh = new Ext.Button({ icon: IC('refresh'), handler: function(){
        docs_tree.refresh();
    }});

    var btn_left = new Ext.Button({ icon: IC('arrow_left.gif'), disabled: true, handler: function(){
        check_btns();
        if( help_win.history_curr <= 0 )  return;
        var path = help_win.history[ --help_win.history_curr ];
        if( path ) goto_doc( path, { from_hist : true } ); 
        check_btns();
    }});
    var btn_right = new Ext.Button({ icon: IC('arrow_right.gif'), disabled: true, handler: function(){
        check_btns();
        if( help_win.history_curr >= help_win.history.length ) return;
        var path = help_win.history[ ++help_win.history_curr ];
        if( path ) goto_doc( path, { from_hist : true } ); 
        check_btns();
    }});
    var check_btns = function(){
        if( help_win.history_curr <= 0 )  {
            btn_left.disable();
        } else {
            btn_left.enable();
        }
        if( help_win.history_curr >= help_win.history.length-1 ) {
            btn_right.disable();
        } else {
            btn_right.enable();
        }
    }

    var help_win = new Cla.Window({
        height: 750,
        width: 1000,
        //top: 20, left: 3,
        autoScroll: true,
        title: _('Help'),
        titleCollapse: true,
        //closeAction: 'destroy',
        layout: 'border',
        history: [],
        history_curr: -1,
        tbar: [
            search_box, btn_refresh, '->', btn_home, btn_left, btn_right
        ],
        items: [ docs_tree, doc_reader ]
    });
    help_win.mask = function(){
        help_win.body.mask( String.format('<img src="{0}" />', '/static/images/loading.gif' ) ).setHeight(9999);
    }
    help_win.unmask = function(){
        help_win.body.unmask();
    }
    help_win.history_push = function(path){
        if( help_win.history[help_win.history.length-1] != path ) {// avoid dups
            help_win.history.push( path );
        }
        help_win.history_curr = help_win.history.length-1;
        check_btns();
    }
        //help_win.getEl().fadeOut('l', { duration: .5 });
        //help_win.hide();
    help_win.show();
    //treeRoot.expand();
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
}

Cla.help_button_flash = function(params) {
    Cla.help_button.show();
    Cla.help_on();
    // there's new content, show the bulb on
    Cla.help_button.setIcon(IC('loading-fast.gif'));
    setTimeout(function(){
        Cla.help_button.setIcon(IC('lightbulb.png'));
    },400);
}

Cla.help_base_items = [
    { text:_('Clarive Help'), icon: IC('help'), handler:function(){ Cla.help_show() } },
    '-'
];
Cla.help_items = [];

Cla.help_push = function(params) {
    var items = Cla.help_menu.find( 'help_path', params.path );
    var item = {
        text: params.title,
        help_path: params.path,
        handler: function() { 
            Cla.help_show({ path: params.path+'.markdown' });
        },
        icon: (params.icon!=undefined ? params.icon : '/static/images/icons/help.png')
    };
    Cla.help_items = Cla.help_items.splice(0,9); 
    Cla.help_items.unshift( item );
    Cla.help_menu.removeAll();
    var added={};
    Ext.each( Cla.help_base_items.concat(Cla.help_items), function(it){
        if( it == '-' ) {
            Cla.help_menu.addSeparator()
        } else {
            if( added[it.help_path] ) return;
            Cla.help_menu.addMenuItem(it);
        }
        added[it.help_path] = true;
    });
    if( items==undefined || !items.length ) {
        Cla.help_button_flash();
    }
};
