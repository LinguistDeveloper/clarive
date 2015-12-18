Baseliner.HtmlEditor = Ext.extend(Ext.form.HtmlEditor, {
    defaultValue: (Ext.isOpera || Ext.isIE6) ? '&#160;' : '',
    initComponent : function(){
        var self = this;
        Baseliner.HtmlEditor.superclass.initComponent.call(this);
        if( Ext.isChrome ) {
            this.on('initialize', function(ht){
                ht.iframe.contentDocument.onpaste = function(e){ 
                    var items = e.clipboardData.items;
                    var blob = items[0].getAsFile();
                    var reader = new FileReader();
                    reader.onload = function(event){
                        self.insertAtCursor( String.format('<img src="{0}" />', event.target.result) );
                    }; 
                    reader.readAsDataURL(blob); 
                };
            }, this);
        }
    }
});

Baseliner.CLEditor = Ext.extend(Ext.form.TextArea, {
    fullscreen: false,
    autofocus: false,
    initComponent : function(){
        Baseliner.CLEditor.superclass.initComponent.call(this);
        var self = this;
        self.loading_field = false;
        self.addEvents(['aftereditor']);

        this.on('afterrender', function(){
            $.cleditor.buttons.fullscreen = {
                name: 'fullscreen',
                image: '../../images/icons/fullscreen-24.png',
                tooltip: _('full screen'),
                title: _("Full Screen"),
                command: "fullscreen",
                popupName: "fullscreen",
                getEnabled: function(){ return true },
                buttonClick: function(){
                    if( self.fullscreen ) {
                        // minimize
                        // TODO in Chrome, after minimize, can't paste images
                        var main = self.editor_dom();
                        $(main).css({ position:'', top:'', left:'', bottom:'', right:'' });
                        if( self.iframe_last_height ) self.cleditor.$frame.css({ height: self.iframe_last_height });
                        self.$lastParent.appendChild( main );
                        self.cleditor.refresh();
                        self.cleditor.focus();
                        self.fullscreen = false;
                    } else {
                        // max
                        var main = self.editor_dom();
                        $(main).css({ position:'absolute', top:0, left:0, bottom:0, right:0, 'z-index':9999 });
                        main.style.height = null;
                        main.style.width = null;
                        self.$lastParent = main.parentElement;
                        document.body.appendChild( main );
                        self.cleditor.refresh();
                        self.cleditor.focus();
                        self.fullscreen = true;
                        
                        // fix the iframe height, otherwise full window text looks awkward
                        var iframe = self.cleditor.$frame;
                        self.iframe_last_height = iframe.height();
                        iframe.css({ height: '94%' });
                    }
                }
            };
            var c = Ext.apply({width:"100%", height:"100%", controls:
                "bold italic underline strikethrough subscript superscript | font size " +
                "style | color highlight removeformat | bullets numbering | outdent " +
                "indent | alignleft center alignright justify | undo redo | " +
                "rule image link unlink | cut copy paste pastetext | print source fullscreen"
            }, self );
            self.cleditor = $( self.el.dom ).cleditor(c)[0];
            self.cleditor.disable(self.readOnly);

            self.on('resize', function(){
                self.cleditor.refresh();
                if( this.autofocus ) self.cleditor.focus();
            });
            if( this.autofocus ) this.cleditor.focus();
            
        });
        if( Ext.isChrome ) {
            var foo_load = function(i){
                if( i < 0 ) return;
            setTimeout( function(){  // TODO detect when the CLEditor is loaded
            
                    if( !self.cleditor ) 
                        foo_load( i-- );
                    else {
                        var iframe = self.editor_iframe() ;
                        if( iframe ) {
                            // fix caret cursor not showing on focus.
                            iframe.contentDocument.body.style.height = '90%';
                            iframe.contentDocument.documentElement.style.height = '100%'
                            self.fireEvent('aftereditor', self );
                        }
                        self.cleditor.$frame[0].contentDocument.onpaste = function(e){ 
                            var items = e.clipboardData.items;
                            var blob = items[0].getAsFile();
                            var reader = new FileReader();
                            reader.onload = function(event){
                                self.cleditor.execCommand('inserthtml',
                                    String.format('<img src="{0}" />', event.target.result) );
                                //self.insertAtCursor( String.format('<img src="{0}" />', event.target.result) );
                            }; 
                            reader.readAsDataURL(blob); 
                        };
                    }
                }, 800);
            };
            foo_load(5);
        }
    },
    setValue : function(v){
        if( this.loading_field ) return;
        Baseliner.CLEditor.superclass.setValue.call(this, v );
        if( this.cleditor ) this.cleditor.updateFrame( true );
    },
    editor_dom : function(){
        return this.cleditor ? this.cleditor.$main[0] : null;
    },
    editor_iframe : function(){
        var eldom = this.editor_dom();
        if( !eldom ) return;
        return eldom.children[1];
    },
    show : function(){
        Baseliner.CLEditor.superclass.show.apply(this, arguments);
        var dom = this.editor_dom() ;
        if( dom ) $( dom ).show(); 
    },
    hide : function(){
        Baseliner.CLEditor.superclass.hide.apply(this, arguments);
        var dom = this.editor_dom() ;
        if( dom ) $( dom ).hide();
    },
    focus : function(){
        this.cleditor.focus();  // focus con cleditor instead of textarea
    }
});

