Cla.AceEditor = Ext.extend( Ext.Panel, {
    gutter: true,
    mode: 'perl',
    theme: 'xcode',
    border: false,
    initComponent: function() {
        var self=this;
        // buttons
        var btnUndo = new Ext.Button({ icon:IC('undo'), handler: function(){ self.$undo() } });
        var btnRedo = new Ext.Button({ icon:IC('redo'), handler: function(){ self.$redo() } });
        self.tbar = [
            btnUndo,btnRedo 
        ];
        self.addEvents( 'aftereditor', 'docchange' );
        self.on('afterrender', function(){
            self.$createEditor();
            self.fireEvent('aftereditor');
        });
        self.on('resize', function(){
            if( self.editor && self.editor.resize ) {
                self.editor.resize();
            }
        });
        Cla.AceEditor.superclass.initComponent.call(this);
    },
    $createEditor : function(){
        var self = this;
        self.body.dom.innerHTML = "";
        self.editor = ace.edit(self.body.id);
        self.editor.setTheme("ace/theme/" + self.getTheme() );
        
        var session = self.editor.session;
        session.setMode("ace/mode/" + self.mode);
        self.editor.setHighlightActiveLine(false);
        self.editor.renderer.setShowGutter(self.gutter);
        self.track_changes = false;
        if( self.font ) {
            self.el.setStyle({ 'font': self.font });
        }
        if( self.value ) {
            self.setValue( self.value );
        }
        else if( self.data ) {
            self.setValue( self.data );
        }
        else if( self.file ) {
            self.load_file( self.file );
        }
        else {
            self.setValue( '' );
        }
    },
    getTheme : function(){
        switch( this.theme ) {
            case 'dark' : return 'idle_fingers';
            case 'light' : return 'github';
            default: return this.theme; 
        }
    },
    getValue : function(){
        return this.editor.getValue();
    },
    get_save_data : function(){
        return this.editor.getValue();
    },
    setValue : function(value){
        var self = this;
        self.editor.setValue( value );
        self.editor.getSession().selection.clearSelection();
    },
    setMode : function(v){
        this.editor.session.setMode( 'ace/mode/' + v );
    },
    setTheme : function(v){
        this.editor.setTheme( 'ace/theme/' + v );
    },
    focus : function(){
        Cla.AceEditor.superclass.focus.apply(this,arguments);
        if( this.editor ) 
            this.editor.focus();
    },
    $undo : function(){ 
        var self = this;
        self.editor.undo(); 
        self.editor.focus(); 
        self.editor.getSession().selection.clearSelection();
    },
    $redo : function(){ 
        var self = this;
        self.editor.redo(); 
        self.editor.focus(); 
        self.editor.getSession().selection.clearSelection();
    }
});

