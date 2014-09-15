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
if( ! Ext.isIE ) {
Baseliner.Ace = {};
Baseliner.Ace.Range = ace.require("./range").Range;
Baseliner.Ace.Renderer = ace.require("ace/virtual_renderer").VirtualRenderer;
Baseliner.Ace.EditSession = ace.require("ace/edit_session").EditSession;
Baseliner.Ace.EDITOR = ace.require("ace/editor").Editor;
Baseliner.Ace.THEME = ace.require("ace/theme/textmate"); 
Baseliner.Ace.UndoManager = ace.require("ace/undomanager").UndoManager;

Baseliner.AceEditor = Ext.extend( Ext.BoxComponent, {
    //autoScroll: true,
    gutter: true,
    url: '/slurp',
    theme: 'light',
    mode: 'perl',
    getTheme : function(){
        switch( this.theme ) {
            case 'dark' : return 'idle_fingers';
            case 'light' : return 'github';
            default: return this.theme; 
        }
    },
    initComponent: function() {
        var self=this;
        self.changed_lines = [];
        Baseliner.AceEditor.superclass.initComponent.call(this);
        self.addEvents( 'aftereditor', 'docchange' );
        self.on('afterrender', function(){
            self.create_editor();
            //self.editor.gotoLine( 0,0,false );
            setTimeout(function(){ self.focus(); }, 200);  // TODO find a hook for this
            self.fireEvent('aftereditor');
        });
        self.on('resize', function(){
            //if( !self.height_orig ) self.height_orig = self.el.getHeight();
            if( self.editor && self.editor.resize ) {
                //var h = self.ownerCt.getHeight();
                //var curr_h = self.el.getHeight();
                //self.el.setHeight( curr_h + ( h - self.height_orig ) );
                self.editor.resize();
            }
        });
    },
    create_editor : function(){
        var self = this;
        self.el.dom.innerHTML = "";
        self.renderer = new Baseliner.Ace.Renderer( self.el.dom );
        self.editor = new Baseliner.Ace.EDITOR(self.renderer );
        self.editor.setTheme("ace/theme/" + self.getTheme() );
        
        var session = self.editor.session;
        session.setUndoManager(new Baseliner.Ace.UndoManager());
        session.setMode("ace/mode/" + self.mode);
        self.editor.setHighlightActiveLine(false);
        self.editor.renderer.setShowGutter(self.gutter);
        self.track_changes = false;
        if( self.font ) {
            self.el.setStyle({ 'font': self.font });
        }
        session.doc.on('change', function(e){ if( e.data.action[0] == 'i' ) session._emit('changeBackMarker') });
        self.initialized = true;
        if( self.value ) {
            self.editor_value( self.value );
        }
        else if( self.data ) {
            self.editor_value( self.data );
        }
        else if( self.file ) {
            self.load_file( self.file );
        }
        else {
            self.editor_value( '' );
        }
        self.setup_change_event();
        // add key maps
        Ext.each( self.commands, function(cmd){
            self.add_command( cmd );
        });
    },
    getValue : function(){
        return this.editor.getValue();
    },
    get_save_data : function(){
        return this.editor.getValue();
    },
    setValue : function(v){
        return this.editor_value(v);
    },
    setMode : function(v){
        this.editor.session.setMode( 'ace/mode/' + v );
    },
    setTheme : function(v){
        this.editor.setTheme( 'ace/theme/' + v );
    },
    focus : function(){
        Baseliner.AceEditor.superclass.focus.apply(this,arguments);
        if( this.editor ) 
            this.editor.focus();
    },
    add_command : function(cmd){
        var commands = this.editor.commands;
        return commands.addCommand(cmd);
    },
    editor_value : function( value ){
        var self = this;
        self.editor.setValue( value );
        self.is_loaded = true;
        self.editor.getSession().selection.clearSelection();
        self.track_changes = true;
        //self.ownerCt.doLayout();
        //self.ownerCt.setHeight( 300 );
    },
    wipe_out : function(){
        var self = this;
        self.editor.destroy();
        for( var i in self.editor.session.getMarkers() ) {
            self.editor.session.removeMarker( i );
        }
        self.editor.session.clearBreakpoints();
        self.editor.setValue('');
    },
    load_file : function( file ){
        var self = this;
        Baseliner.ajaxEval( self.url, { file: file }, function(res){
            self.editor_value( res.data );
        });
    },
    delete_editor : function(){
        this.editor.destroy();
        this.el.dom.innerHTML = "";
    },
    setup_change_event : function(){
        var self = this;
        self.editor.session.doc.on('change', function(e){ 
            if( ! self.track_changes ) return;
            self.move_breakpoints( e, self.editor );
            self.create_breakpoints( e, self.editor );
            self.fireEvent( 'docchange', self, e );
        });
    },
    line : function() {
        return this.editor.getCursorPosition().row;
    },
    total_lines : function(){
        return this.editor.session.getLength(); 
    },
    find_next_marker : function( c ){
        var direction=c.direction, ln=c.ln, marker=c.marker,
            clazz=c.clazz;
        var self = this;
        var next_marker;
        for( var i=( direction=='down' ? ln+1 : ln-1 ); ( direction == 'down' ? i< self.total_lines() : i>=0 ); ( direction=='down' ? i++ : i-- ) ) {
            next_marker = self.marker_for_line( i, clazz );
            if( !next_marker ) continue;
            if( marker ) {
                if( next_marker.id != marker.id ) {
                    break;
                }
            } else {
                break;
            }
        }
        return next_marker;
    },
    markers : function( fn ) {
        var self = this;
        var markers = self.editor.session.getMarkers();
        for( var i in markers ) {
            var m = markers[i];
            var ret = fn( m );
            if( ret != undefined ) return ret;
        }
    },
    remove_selected_marks : function(){
        var self = this;
        var markers = self.editor.session.getMarkers();
        for( var i in markers ) {
            var m = markers[i];
            if( m.clazz == 'vl-selected' ) {
                self.editor.session.removeMarker( m.id );
            }
        }
    },
    marker : function( id ) {
        return this.editor.session.getMarkers()[ id ]; 
    },
    selected_marker : function(){
        var self = this;
        var markers = self.editor.session.getMarkers();
        for( var i in markers ) {
            var m = markers[i];
            if( m.clazz == 'vl-selected' ) return m;
        }
    },
    delete_markers : function( from, to, lines_too ) {
        var self = this;
        var markers = self.editor.session.getMarkers();
        for( var i in markers ) {
            var m = markers[i];
            if( m.clazz[0] != 'v' ) continue;
            if( m.range.start.row >= from && m.range.start.row < to ) {
                self.remove_marker( m );
            }
        }
        if( lines_too ) 
            self.editor.session.doc.removeLines( from, to-1 );
    },
    remove_marker : function( marker ){
        var self = this;
        if( ! marker ) return;
        self.editor.session.removeMarker( marker.id );
    },
    marker_for_line : function( line, start_str ){
        var self = this;
        var markers = self.editor.session.getMarkers();
        for( var i in markers ) {
            var m = markers[i];
            if( start_str!=undefined && !m.clazz.startsWith(start_str) ) continue; 
            if( m.clazz[0] != 'v' ) continue;
            if( line == undefined ) {
                return m;
            }
            else if( m.range.start.row <= line && line < m.range.end.row ) {
                return m; 
            }
        }
    },
    create_conflict : function( range, filler ){
        var self = this;
        var cn = 'vl-block-'+range[2];
        var conflict_id = self.mark_range( range[0], range[1], 'vl-conflict' );
        var conflict = self.marker( conflict_id );
        var to = filler ? filler.from-1 : range[1];
        conflict.block_id = self.mark_range( range[0], to, cn );
        conflict.block = self.marker( conflict.block_id );
        if( filler ) {
            conflict.filler_id = self.mark_range( filler.from, filler.to, 'vl-filler' );
            conflict.filler = self.marker( conflict.filler_id );
        }
        return conflict;
    },
    create_breakpoints : function(e, editor) {
        var self = this;
        // if it's inside a filler block, split filler block
        var from = e.data.range.start.row;
        var to = e.data.range.end.row;
        //self.editor.session.addMarker( e.data.range, 'vl-modified', 'background', false );
        if( e.data.action[0] == 'i' ) {
            // insert 
            for( var i=from; i<=to; i++ ) {
                self.editor.session.setBreakpoint( i );
                var marker = self.marker_for_line( i );
                if( marker ) {
                    self.editor.session.removeMarker( marker.id );
                }
            }
        } else {
            // remove
            for( var i=from; i<=to; i++ ) 
                self.editor.session.clearBreakpoint( i );
        }
    },
    move_breakpoints : function(e, editor) {
        var self = this;
        //TODO change current tab to asterisk (changed)
        
        var delta = e.data;
        var range = delta.range;
        var len, firstRow, f1;

        if (delta.action == "insertText") {
            len = range.end.row - range.start.row;
            firstRow = range.start.column == 0? range.start.row: range.start.row + 1;
        } else if (delta.action == "insertLines") {
            len = range.end.row - range.start.row;
            firstRow = range.start.row;
        } else if (delta.action == "removeText") {
            len = range.start.row - range.end.row;
            firstRow = range.start.row;
        } else if (delta.action == "removeLines") {
            len = range.start.row - range.end.row;
            firstRow = range.start.row;
        }
        
        var breakpoints = editor.session.getBreakpoints();
        var newBreakpoints = [];
        
        var changed = false;
        if (len > 0) {
            for( var index in breakpoints ) {
                var idx = parseInt(index);
                if( idx < firstRow ) {
                    newBreakpoints.push(idx);
                }
                else {
                    changed = true;
                    newBreakpoints.push(idx+len);
                }
            }
        } else if (len < 0) {
            for( var index in breakpoints ) {
                var idx = parseInt(index);
                
                if( idx < firstRow ) {
                    newBreakpoints.push(idx);
                }
                else if( (index < firstRow-len) && !newBreakpoints[firstRow]) {
                    newBreakpoints.push(firstRow);
                    changed = true;
                }
                else {
                    newBreakpoints.push(len+idx);
                    changed = true;
                }
            }
        }
        
        if( changed ) editor.session.setBreakpoints(newBreakpoints);
    },
    mark_range : function( from, to, cn) {
        var self = this;
        var range = new Baseliner.Ace.Range( from, null, to + 1, null);
        range.start = self.editor.session.doc.createAnchor( range.start );
        range.end = self.editor.session.doc.createAnchor( range.end );
        var mark_id = self.editor.session.addMarker( range, cn, 'background', false);
        range.id = mark_id;
        return mark_id;
    },
    mark_remove : function( mark_id ) {
        var self = this;
        self.editor.session.removeMarker( mark_id );
    },
    lines : function( joined ){
        var self = this;
        var lines = self.editor.session.doc.getAllLines();
        var doc = [];
        var fillers={};
        self.markers(function(m){
            if( m.clazz=='vl-filler' ) {
               for( var i=m.range.start.row; i<m.range.end.row; i++)
                   fillers[ i ] = true;
            }
        });
        for( var i=0; i<lines.length; i++ ) {
            if( !fillers[i] ) doc.push( lines[i] ); 
        }
        return joined ? doc.join("\n") : doc;
    },
    scroller_height : function(){
        return $(self.editor.renderer.scrollBar.inner).height();
    },
    refresh_me: function(){ },
    editor_focus: function(){ this.editor.focus() }
});

}

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