// in use by GridEditor 
Baseliner.CLEditorField = Ext.extend(Ext.form.TextArea, {
    fullscreen: false,
    autofocus: false,
    initComponent : function(){
        Baseliner.CLEditorField.superclass.initComponent.call(this);
        var self = this;
        this.on('afterrender', function(){
            $.cleditor.buttons.fullscreen = {
                name: 'fullscreen',
                image: '../../images/icons/fullscreen-24.png',
                tooltip: 'full screen',
                title: "Full Screen",
                command: "fullscreen",
                popupName: "fullscreen",
                getEnabled: function(){ return true },
                buttonClick: function(){
                    if( self.fullscreen ) {
                        // minimize
                        var main = self.editor_dom();
                        $(main).css({ position:'', top:'', left:'', bottom:'', right:'', height: self.last_height, width: self.last_width });
                        self.$lastParent.appendChild( main );
                        self.cleditor.refresh();
                        self.cleditor.focus();
                        self.fullscreen = false;
                    } else {
                        // max
                        var main = self.editor_dom();
                        self.last_width = main.style.width;
                        self.last_height = main.style.height;
                        var w = $(document).width();
                        var h = $(document).height();
                        $(main).css({ position:'absolute', top:0, height: h, width: w, left:0, bottom:0, right:0, 'z-index':99999 });
                        self.$lastParent = main.parentElement;
                        document.body.appendChild( main );
                        //main.style.width = document.body.width;
                        //main.style.height = document.body.height;
                        self.cleditor.refresh();
                        self.cleditor.focus();
                        self.fullscreen = true;
                    }
                }
            };
            var c = Ext.apply({width:"100%", height:"100%", controls:
                "fullscreen bold italic underline strikethrough subscript superscript | font size " +
                "style | color highlight removeformat | bullets numbering | outdent " +
                "indent | alignleft center alignright justify | undo redo | " +
                "rule image link unlink | cut copy paste pastetext | print source fullscreen"
            }, self );
            this.cleditor = $( self.el.dom ).cleditor(c)[0];
            self.on('resize', function(){
                self.cleditor.refresh();
                if( this.autofocus ) self.cleditor.focus();
            });
            if( this.autofocus ) 
                this.cleditor.focus();
        });
        if( Ext.isChrome ) {
            var foo_load = function(i){
                if( i < 0 ) return;
                setTimeout( function(){  // TODO detect when the CLEditor is loaded
                    if( !self.cleditor ) 
                        foo_load( i-- );
                    else
                        self.cleditor.$frame[0].contentDocument.onpaste = function(e){ 
                            var items = e.clipboardData.items;
                            var blob = items[0].getAsFile();
                            var reader = new FileReader();
                            reader.onload = function(event){
                                self.cleditor.execCommand('inserthtml',
                                    String.format('<img src="{0}" />', event.target.result) );
                                //self.insertAtCursor( String.format('<img src="{0}" />', event.target.result) );
                            }; 
                            reader.readAsDataURL(blob); 
                        };
                }, 500);
            };
            foo_load(5);
        }
    },
    editor_dom : function(){
        return this.cleditor ? this.cleditor.$main[0] : null;
    },
    show : function(){
        Baseliner.CLEditorField.superclass.show.apply(this, arguments);
        var dom = this.editor_dom() ;
        if( dom ) $( dom ).show(); 
    },
    hide : function(){
        Baseliner.CLEditorField.superclass.hide.apply(this, arguments);
        var dom = this.editor_dom() ;
        if( dom ) $( dom ).hide();
    },
    focus : function(){
        this.cleditor.focus();  // focus con cleditor instead of textarea
    }
});

