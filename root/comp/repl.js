(function(){
    Cla.help_push({ title:_('REPL'), path:'devel/repl' });
    var last_name = "";

    var REPL_CONFIGURATION = {
        lang: [{
            text: 'JS Server',
            lang: 'js-server',
            icon: 'repl-lang-js'
        }, {
            text: 'Perl',
            lang: 'perl',
            icon: 'repl-lang-perl'
        }, {
            text: 'JS Client',
            lang: 'js-client',
            icon: 'repl-lang-js-client'
        }, {
            text: 'CSS',
            lang: 'css',
            icon: 'repl-lang-css',
            checked: true
        }, {
            text: 'SQL',
            icon: 'repl-lang-sql',
            lang: 'sql'
        }],
        out: [{
            text: 'YAML',
            out: 'yaml',
            icon: 'logo-yaml'
        }, {
            text: 'JSON',
            out: 'json',
            icon: 'logo-json'
        }, {
            text: 'Table',
            out: 'table',
            icon: 'repl-table'
        }, {
            text: 'Data Editor',
            out: 'data_editor',
            icon: 'repl-data-editor'
        }],
        theme: [{
            text: 'Eclipse',
            theme: 'eclipse'
        }, {
            text: 'Chaos',
            theme: 'chaos'
        }, {
            text: 'Idle Fingers',
            theme: 'idle_fingers'
        }, {
            text: 'Clouds',
            theme: 'clouds'
        }, {
            text: 'Terminal',
            theme: 'terminal'
        }]
    };

    for (var key in REPL_CONFIGURATION) {
        REPL_CONFIGURATION[key + '_map'] = {};
        Ext.each(REPL_CONFIGURATION[key], function(item) {
            REPL_CONFIGURATION[key + '_map'][item[key]] = item;
        });
    }

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
    if( Cla.AceEditor === undefined ) Cla.AceEditor = { theme: 'eclipse', mode: { name:'perl' } };

    var aceditor = new Cla.AceEditor({
        name: 'code',
        mode: 'js',
        tbar: undefined,
        value: example_js
    });

    var search = new Baseliner.SearchField({
        width: 180,
        params: {start: 0, limit: 100 },
        onTrigger1Click : function(){
            if(this.hasSearch){
                this.el.dom.value = '';

                reload_root();

                this.triggers[0].hide();
                this.hasSearch = false;
            }
        },
        onTrigger2Click : function(){
            var v = this.getRawValue();
            if(v.length < 1){
                this.onTrigger1Click();
                return;
            }

            tree.root.collapseChildNodes();
            var results = tree.root.appendChild({ text: 'Search Results: ' + v, leaf: false, url: '', icon:IC('folder-explore') });
            results.expand();
            tree.root.eachChild( function(n) {
                var url = n.attributes.url;
                if( url === undefined ) return;
                var bb = { query: v };
                Ext.apply(bb, n.attributes.data, bb );
                xxx += "\n" + url;
                set_output( xxx );
                Baseliner.ajaxEval( url, bb, function(res) {
                    if( res !== undefined && typeof(res) == 'object' ){
                        results.appendChild( res );
                    }
                });
            });
            this.hasSearch = true;
            this.triggers[0].show();
        }
    });
    search.on('click', function(){ alert('ok'); });

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
        containerScroll : true,
        tbar: [ search,
            {   xtype: 'button',
                tooltip:_('Refresh Node'),
                icon:IC('refresh'),
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

    tree.getLoader().on("beforeload", function(loader, node) {
        if( node.attributes.url !== undefined ) {
            if( node.attributes.url === "" ) return false;
            loader.dataUrl = node.attributes.url;
        }
        loader.baseParams = node.attributes.data;
    });

    tree.on('click', function(n,e) {
        if( n.attributes.url_click !== undefined ) {
            Baseliner.ajaxEval( n.attributes.url_click, n.attributes.data, function(res) {
                if( res.code ) {
                    last_name= n.text;
                    aceditor.setValue( res.code );
                }
                if( res.output ) set_output( res.output );

                if (res.lang) {
                    langMenu.get(menuElementByValue(langMenu, res.lang)).setChecked(true);
                }

                if (res.out) {
                    outMenu.get(menuElementByValue(outMenu, res.out)).setChecked(true);
                }

                if( res.div ) {
                    var tab = outputTabPanel.add({ xtype:'panel', closable: true,
                        style: { padding: '10px 10px 10px 10px' },
                        title: n.text, html: '<div id="boot">' + res.div + '</div>',
                        iconCls: 'icon-method' });
                    outputTabPanel.setActiveTab( tab );
                    outputTabPanel.expand( true );
                }
                if(!(n instanceof Ext.tree.AsyncTreeNode)){
                    var tooltip = Cla.truncateTooltip(n.text);
                    panel.setTabTip(tooltip);
                    n.text = Cla.truncateText(n.text);
                    panel.setTitle("REPL - " + n.text);

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
        style: 'background: black; background-image: none; color: #10C000; font-family: "DejaVu Sans Mono", "Courier New", Courier',
        width: 700,
        height: 300
    });

    var outputTabPanel = new Ext.TabPanel({
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
            Baseliner.button('Clear', IC('clear'), function(b) { set_output(""); } ),
            Baseliner.button('Close All', IC('clear'), function(b) {
                outputTabPanel.items.each(function(comp) {
                    if( comp.initialConfig.closable ) {
                        outputTabPanel.remove( comp );
                        comp.destroy();
                    }
                });
            }),
            Baseliner.button(_('Maximize'), IC('detach'), function(b) {
                var tab = outputTabPanel.getActiveTab();
                if( tab.initialConfig.closable ) {
                    Baseliner.addNewTabItem( tab, '' );
                } else {
                    var to = new Ext.form.TextArea({ title: 'Output', value: output.getValue() });
                    Baseliner.addNewTabItem( to , '' );
                }
            }),
            Baseliner.button(_('Raw'), IC('detach'), function(b) {
                var ww = window.open('about:blank', '_blank' );
                ww.document.title = _('REPL');
                ww.document.write( '<pre>' + output.getValue() + '</pre>' );
                ww.document.close();
            }),
            '->',
            Baseliner.button('Collapse', IC('arrow-down-color'), function(b) { outputTabPanel.collapse(true); } )
        ],
        region: 'south'
    });

    function set_output( data ) {
        output.setValue( data );
        outputTabPanel.setActiveTab( output );
        if( data && data !== '' )
            outputTabPanel.expand(true);
    }

    var save = function(params) {
        var dt = new Date();
        var short = params.c.substring(0,20);
        var node_name = params.tx || dt.format("Y-m-d H:i:s") + ": " + short;
        if( params.save!==undefined && params.save ) {
            last_name = node_name;
            var f = codeFormPanel.getForm();
            f.submit({ url:'/repl/save', params: { code: params.c, id: params.tx, output: params.o, lang: params.lang, out: params.out} });
        }
    };

    var show_table = function( d ) {
        try {
            if( ! Ext.isArray( d ) ) {
                if( Ext.isObject( d ) ) d = [d];
                else { d = [ { value: d } ] ; }
            }
            var ag = new Baseliner.AutoGrid({ data: d, closable:true, title:_('%1', outputTabPanel.items.length ) });
            outputTabPanel.add( ag );
            outputTabPanel.setActiveTab( ag );
        } catch(e) { set_output( e ); }
    };

    var show_data_editor = function( d ) {
        try {
            if( ! Ext.isArray( d ) ) {
                if( Ext.isObject( d ) ) d = [d];
                else { d = [ { value: d } ] ; }
            }
            var ag = new Baseliner.DataEditor({ data: d, closable:true, title:_('%1', outputTabPanel.items.length ) });
            outputTabPanel.add( ag );
            outputTabPanel.setActiveTab( ag );
        } catch(e) { set_output( e ); }
    };

    var save_hist = function(){
        Baseliner.ajaxEval( '/repl/save_hist', { code: aceditor.getValue(), lang: langButton.lang }, function(res){
            reload_hist();
        });
    };

    var reload_hist = function(){
        var hist = tree.root.firstChild;
        if( hist && hist.isExpanded() ) {
            hist.reload();
        }
    };

    function processPacket(show, packet) {
        if (!packet.length) {
            return;
        }

        try {
            packet = JSON.parse(packet);
        } catch (e) {
            console.log('error parsing JSON ' + e);
            return;
        }

        var value = output.getValue();

        if (packet.type === 'output') {
            output.setValue(value + packet.data);
        } else if (packet.type === 'result') {
            Cla.tabpanel().changeTabIcon(panel, IC('console'));
            elapsed.setValue(packet.data.elapsed);

            if (!packet.data.error) {
                if (show == 'table' || show == 'data_editor') {
                    if (show == 'table') {
                        show_table(packet.data.result);
                    } else {
                        show_data_editor(packet.data.result);
                    }
                } else {
                    output.setValue(value + packet.data.result);

                    status.setValue("OK");
                    document.getElementById(output.getId()).style.color = "#10c000";
                }
            } else {
                output.setValue(value + packet.data.error);

                status.setValue("ERROR");
                document.getElementById(output.getId()).style.color = "#f54";
            }

            save_hist();
            aceditor.focus();
            reload_hist();
        }
    }

    var run_repl = function(){
        var lang = langButton.lang;
        var dump = 'yaml', show = 'cons';
        if( outButton.out == 'yaml' ) dump = 'yaml';
        else if( outButton.out == 'json' ) dump = 'json';
        else if( outButton.out == 'table' ) { dump = 'json'; show = 'table'; }
        else if( outButton.out == 'data_editor' ) { dump = 'json'; show = 'data_editor'; }

        document.getElementById(output.getId()).style.color = "#10c000";
        elapsed.setValue('');

        if( lang == 'perl' || lang == 'js-server' || lang == 'sql' ) {
            Cla.tabpanel().changeTabIcon(panel, "/static/images/loading/loading-fast.gif");

            output.setValue('');

            var xhr = new XMLHttpRequest();
            var params = "lang=" + lang + "&dump=" + dump + "&code=" + encodeURIComponent(aceditor.getValue());

            var offset = 0;
            xhr.open("POST", "/repl/eval", true);
            xhr.onprogress = function(e) {
                var messagePayload = '';
                var messageLength = 0;

                while (offset < xhr.responseText.length) {
                    var indexOfSep = xhr.responseText.indexOf("\n", offset);
                    if (indexOfSep != -1) {
                        messageLength = parseInt(xhr.responseText.substr(offset, indexOfSep - offset));
                        messagePayload = xhr.responseText.substr(indexOfSep + 1, messageLength);

                        if (messagePayload.length >= messageLength) {
                            offset += (indexOfSep - offset) + 1 + messageLength;

                            processPacket(show, messagePayload);
                        }
                        else {
                            return;
                        }
                    }
                    else {
                        return;
                    }
                }
            };
            xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
            xhr.send(params);
        }
        else if( lang=='js-client' ) {
            var d;
            try {
                set_output( '' );
                save_hist();
                eval("d=(function(){ " + aceditor.getValue() + " }) ");
                d = d();
                if( show == 'table' && d !== undefined ) {
                    show_table( d );
                } else if( show == 'data_editor' && d !== undefined ) {
                    show_data_editor( d );
                } else {
                    if( Ext.isObject( d ) || Ext.isArray( d ) ) d = Ext.util.JSON.encode( d );
                    set_output( d );
                }
            } catch(e) {
                set_output( e + "" );
            }
        }
        else if( lang=='css' ) {
            var style = document.createElement('style');
            style.innerHTML = aceditor.getValue();
            style.type = 'text/css';
            document.getElementsByTagName('head')[0].appendChild(style);
        }
    };

    function changeLangHandler(menu, checked) {
        if (checked) {
            var lang = menu.value;
            var txt = aceditor.getValue();

            var syntax;
            if (lang == 'js-server' || lang == 'js-client') {
                syntax = 'javascript';
            }
            else if (lang == 'perl') {
                syntax = 'perl';
            }
            else if (lang == 'css') {
                syntax = 'css';
            }
            else if (lang == 'sql') {
                syntax = 'plsql';
            }
            aceditor.setMode(syntax);
            aceditor.setValue(txt);

            var language = REPL_CONFIGURATION.lang_map[lang];
            langButton.setText(_('Lang: %1', '<b>' + language.text + '</b>'));
            langButton.setIcon(IC('' + language.icon + ''));
            langButton.lang = lang;

            aceditor.focus();

            Baseliner.ajaxEval('/user/update_repl_config', {
                lang: language.lang
            }, function(res) {});
        }
    }

    function changeOutHandler(menu, checked) {
        if (checked) {
            var out = REPL_CONFIGURATION.out_map[menu.value];

            outButton.setText(_('Output: %1', '<b>' + out.text + '</b>'));
            outButton.setIcon(IC('' + out.icon + ''));
            outButton.out = out;

            aceditor.focus();

            Baseliner.ajaxEval('/user/update_repl_config', {
                out: out.out
            }, function(res) {});
        }
    }

    function changeThemeHandler(menu, checked) {
        if (checked) {
            var theme = REPL_CONFIGURATION.theme_map[menu.value];

            aceditor.setTheme(theme.theme);
            aceditor.focus();

            Baseliner.ajaxEval('/user/update_repl_config', {
                theme: theme.theme
            }, function(res) {});
        }
    }

    var themeMenu = new Ext.menu.Menu({
        items: REPL_CONFIGURATION.theme.map(function(theme) {
            return {
                text: theme.text,
                value: theme.theme,
                checked: false,
                group: 'menu-theme',
                checkHandler: changeThemeHandler
            }
        })
    });

    var configMenu = new Ext.menu.Menu({
        items: [{
            text: _('Theme'),
            icon: IC('wrench'),
            menu: themeMenu
        }]
    });

    var langMenu = new Ext.menu.Menu({
        items: REPL_CONFIGURATION.lang.map(function(lang) {
            return {
                text: lang.text,
                value: lang.lang,
                checked: false,
                group: 'menu-lang',
                checkHandler: changeLangHandler
            }
        })
    });

    var langButton = new Ext.Button({
        text: _('Lang'),
        icon: IC('register-view'),
        cls: 'x-btn-text-icon',
        menu: langMenu
    });

    function menuElementByValue(menu, value) {
        var id;
        menu.items.items.map(function(item) {
            if (item.value === value) {
                id = item.id;
            }
        });
        return id;
    }

    var outMenu = new Ext.menu.Menu({
        items: REPL_CONFIGURATION.out.map(function(out) {
            return {
                text: out.text,
                value: out.out,
                checked: false,
                group: 'menu-out',
                checkHandler: changeOutHandler
            }
        })
    });

    var outButton = new Ext.Button({
        text: _('Output'),
        icon: IC('register-view'),
        cls: 'x-btn-text-icon',
        menu: outMenu
    });

    aceditor.on('aftereditor', function(){
        HashHandler = ace.require("ace/keyboard/hash_handler").HashHandler;
        var editor_keys = new HashHandler([{
            bindKey: "Cmd-Enter|Ctrl-Enter", exec: function(ed){
                run_repl();
            }
        }]);
        aceditor.editor.keyBinding.addKeyboardHandler(editor_keys);

        Baseliner.ajaxEval('/user/repl_config', {}, function(res){
            var lang = res.data.lang || 'js-server';
            var out = res.data.out || 'yaml';
            var theme = res.data.theme || 'eclipse';

            langMenu.get(menuElementByValue(langMenu, lang)).setChecked(true);
            outMenu.get(menuElementByValue(outMenu, out)).setChecked(true);
            themeMenu.get(menuElementByValue(themeMenu, theme)).setChecked(true);
        });

        aceditor.focus();
    });

    var tbar = [
            {   xtype: 'button',
                text: _('Run'),
                icon: IC('play'),
                cls: 'x-btn-text-icon',
                handler: run_repl
            },
            langButton,
            outButton,
            {   xtype: 'button',
                text: _('Save'),
                icon: IC('save'),
                cls: 'x-btn-text-icon',
                handler: function(){
                    Ext.Msg.prompt('Name', 'Save as:', function(btn, text){
                        if (btn == 'ok'){
                            save({ c: aceditor.getValue(), o: output.getValue(), tx: text, save: true, lang: langButton.lang, out: outButton.out });
                            var tooltip = Cla.truncateTooltip(text);
                            panel.setTabTip(tooltip);
                            text = Cla.truncateText(text);
                            panel.setTitle("REPL - " + text);
                        }
                    }, undefined, false, last_name );
                }
            },
            {   xtype: 'button',
                text: _('Export all to file'),
                icon:IC('drive-go'),
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
                icon:IC('delete'),
                cls: 'x-btn-text-icon',
                handler: function(){
                    var selectedNode = tree.getSelectionModel().getSelectedNode();
                    if( selectedNode === undefined ) return;
                    var id = selectedNode.text;
                    Ext.Msg.confirm(_('Confirmation'), _('Are you sure you want to delete the entry %1?', id),
                            function(btn){
                                if(btn=='yes') {
                                    Ext.Ajax.request({
                                        url: '/repl/delete',
                                        params: { id: id },
                                        success: function(xhr) {
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
                icon:IC('tidy'),
                cls: 'x-btn-text-icon',
                handler: function(){
                    var lang = langButton.lang;
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
                icon:IC('wrench'),
                cls: 'x-btn-text-icon',
                menu: configMenu
            },
            { xtype:'button',
                icon: IC('fullscreen'),
                tooltip:_('Fullscreen'),
                enableToggle: true,
                pressed: false,
                toggleGroup: 'x-fullscreen-repl',
                handler:function(){
                    if( this.pressed ) {
                        codeFormPanel.$lastParent = codeFormPanel.el.dom.parentElement;
                        document.body.appendChild( codeFormPanel.el.dom );
                        $(codeFormPanel.el.dom).css({ width:'', left:0, right:0, 'z-index':9999 });
                        codeFormPanel.setWidth( $(document).width() );
                        codeFormPanel.setHeight( $(document).height() );
                        aceditor.focus();
                    } else {
                        codeFormPanel.$lastParent.appendChild( codeFormPanel.el.dom );
                        codeFormPanel.doLayout();
                        codeFormPanel.ownerCt.doLayout();
                        aceditor.focus();
                    }
                }
            }
    ];

    var codeFormPanel = new Baseliner.FormPanel({
        layout: 'fit',
        region: 'center',
        split: true,
        url: '/repl/eval',
        frame: false,
        hideLabel: false,
        tbar: tbar,
        items: [aceditor]
    });

    var panel = new Ext.Panel({
        title: _('REPL'),
        layout: 'border',
        items: [ tree, codeFormPanel, outputTabPanel ]
    });

    Baseliner.edit_check( panel, true );

    tree.expand();

    return panel;
})();
