/*
REPL component.

To do:
    - line numbering
    - coloring in the console
    - save to file in a /Files folder
    - trim output on the server side

*/
(function(){
    var last_mode = { eval: true };
    var last_name = "";
    var style_cons = 'background: black; background-image: none; color: #10C000; font-family: "DejaVu Sans Mono", "Courier New", Courier';

    // This is the code that is loaded with the REPL as an example starter, indentation is important here
    var example_js = function(){/*var ci = require("cla/ci");

var obj = ci.load('1');
print(obj.name());

// files and paths
var path = require("cla/path");
var fs = require("cla/fs");

print(path.basename('/foo/bar.baz'));
// var fh = fs.openFile("${tempdir}/foo", "w");
// fh.write("foobar");
// fh.close();

// database
var db = require("cla/db");
var col = db.getCollection('test_collection');
col.insert({'foo':'bar'});
col.insert({'foo':'baz'});
col.findOne({'foo':'bar'});

// utils
cla.parseVars('${foo}',{ foo: 'bar' });
*/}.heredoc();

    // setup defaults
    if( Cla.AceEditor == undefined ) Cla.AceEditor = { theme: 'lesser-dark', mode: { name:'perl' } };

    var aceditor = new Cla.AceEditor({ 
        name: 'code',
        mode: 'js',
        tbar: undefined,
        value: example_js
    });
    aceditor.on('aftereditor',function(){
        HashHandler = ace.require("ace/keyboard/hash_handler").HashHandler;
        var editor_keys = new HashHandler([{
            bindKey: "Cmd-Enter|Ctrl-Enter", exec: function(ed){
                run_repl();
            }
        }]);
        aceditor.editor.keyBinding.addKeyboardHandler(editor_keys);
        aceditor.focus();
    });

    /*
    var thist = new Ext.tree.TreeNode({text:'History',draggable : false, expandable:true, leaf:false, url:'/repl/tree_hist' });
    var tclass = new Ext.tree.TreeNode({text:'Classes',draggable : false, expandable:true, leaf:false, url:'/repl/tree_class' });
    var tsave = new Ext.tree.TreeNode({text:'Saved',draggable : false, expandable:true, leaf:false, url:'/repl/tree_saved' });
    var tsave_delete_all = function() { var delNode; while (delNode = tsave.childNodes[0]) tsave.removeChild(delNode); }
    */

    var search = new Baseliner.SearchField({
        width: 180,
        params: {start: 0, limit: 100 },
	    onTrigger1Click : function(){ // clear button
		    if(this.hasSearch){
			    this.el.dom.value = '';
		        var v = this.getRawValue();
                // reset tree
                reload_root();
                // hide clear button
			    this.triggers[0].hide();
			    this.hasSearch = false;
		    }
	    },
	    onTrigger2Click : function(){  // search button or enter
		    var v = this.getRawValue();
		    if(v.length < 1){ //>
			    this.onTrigger1Click();
			    return;
		    }

            tree.root.collapseChildNodes();
            var results = tree.root.appendChild({ text: 'Search Results: ' + v, leaf: false, url: '', icon:'/static/images/icons/folder_magnify.png' });
            results.expand();
            tree.root.eachChild( function(n) {
                var url = n.attributes.url;
                if( url == undefined ) return;
                var bb = { query: v };
                Ext.apply(bb, n.attributes.data, bb );
                xxx += "\n" + url;
                set_output( xxx );
                Baseliner.ajaxEval( url, bb, function(res) {
                    //set_output( Ext.encode( res ) );
                    if( res != undefined && typeof(res) == 'object' ){
                        results.appendChild( res );
                    }
                });
            });
		    this.hasSearch = true;
		    this.triggers[0].show();
	    }
    });
    search.on('click', function(){ alert('ok') });
    
    function reload_root() {
        var loader = tree.getLoader();
        loader.dataUrl = tree.dataUrl;
        loader.load(tree.root);
    }

    var tree = new Ext.tree.TreePanel({
        region: 'west',
        title: _("History"),
        width: 280,
        expanded: true,
        animate : true,          
        collapsible: true,
        split: true,
        rootVisible: false,
        dataUrl: '/repl/tree_main',
        autoScroll : true,          
        //baseArgs: { singleClickExpand: true },
        containerScroll : true,          
        tbar: [ search,
            {   xtype: 'button',
                tooltip:_('Refresh Node'),
                icon:'/static/images/icons/refresh.png',
                cls: 'x-btn-icon',
                handler: function(){
                    tree.removeAll();
                    reload_root();
                }
            }
        ],
        root: {
            nodeType: 'async',
            text: '/',
            draggable:false,
            id: '/'
        },
        dropConfig : { appendOnly : true }     
    });
    //root.appendChild( thist );
    //root.appendChild( tclass );
    //root.appendChild( tsave );
    
    tree.getLoader().on("beforeload", function(loader, node) {
        if( node.attributes.url != undefined ) {
            if( node.attributes.url == "" ) return false;
            loader.dataUrl = node.attributes.url;
        }
        loader.baseParams = node.attributes.data;
    });

    // code loading on click
    tree.on('click', function(n,e) {
        if( n.attributes.url_click != undefined ) {
            Baseliner.ajaxEval( n.attributes.url_click, n.attributes.data, function(res) {
                if( res.code ) { 
                    last_name= n.text;
                    aceditor.setValue( res.code );
                }
                if( res.output ) set_output( res.output );
                if( res.lang ) change_lang({ lang: res.lang, checked: true });
                if( res.div ) {
                    var tab = cons.add({ xtype:'panel', closable: true,
                        style: { padding: '10px 10px 10px 10px' },
                        title: n.text, html: '<div id="boot">' + res.div + '</div>',
                        iconCls: 'icon-method' });
                    cons.setActiveTab( tab );
                    cons.expand( true );
                    //output_tabs.
                }
            });
        }
    });

    var status = new Ext.form.TextField({
        name: 'status',
        fieldLabel: 'Status',
        width: 700
    });

    var elapsed = new Ext.form.TextField({
        fieldLabel: 'Elapsed',
        readOnly: true,
        width: 60 
    });

    var output = new Ext.form.TextArea({
        name: 'output',
        title: _('Output'),
        closable: false,
        style: style_cons,
        width: 700,
        height: 300
    });

    var cons = new Ext.TabPanel({
        //collapsible: true,
        defaults: { closable: false, autoScroll: true }, 
          plugins: [ new Ext.ux.panel.DraggableTabs()],
        split: true,
        activeTab: 0,
        enableTabScroll: true,
        layoutOnTabChange: true,
        autoScroll: false,
        height: 350,
        items: [ output ],
        tbar: [
            Baseliner.button('Clear', '/static/images/icons/clear.gif', function(b) { set_output("") } ),
            Baseliner.button('Close All', '/static/images/icons/clear.gif', function(b) { 
                cons.items.each(function(comp) {
                    if( comp.initialConfig.closable ) {
                        cons.remove( comp );
                        comp.destroy();
                    }
                });
            }),
            Baseliner.button(_('Maximize'), '/static/images/icons/detach.png', function(b) { 
                var tab = cons.getActiveTab();
                if( tab.initialConfig.closable ) {
                    Baseliner.addNewTabItem( tab, '' );
                } else {
                    var to = new Ext.form.TextArea({ title: 'Output', value: output.getValue() });
                    Baseliner.addNewTabItem( to , '' );
                }
            }),
            Baseliner.button(_('Raw'), '/static/images/icons/detach.png', function(b) { 
                var tab = cons.getActiveTab();
                var ww = window.open('about:blank', '_blank' );
                ww.document.title = _('REPL');
                ww.document.write( '<pre>' + output.getValue() + '</pre>' );
                ww.document.close();
            }),
            '->',
            Baseliner.button('Collapse', '/static/images/icons/arrow_down.gif', function(b) { cons.collapse(true) } )
        ],
        region: 'south'
    });

    function set_output( data ) {
        output.setValue( data );
        cons.setActiveTab( output );
        if( data && data != '' ) 
            cons.expand(true);
    }

    var save = function(params) {
        var dt = new Date();
        var short = params.c.substring(0,20);
        var node_name = params.tx || dt.format("Y-m-d H:i:s") + ": " + short;
        if( params.save!=undefined && params.save ) {
            last_name = node_name;
            var f = form.getForm();
            f.submit({ url:'/repl/save', params: { code: params.c, id: params.tx, output: params.o } });
        }
    }

    var show_table = function( d ) {
        try {
            if( ! Ext.isArray( d ) ) {
                if( Ext.isObject( d ) ) d = [d];
                else { d = [ { value: d } ] ; }
            }
            var ag = new Baseliner.AutoGrid({ data: d, closable:true, title:_('%1', cons.items.length ) });
            cons.add( ag );
            cons.setActiveTab( ag );
        } catch(e) { set_output( e ); }
    };

    var show_data_editor = function( d ) {
        try {
            if( ! Ext.isArray( d ) ) {
                if( Ext.isObject( d ) ) d = [d];
                else { d = [ { value: d } ] ; }
            }
            var ag = new Baseliner.DataEditor({ data: d, closable:true, title:_('%1', cons.items.length ) });
            cons.add( ag );
            cons.setActiveTab( ag );
        } catch(e) { set_output( e ); }
    };

    var submit = function(parms) {
        if( parms.last ) {
            parms = last_mode;
        }
        last_mode = parms;
        parms.code = aceditor.getValue();
        Cla.mask = function(comp, opts) {
            var el = comp.el;
            var unmask_id = el.id || '';
            if( !opts ) opts={};

            var html = function(){/*
            <div id="boot" style="background: transparent; margin: -5px -5px 5px 5px;">
                <p><img src="/static/images/icons/loading-fast.gif" />&nbsp;<b>[%= msg %]</b></p>
                [% if( cancel ) { %]
                    <center>
                        <button class="btn btn-default btn-sm" type="button" onclick="javascript:Cla.unmask('[%= unmask_id %]');">Cancel</button>
                    </center>
                [% } %]
            </div>
            */}.tmpl( Ext.apply({ msg: _('Loading...'), cancel: false, unmask_id: unmask_id }, opts) );

            el.mask(html);

            if( opts.mask_tab ) {
                Cla.tabpanel().changeTabIcon( panel, "/static/images/loading-fast.gif" );
            }
        }
        Cla.unmask = function(id_or_cmp){
            var cmp = Ext.isObject(id_or_cmp) ? id_or_cmp : Ext.getCmp(id_or_cmp);
            if( cmp ) 
                cmp.el.unmask();
        }
        Cla.mask( panel, { msg:_('Running...'), cancel: true, mask_tab: true });
        
        save({ c: aceditor.getValue(), o: output.getValue() });

        Cla.ajax_json('/repl/eval', parms, function(res){
            var data = 
                ( res.stdout ?  res.stdout + "\n" : "" ) +  
                ( res.stderr ?  res.stderr + "\n" : "" ) +  
                res.result ;
            if( parms.show == 'table' || parms.show == 'data_editor' ) {
                try {
                    var d = Ext.util.JSON.decode( res.result );
                    if( parms.show == 'table' ) 
                        show_table( d ); 
                    else
                        show_data_editor( d );
                } catch(e){ set_output( e ) };
            } else {
                set_output( data );
                status.setValue( "OK" );
                document.getElementById( output.getId() ).style.color = "#10c000"; // green
            }
            elapsed.setValue( res.elapsed );
            aceditor.focus();
            reload_hist();

            Cla.unmask(panel);
            Cla.tabpanel().changeTabIcon( panel, IC('console') );
        },
        function(res){
            // failure
            Cla.unmask(panel);
            Cla.tabpanel().changeTabIcon( panel, IC('console') );
            status.setValue( "ERROR" );

            if( !res ) return;
            elapsed.setValue( res.elapsed );
            var data = 
                res.error + "\n" + 
                res.stdout + "\n" + 
                res.stderr ;
            set_output( data );
            document.getElementById( output.getId() ).style.color = "#f54";  // red
            aceditor.focus();
            // TODO show error line to user, if any
            //   var line = res.line ;
        });
    }
    var submit2 = function(parms) {
        //Baseliner.showLoadingMask(form.getEl(), _("Loading") );
        if( parms.last ) {
            parms = last_mode;
        }
        last_mode = parms;
        var f = form.getForm();
        set_output( "" );
        parms.lang = btn_lang.lang ;
        f.submit({
            params: parms,
            waitMsg: _('Running...'),
            success: function(f,action){
                var data = 
                    ( action.result.stdout ?  action.result.stdout + "\n" : "" ) +  
                    ( action.result.stderr ?  action.result.stderr + "\n" : "" ) +  
                    action.result.result ;
                if( parms.show == 'table' || parms.show == 'data_editor' ) {
                    try {
                        var d = Ext.util.JSON.decode( action.result.result );
                        if( parms.show == 'table' ) 
                            show_table( d ); 
                        else
                            show_data_editor( d );
                    } catch(e){ set_output( e ) };
                } else {
                    set_output( data );
                    status.setValue( "OK" );
                    document.getElementById( output.getId() ).style.color = "#10c000"; // green
                }
                elapsed.setValue( action.result.elapsed );
                save({ c: aceditor.getValue(), o: output.getValue() });
                aceditor.focus();
                reload_hist();
            },
            failure: function(f,action){
                status.setValue( "ERROR" );
                elapsed.setValue( action.result.elapsed );
                if( action.result==undefined ) return;
                var data = 
                    action.result.error + "\n" + 
                    action.result.stdout + "\n" + 
                    action.result.stderr ;
                set_output( data );
                //output.getEl().style.color = "#f33";
                document.getElementById( output.getId() ).style.color = "#f54";  // red
                aceditor.focus();
                var line = action.result.line ;
                // TODO show error line to user, if any
            }
        });
    };

    var save_hist = function(){ // only browser-eval needs this (javascript)
        Baseliner.ajaxEval( '/repl/save_hist', { code: aceditor.getValue(), lang: btn_lang.lang }, function(res){ 
            reload_hist();
        });
    }

    var reload_hist = function(){
        var hist = tree.root.firstChild;
        if( hist && hist.isExpanded() ) {
            hist.reload();
        }
    }
     
    var run_repl = function(){
        var lang = btn_lang.lang;
        var dump = 'yaml', show = 'cons';
        if( btn_out.out == 'yaml' ) dump = 'yaml';
        else if( btn_out.out == 'json' ) dump = 'json';
        else if( btn_out.out == 'table' ) { dump = 'json'; show = 'table' }
        else if( btn_out.out == 'data_editor' ) { dump = 'json'; show = 'data_editor' }

        if( lang == 'perl' ) {
            submit({ eval: true, dump: dump, show: show, lang: 'perl' });
        }
        else if( lang=='js-server' ) {
            submit({ eval: true, dump: dump, show: show, lang: 'js-server' });
        }
        else if( lang=='js-client' ) {
            var d;
            try { 
                set_output( '' );
                save_hist();
                eval("d=(function(){ " + aceditor.getValue() + " }) ");
                d = d();
                if( show == 'table' && d != undefined ) {
                    show_table( d ); 
                } else if( show == 'data_editor' && d != undefined ) {
                    show_data_editor( d );
                } else {
                    if( Ext.isObject( d ) || Ext.isArray( d ) ) d = Ext.util.JSON.encode( d );
                    set_output( d );
                }
            } catch(e) {
                set_output( e + "" );
            }
            /* window
                    eval( "var code_evaled = " + editor.getValue() );
                    var win = new Ext.Window( code_evaled );
                    if( win.width == undefined ) { win.width = '90%' }
                    win.show();
            */
        }
        else if( lang=='css' ) {
            var style = document.createElement('style');
            style.innerHTML = aceditor.getValue();
            style.type = 'text/css';
            document.getElementsByTagName('head')[0].appendChild(style);
        } else {
            submit({ sql: 'array', dump: dump, show: show });
            //submit({ sql: 'array', dump: 'json', show:'table' });
            //submit({ sql: 'hash', dump: 'yaml' });
        }
    };

    var change_theme = function(x) {
        if( x.checked && aceditor.editor ) { 
            var txt = aceditor.getValue();
            aceditor.setTheme( x.theme );
            aceditor.setValue( txt );
        }
    };
    var default_lang = function(x) { return Cla.AceEditor.mode.name == x; };
    var default_theme = function(x) { return Cla.AceEditor.theme == x; };
    var change_lang = function(x) {
        if( x.checked && aceditor.editor ) { 
            var txt = aceditor.getValue();
            if( ! x.syntax ) {
               x.syntax = ( x.lang == 'sql' ? 'plsql' : x.lang ); 
            }
            if( ! x.text ) {
                x.text = ( x.lang == 'perl' ? 'Perl' : x.lang=='sql' ? 'SQL' : x.lang=='js-client' ? 'JS Client' : 'JS Server' );
            }
            aceditor.setMode( x.syntax );
            aceditor.setValue( txt );
            btn_lang.setText( _('Lang: %1', '<b>'+x.text+'</b>') );
            btn_lang.setIcon( '/static/images/icons/' + x.lang + '.png' );
            btn_lang.lang = x.lang;
            aceditor.focus();
        }
    };
    var change_out = function(x) {
        if( x.checked && aceditor.editor ) { 
            btn_out.setText( _('Output: %1', '<b>'+x.text+'</b>') );
            btn_out.setIcon( '/static/images/icons/' + x.out + '.png' );
            btn_out.out = x.out;
            aceditor.focus();
        }
    };
    var config_menu = new Ext.menu.Menu({
        items: [
            {
                text: _('Theme'),
                menu: { items: [ 
                        { text: 'Lesser-Dark', theme: 'lesser-dark', checked: default_theme('lesser-dark'), group: 'theme', checkHandler: change_theme },
                        { text: 'Eclipse', theme: 'eclipse', checked: default_theme('eclipse'), group: 'theme', checkHandler: change_theme },
                        { text: 'CodeMirror', theme: 'default', checked: default_theme('default'), group: 'theme', checkHandler: change_theme },
                        { text: 'Night', theme: 'night', checked: default_theme('night'), group: 'theme', checkHandler: change_theme },
                        { text: 'Elegant', theme: 'elegant', checked: default_theme('elegant'), group: 'theme', checkHandler: change_theme }
                ]}
            }
        ]
    });
    var menu_lang = new Ext.menu.Menu({ 
                items: [
                    { text:'JS Server', lang:'js-server', checked: true, syntax:'javascript', group:'repl-lang', checkHandler: change_lang },
                    { text:'Perl', lang:'perl', checked: true, syntax:'perl', group:'repl-lang', checkHandler: change_lang },
                    { text:'JS Client', lang:'js-client', syntax:'javascript', checked: true, group:'repl-lang', checkHandler: change_lang  },
                    { text:'CSS', lang:'css', syntax:'css', checked: true, group:'repl-lang', checkHandler: change_lang  },
                    { text:'SQL', lang:'sql', syntax:'plsql', checked: true, group:'repl-lang', checkHandler: change_lang }
                ]
    });
    var btn_lang = new Ext.Button({  
                text: _('Lang'),
                icon:'/static/images/scm/debug/genericregister_obj.gif',
                cls: 'x-btn-text-icon',
                menu: menu_lang 
            });

    aceditor.on('aftereditor', function(){
        change_lang({ text:'JS Server', lang:'js-server', syntax:'javascript', checked: true });
        change_out({ text:'YAML', out:'yaml', checked: true });
    });
    var menu_out = new Ext.menu.Menu({ 
                items: [
                    { text:_('YAML'), out:'yaml', checked: true, group:'repl-out', checkHandler: change_out },
                    { text:_('JSON'), out:'json', checked: true, group:'repl-out', checkHandler: change_out  },
                    { text:_('Table'), out:'table', checked: true, group:'repl-out', checkHandler: change_out },
                    { text:_('Data Editor'), out:'data_editor', checked: true, group:'repl-out', checkHandler: change_out }
                ]
    });
    var btn_out = new Ext.Button({  
                text: _('Output'),
                icon:'/static/images/scm/debug/genericregister_obj.gif',
                cls: 'x-btn-text-icon',
                menu: menu_out
            });

    var tbar = [
            {   xtype: 'button',
                text: _('Run'),
                icon:'/static/images/icons/debug_view.png',
                cls: 'x-btn-text-icon',
                handler: run_repl
            },
            btn_lang,
            btn_out,
            {   xtype: 'button',
                text: _('Save'),
                icon:'/static/images/icons/save.png',
                cls: 'x-btn-text-icon',
                handler: function(){
                    Ext.Msg.prompt('Name', 'Save as:', function(btn, text){
                        if (btn == 'ok'){
                            save({ c: aceditor.getValue(), o: output.getValue(), tx: text, save: true });
                        }
                    }, undefined, false, last_name );
                }
            },
            {   xtype: 'button',
                text: _('Export all to file'),
                icon:'/static/images/icons/drive_go.gif',
                cls: 'x-btn-text-icon',
                handler: function(){
                    Baseliner.ajaxEval('/repl/save_to_file',{},function(res){
                        if( res.success ) {
                            Baseliner.message(_('Console'), _('Exported all items to files.') );
                        } else {
                            Ext.Msg.alert(_('Error'), res.msg ); 
                        }
                    });
                }
            },
            {   xtype: 'button',
                text: _('Delete'),
                icon:'/static/images/icons/delete_.png',
                cls: 'x-btn-text-icon',
                handler: function(){
                    var selectedNode = tree.getSelectionModel().getSelectedNode();
                    if( selectedNode == undefined ) return;
                    var id = selectedNode.text;
                    Ext.Msg.confirm(_('Confirmation'), _('Are you sure you want to delete the entry %1?', id), 
                            function(btn){ 
                                if(btn=='yes') {
                                    Ext.Ajax.request({
                                        url: '/repl/delete',
                                        params: { id: id }, 
                                        success: function(xhr) {
                                            //saved_store.load();
                                            reload_root();
                                        }
                                    });
                                }
                            }
                    );
                }
            },
            {   xtype: 'button',
                text: _('Tidy'),
                icon:'/static/images/icons/tidy.gif',
                cls: 'x-btn-text-icon',
                handler: function(){
                    var lang = btn_lang.lang;
                    if( aceditor.editor.getSelection().isEmpty() ) aceditor.editor.selectAll();
                    var code =  aceditor.editor.getSelectedText();
                    if( lang == 'perl' ) {
                        Baseliner.ajaxEval('/repl/tidy', { code: code }, function(res){
                            if( res.success ) {
                                aceditor.editor.session.replace(aceditor.editor.selection.getRange(), res.code); 
                                aceditor.focus();
                            } else {
                                set_output( res.msg );
                            }
                        });
                    } else {
                        // js
                        Cla.use('/static/jsbeautifier/beautify.js',function(){
                            code = js_beautify(code,{});
                            aceditor.editor.session.replace(aceditor.editor.selection.getRange(), code); 
                            aceditor.focus();
                        });
                    }
                }
            },
            '->',
            _('Elapsed')+': ', elapsed,
            {   
                icon:'/static/images/icons/wrench.gif',
                cls: 'x-btn-text-icon',
                menu: config_menu
            },
            { xtype:'button',
                icon: '/static/images/icons/fullscreen.png',
                tooltip:_('Fullscreen'),
                enableToggle: true,
                pressed: false,
                toggleGroup: 'x-fullscreen-repl',
                handler:function(){
                    if( this.pressed ) {
                        //$(form.el.dom).css({ position:'absolute', top:0, left:0, bottom:0, right:0, 'z-index':9999 });
                        form.$lastParent = form.el.dom.parentElement;
                        document.body.appendChild( form.el.dom );
                        $(form.el.dom).css({ width:'', left:0, right:0, 'z-index':9999 });
                        form.setWidth( $(document).width() );
                        form.setHeight( $(document).height() );
                        aceditor.focus();
                        //form.doLayout();
                    } else {
                        //$(form.el.dom).css({ position:'', top:'', left:'', bottom:'', right:'' });
                        form.$lastParent.appendChild( form.el.dom );
                        form.doLayout();
                        form.ownerCt.doLayout();
                        aceditor.focus();
                    }
                }
            }
    ];

    var form = new Baseliner.FormPanel({
            layout   : 'fit',
            region   : 'center',
            split    : true,
            url      : '/repl/eval',
            frame    : false,
            hideLabel: false,
            tbar     : tbar,
            items    : [ aceditor ]
        }
    );
    form.setTitle("REPL");

    var panel = new Ext.Panel({
        title: _('REPL'),
        layout: 'border',
        items: [ tree, form, cons ]
    });

    Baseliner.edit_check( panel, true );  // block window closing from the beginning

    tree.expand();

    return panel;
})();