/*
 *
 * CodeMirror Editor
 *
 *     new Baseliner.CodeMirror({ value: 'my $x = 100;', 
 *       run: function(){
 *         alert(this.getValue())
 *       } 
 *     });
 *
 *
 */

Baseliner.CodeMirror = Ext.extend( Ext.form.TextArea, {
    mode: 'perl',
    theme: 'light',
    initComponent : function() {
        Baseliner.CodeMirror.superclass.initComponent.call(this);
        var self = this;
        var run = function(){
            self.run();
        };
        self.addEvents(['aftereditor']);
        self.keys = Ext.apply({
            "Cmd-E": run, 
            "Cmd-Enter": run, 
            "Ctrl-Enter": run, 
            "Ctrl-E": run, 
            "Ctrl-Space": function(cm) {
                CodeMirror.simpleHint(cm, CodeMirror.javascriptHint);
            }
        }, self.keys );
        Ext.each( self.commands, function(cmd){
            var key = Ext.isWindows ? cmd.bindKey.win : cmd.bindKey.mac;
            if( ! key ) return;
            var ix = key.indexOf('Command');
            if( ix >= 0 ) {
               key = 'Cmd' + key.substring( 7 );
            }
            self.keys[ key ] = function(){ cmd.exec };
        });
        self.editor_defaults = Ext.apply({
           lineNumbers: true,
           tabMode: "indent",
           smartIndent: true,
           indentUnit: 4,
           tabSize: 4,
           electricChars: false,  // allow editor to reindent according to certain chars
           matchBrackets: true,
           extraKeys: self.keys 
        }, self.editor );
        if( ! Baseliner.CodeMirrorDefaults ) {
            Baseliner.CodeMirrorDefaults = self.editor_defaults;
        }
        self.on('afterrender', function(){
            self.editor = CodeMirror.fromTextArea( self.el.dom , self.editor_defaults );
            self.editor.setValue( self.getValue() );
            self.editor.setOption('mode', { name: self.mode });
            self.editor.setOption('theme', self.getTheme() );
            var hlLine = self.editor.setLineClass(0, "activeline");
            self.focus();
            self.fireEvent('aftereditor', self );
            // self.editor.setSize( '100%', fcode.getEl().getHeight() );
        });
    },
    get_save_data : function(){
        return this.editor 
            ? this.editor.getValue() 
            : Baseliner.CodeMirror.superclass.getValue.call(this);
    },
    getValue : function(){
        return this.editor 
            ? this.editor.getValue() 
            : Baseliner.CodeMirror.superclass.getValue.call(this);
    },
    run : function(){
        alert('undefined run()');
    },
    getTheme : function(){
        switch( this.theme ) {
            case 'dark' : return 'lesser-dark';
            case 'light' : return '';
            default: return this.theme; 
        }
    }, 
    focus : function(){
        if( this.editor ) 
            this.editor.focus();
    },
    editor_focus: function(){ this.editor.focus() },
    // cross compatibility with Ace:
    setTheme: function(theme) {   
        this.editor.setOption('theme', theme );
    },
    setMode: function(mode){
        this.editor.setOption('mode', { name: mode });
    }
});

/*
 *
 * Ace-based File Viewer ExtJS component
 *
 */

Baseliner.Editor = Ext.extend( Baseliner.CLEditor, {});

Baseliner.CodeEditor = Ext.isIE 
    ? Ext.extend(Baseliner.CodeMirror,{}) 
    : Ext.extend( Baseliner.AceEditor, {});

