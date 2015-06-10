Baseliner.GridArrayField = Ext.extend( Ext.grid.EditorGridPanel, {
    height: 200,
    frame: true,
    clicksToEdit: 1,
    description: '',
    default_value: '*.*',
    hideHeaders: true,
    initComponent: function(){
        var self = this;
        self.viewConfig = {
            scrollOffset: 2,
            forceFit: true
        };
        self.store = new Ext.data.SimpleStore({ fields:[ self.name ] });
        //name: self.name + '_grid',
        self.cm = new Ext.grid.ColumnModel([{
            dataIndex: self.name,
            width: 390,
            editor: new Ext.form.TextField({
                allowBlank: false, 
                renderer: function(v) {  return "a" }
            })
        }]);
        self.sm = (function () {
            var rsm = new Ext.grid.RowSelectionModel({
                singleSelect: true
            });
            rsm.addListener('rowselect', function () {
                var __record = rsm.getSelected();
                return __record;
            });
            return rsm;
        })();
        
        self.tbar = [];
        
        Baseliner.GridArrayField.superclass.initComponent.call(this);
        
        //load value
        if( self.value != undefined ) {
            var push_item = function(f, v ) {
                var rr = new Ext.data.Record.create([{
                    name: f,
                    type: 'string'
                }]);
                var h = {}; h[ self.name ] = v;
                // put it in the grid store
                self.store.insert( x, new rr( h ) );
            };
            try {
                // if it's an Array or Hash
                if( typeof( self.value ) == 'object' ) {
                    for( var x=0; x < self.value.length ; x++ ) {
                        push_item( self.name, self.value[ x ] ); 
                    }
                    // save 
                    //try { self.value =Ext.util.JSON.encode( self.value ); } catch(f) {} 
                } else if( self.value.length > 0 ) {  // just one element
                    push_item( self.name, self.value ); 
                }
            } catch(e) {}
        }

        self.field = new Ext.form.Hidden({ name: self.name, value: self.value, allowBlank: 1 });
        self.field_container = new Ext.Container({ items:[] });
        
        self.getTopToolbar().add([
            self.field_container,
            {
                text: _('Add'),
                icon: '/static/images/icons/add.gif',
                cls: 'x-btn-text-icon',
                handler: function () {
                    var ___record = Ext.data.Record.create([{
                        name: self.name,
                        type: 'string'
                    }]);
                    var h = {};
                    h[ self.name ] = _( self.default_value );
                    var p = new ___record( h );
                    //self.stopEditing();
                    self.store.add(p);
                    //self.startEditing(0, 0);
                }
            }, {
                text: _('Delete'),
                icon: '/static/images/icons/delete_.png',
                cls: 'x-btn-text-icon',
                handler: function (e) {
                    var __selectedRecord = self.getSelectionModel().getSelected();
                    if (__selectedRecord != null) {
                        self.store.remove(__selectedRecord);
                    }
                }
            }, '->', self.description ]
        );

        var write_to_field = function () {
            var arr = new Array();
            self.field_container.removeAll();
            self.store.each( function(r) {
                //arr.push( r.data[ self.name ] );
                self.field_container.add( 
                    new Ext.form.Hidden({ name: self.name, value: r.data[ self.name ] })
                );
            });
            self.field_container.doLayout();
            //self.field.setValue( arr ); //Ext.util.JSON.encode( arr ) );
        };
        self.store.on('beforeaction', write_to_field );
        self.store.on('create', write_to_field );
        self.store.on('remove', write_to_field );
        self.store.on('update', write_to_field );
    }
});

(function(params){
    if( ! params ) params = {};
    
    var dirs = Baseliner.array_field({ name:'dirs',
        title:_('Directories'), label:_('Directories'), description: _('Element pattern regex to include'), 
            value: params.dirs, default_value: '/'});

    var include = new Baseliner.GridArrayField({
        name: 'include',
        value: params.rec.include, 
        fieldLabel:_('Include'), 
        description: _('Element pattern regex to include')
    });

    var exclude = Baseliner.array_field({ name:'exclude',
        title:_('Exclude'), label:_('Exclude'), description: _('Element pattern regex to exclude'),
            value: params.exclude, default_value: '\\.ext$'});
    
    return [
        include
    ]
})