/* 
 *



Ext.ns('VL');
VL.Range = ace.require("./range").Range;
VL.FileView = Ext.extend( Ext.BoxComponent, {
    //autoScroll: true,
    gutter: false,
    initComponent: function() {
        var self=this;
        self.changed_lines = [];
        VL.FileView.superclass.initComponent.call(this);
        self.addEvents( 'aftereditor', 'docchange' );
        self.on('afterrender', function(){
            self.create_editor();
            if( self.onAfterEditor ) self.onAfterEditor();
            self.fireEvent('aftereditor');
        });
    },
    create_editor : function(){
        var self = this;
        var Renderer = ace.require("ace/virtual_renderer").VirtualRenderer;
        var EDITOR = ace.require("ace/editor").Editor;
        var UndoManager = ace.require("ace/undomanager").UndoManager;
        //var THEME = ace.require("ace/theme/textmate");  // default
        self.el.dom.innerHTML = "";
        self.renderer = new Renderer( self.el.dom );
        self.editor = new EDITOR(self.renderer);
        self.editor.setTheme("ace/theme/github");
        var session = self.editor.session;
        session.setMode("ace/mode/perl");
        self.editor.setHighlightActiveLine(false);
        self.editor.getSession().setUndoManager(new UndoManager());
        self.editor.renderer.setShowGutter(self.gutter);
        self.track_changes = false;
        session.doc.on('change', function(e){ if( e.data.action[0] == 'i' ) session._emit('changeBackMarker') });
        //self.editor.resize();
        self.initialized = true;
        if( self.data ) {
            self.editor_value( self.data );
        }
        else if( self.file ) {
            self.load_file( self.file );
        }
        self.setup_change_event();
    },
    editor_value : function( value ){
        var self = this;
        self.editor.setValue( value );
        self.is_loaded = true;
        self.editor.getSession().selection.clearSelection();
        self.track_changes = true;
        //self.ownerCt.doLayout();
        //self.ownerCt.setHeight( 300 );
    },
    wipe_out : function(){
        var self = this;
        self.editor.destroy();
        for( var i in self.editor.session.getMarkers() ) {
            self.editor.session.removeMarker( i );
        }
        self.editor.session.clearBreakpoints();
        self.editor.setValue('');
    },
    load_file : function( file ){
        var self = this;
        VL.request('/slurp', { file: file }, function(res){
            self.editor_value( res.data );
        });
    },
    delete_editor : function(){
        this.editor.destroy();
        this.el.dom.innerHTML = "";
    },
    setup_change_event : function(){
        var self = this;
        self.editor.session.doc.on('change', function(e){ 
            if( ! self.track_changes ) return;
            self.move_breakpoints( e, self.editor );
            self.create_breakpoints( e, self.editor );
            self.fireEvent( 'docchange', self, e );
        });
    },
    line : function() {
        return this.editor.getCursorPosition().row;
    },
    total_lines : function(){
        return this.editor.session.getLength(); 
    },
    find_next_marker : function( c ){
        var direction=c.direction, ln=c.ln, marker=c.marker,
            clazz=c.clazz;
        var self = this;
        var next_marker;
        for( var i=( direction=='down' ? ln+1 : ln-1 ); ( direction == 'down' ? i< self.total_lines() : i>=0 ); ( direction=='down' ? i++ : i-- ) ) {
            next_marker = self.marker_for_line( i, clazz );
            if( !next_marker ) continue;
            if( marker ) {
                if( next_marker.id != marker.id ) {
                    break;
                }
            } else {
                break;
            }
        }
        return next_marker;
    },
    markers : function( fn ) {
        var self = this;
        var markers = self.editor.session.getMarkers();
        for( var i in markers ) {
            var m = markers[i];
            var ret = fn( m );
            if( ret != undefined ) return ret;
        }
    },
    remove_selected_marks : function(){
        var self = this;
        var markers = self.editor.session.getMarkers();
        for( var i in markers ) {
            var m = markers[i];
            if( m.clazz == 'vl-selected' ) {
                self.editor.session.removeMarker( m.id );
            }
        }
    },
    marker : function( id ) {
        return this.editor.session.getMarkers()[ id ]; 
    },
    selected_marker : function(){
        var self = this;
        var markers = self.editor.session.getMarkers();
        for( var i in markers ) {
            var m = markers[i];
            if( m.clazz == 'vl-selected' ) return m;
        }
    },
    delete_markers : function( from, to, lines_too ) {
        var self = this;
        var markers = self.editor.session.getMarkers();
        for( var i in markers ) {
            var m = markers[i];
            if( m.clazz[0] != 'v' ) continue;
            if( m.range.start.row >= from && m.range.start.row < to ) {
                self.remove_marker( m );
            }
        }
        if( lines_too ) 
            self.editor.session.doc.removeLines( from, to-1 );
    },
    remove_marker : function( marker ){
        var self = this;
        if( ! marker ) return;
        self.editor.session.removeMarker( marker.id );
    },
    marker_for_line : function( line, start_str ){
        var self = this;
        var markers = self.editor.session.getMarkers();
        for( var i in markers ) {
            var m = markers[i];
            if( start_str!=undefined && !m.clazz.startsWith(start_str) ) continue; 
            if( m.clazz[0] != 'v' ) continue;
            if( line == undefined ) {
                return m;
            }
            else if( m.range.start.row <= line && line < m.range.end.row ) {
                return m; 
            }
        }
    },
    create_conflict : function( range, filler ){
        var self = this;
        var cn = 'vl-block-'+range[2];
        var conflict_id = self.mark_range( range[0], range[1], 'vl-conflict' );
        var conflict = self.marker( conflict_id );
        var to = filler ? filler.from-1 : range[1];
        conflict.block_id = self.mark_range( range[0], to, cn );
        conflict.block = self.marker( conflict.block_id );
        if( filler ) {
            conflict.filler_id = self.mark_range( filler.from, filler.to, 'vl-filler' );
            conflict.filler = self.marker( conflict.filler_id );
        }
        return conflict;
    },
    create_breakpoints : function(e, editor) {
        var self = this;
        // if it's inside a filler block, split filler block
        var from = e.data.range.start.row;
        var to = e.data.range.end.row;
        //self.editor.session.addMarker( e.data.range, 'vl-modified', 'background', false );
        if( e.data.action[0] == 'i' ) {
            // insert 
            for( var i=from; i<=to; i++ ) {
                self.editor.session.setBreakpoint( i );
                var marker = self.marker_for_line( i );
                if( marker ) {
                    self.editor.session.removeMarker( marker.id );
                }
            }
        } else {
            // remove
            for( var i=from; i<=to; i++ ) 
                self.editor.session.clearBreakpoint( i );
        }
    },
    move_breakpoints : function(e, editor) {
        var self = this;
        //TODO change current tab to asterisk (changed)
        
        var delta = e.data;
        var range = delta.range;
        var len, firstRow, f1;

        if (delta.action == "insertText") {
            len = range.end.row - range.start.row;
            firstRow = range.start.column == 0? range.start.row: range.start.row + 1;
        } else if (delta.action == "insertLines") {
            len = range.end.row - range.start.row;
            firstRow = range.start.row;
        } else if (delta.action == "removeText") {
            len = range.start.row - range.end.row;
            firstRow = range.start.row;
        } else if (delta.action == "removeLines") {
            len = range.start.row - range.end.row;
            firstRow = range.start.row;
        }
        
        var breakpoints = editor.session.getBreakpoints();
        var newBreakpoints = [];
        
        var changed = false;
        if (len > 0) {
            for( var index in breakpoints ) {
                var idx = parseInt(index);
                if( idx < firstRow ) {
                    newBreakpoints.push(idx);
                }
                else {
                    changed = true;
                    newBreakpoints.push(idx+len);
                }
            }
        } else if (len < 0) {
            for( var index in breakpoints ) {
                var idx = parseInt(index);
                
                if( idx < firstRow ) {
                    newBreakpoints.push(idx);
                }
                else if( (index < firstRow-len) && !newBreakpoints[firstRow]) {
                    newBreakpoints.push(firstRow);
                    changed = true;
                }
                else {
                    newBreakpoints.push(len+idx);
                    changed = true;
                }
            }
        }
        
        if( changed ) editor.session.setBreakpoints(newBreakpoints);
    },
    mark_range : function( from, to, cn) {
        var self = this;
        var range = new VL.Range( from, null, to + 1, null);
        range.start = self.editor.session.doc.createAnchor( range.start );
        range.end = self.editor.session.doc.createAnchor( range.end );
        var mark_id = self.editor.session.addMarker( range, cn, 'background', false);
        range.id = mark_id;
        return mark_id;
    },
    mark_remove : function( mark_id ) {
        var self = this;
        self.editor.session.removeMarker( mark_id );
    },
    lines : function( joined ){
        var self = this;
        var lines = self.editor.session.doc.getAllLines();
        var doc = [];
        var fillers={};
        self.markers(function(m){
            if( m.clazz=='vl-filler' ) {
               for( var i=m.range.start.row; i<m.range.end.row; i++)
                   fillers[ i ] = true;
            }
        });
        for( var i=0; i<lines.length; i++ ) {
            if( !fillers[i] ) doc.push( lines[i] ); 
        }
        return joined ? doc.join("\n") : doc;
    },
    scroller_height : function(){
        return $(self.editor.renderer.scrollBar.inner).height();
    },
    refresh_me: function(){ },
    editor_focus: function(){ this.editor.focus() }
});

new VL.FileView({ fieldLabel:_('Code'), height: 500, anchor:'100%', name:'code', gutter: true })


*/