Baseliner.MultiEditor = Ext.extend( Ext.Panel, {
    layout:'card',
    activeItem: 0,
    constructor : function(c){
        var tg = Ext.id() + '-multieditor-card';
        var btn_html = {
            xtype: 'button',
            text: _('HTML'),
            enableToggle: true, pressed: true, allowDepress: false, toggleGroup: tg,
            handler: function(){
                self.getLayout().setActiveItem( self.html_editor );
                self.html_editor.focus();
            }
        };
        var btn_code = {
            xtype: 'button',
            text: _('Code'),
            enableToggle: true, pressed: false, allowDepress: false, toggleGroup: tg,
            handler: function(){
                self.getLayout().setActiveItem( self.code_field );
                self.code_field.focus();
                /* var com = code_field.getEl().dom;
                code = CodeMirror(function(elt) {
                    com.parentNode.replaceChild( elt, com );
                }, { 
                    value: comment_field.getValue(),
                    lineNumbers: true, tabMode: "indent", smartIndent: true, matchBrackets: true
                });
                */
            }
        };
        Baseliner.MultiEditor.superclass.constructor.call(this,Ext.apply({ 
            bbar: [ btn_html, btn_code ]
        },c));
        var self = this;
        self.html_editor = new Baseliner.CLEditor({});
        self.code_field = new Baseliner.CodeEditor({});
        self.add( self.html_editor );
        self.add( self.code_field );
    },
    doLayout: function(){
        Baseliner.MultiEditor.superclass.doLayout.apply(this,arguments);
    },
    setValue: function(v){
        this.getCurrentField().setValue(v);
    },
    getCurrentField : function(){
        this.getLayout().activeItem;
    }
});

/*

   Pagedown Editor - Stackoverflow Markdown style

            var ed = new Baseliner.Pagedown({ fieldLabel: 'Comments', value: 'eee' });
            var w = new Baseliner.Window({
                width: 800, height: 450, layout:'fit', 
                items: new Ext.FormPanel({
                    items: ed
                })
            }).show();
*/

Baseliner.Pagedown = Ext.extend(Ext.form.Field, {
    //shouldLayout: true,
    initComponent : function(){
        Baseliner.Pagedown.superclass.initComponent.apply(this, arguments);
    },
    defaultAutoCreate : {tag: 'div', 'class':'wmd-panel' },
    onRender : function(){
        Baseliner.Pagedown.superclass.onRender.apply(this, arguments);
        this.list = [];
        var self = this;
        // the main navbar
        self.id = Ext.id();
        var div_btn = document.createElement('div');
        div_btn.id = 'wmd-button-bar-' + self.id;
        this.el.dom.appendChild( div_btn );
        
        var width_parent = self.container.getWidth() - 8;

        self.$field = document.createElement('textarea');
        self.$field.className = 'wmd-input';
        self.$field.style['height'] = self.height + 'px';
        self.$field.style['width'] = width_parent + 'px'; 
        if( self.font ) 
            self.$field.style['font'] = self.font;
        self.$field.id = 'wmd-input-' + self.id;
        self.$field.value =  self.value ;
        self.$field.name =  self.name ;
        this.el.dom.appendChild( self.$field );
        
        self.label_preview = document.createElement('p');
        self.label_preview.innerHTML = _('Preview') + ':';
        this.el.dom.appendChild( self.label_preview );

        // boot based preview
        self.boot = document.createElement('div');
        self.boot.id = 'boot';
        self.preview = document.createElement('div');
        self.preview.id = "wmd-preview-" + self.id;
        self.preview.className = "well fieldlet-html";
        self.preview.style['paddingRight'] = '40px'; 
        // original classes for preview: self.preview.className = "wmd-panel wmd-preview";
        self.boot.appendChild( self.preview );   
        this.el.dom.appendChild( self.boot );   
        
        self.converter = Markdown.getSanitizingConverter();
        self.converter.hooks.chain("preBlockGamut", function (text, rbg) {
            return text.replace(/^ {0,3}""" *\n((?:.*?\n)+?) {0,3}""" *$/gm, function (whole, inner) {
                return "<blockquote>" + rbg(inner) + "</blockquote>\n";
            });
        }); 
        self.editor = new Markdown.Editor(self.converter, '-' + self.id);
        self.editor.run();
    },
    // private
    redraw : function(){ 
    },
    initEvents : function(){
        this.originalValue = this.getValue();
    },
    // These are all private overrides
    getValue: function(){
        return this.$field.value;
    },
    setValue: function( v ){
        this.value = this.$field.value = v;
        this.redraw();
    },
    onResize : function( w,r ) {
        //this.$field.style['width'] = ( w - 200 ) + 'px';
        alert( w );
        var width_parent = self.container.getWidth() - 8;
        this.$field.style['width'] = width_parent + 'px'; 
        this.preview.style['width'] = width_parent + 'px';
    },
    setSize : Ext.emptyFn,
    setWidth : Ext.emptyFn,
    setHeight : Ext.emptyFn,
    setPosition : Ext.emptyFn,
    setPagePosition : Ext.emptyFn,
    markInvalid : Ext.emptyFn,
    clearInvalid : Ext.emptyFn
});
