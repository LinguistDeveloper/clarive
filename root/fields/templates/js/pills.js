/*
name: Pills
params:
    origin: 'template'
    type: 'combo'
    html: '/fields/templates/html/row_body.html'
    js: '/fields/templates/js/pills.js'
    field_order: 1
    allowBlank: 0
    section: 'body'
    options: 'option1,option2,option3'
*/

(function(params){
    var meta = params.topic_meta;
    var data = params.topic_data;
    
    var value = data[ meta.bd_field ] || meta.default_value ;
    var options = meta[ 'options' ];
    
    Baseliner.Pills = Ext.extend(Ext.form.Field, {
        //shouldLayout: true,
        initComponent : function(){
            Baseliner.Pills.superclass.initComponent.apply(this, arguments);
        },
        defaultAutoCreate : {tag: 'div', id: 'boot', 'class':'', style:'margin-top: 4px; height: 30px;' },
        onRender : function(){
            Baseliner.Pills.superclass.onRender.apply(this, arguments);
            this.list = [];
            var self = this;
            if( this.options != undefined  ) {
                var opts = Ext.isArray( this.options ) ? this.options : this.options.split(',');
                Ext.each(opts, function(v){
                    var li = document.createElement('li');
                    li.className = self.value == v ? 'active' : '';
                    li.style['margin-top'] = '-4px';
                    var anchor = document.createElement('a');
                    anchor.href = '#'; 
                    anchor.onclick = function(){ 
                        for( var i=0; i<self.list.length; i++) self.list[i].className = '';
                        li.className = 'active'; 
                        self.value = v;
                        self.$field.value = v;
                        return false;
                    }
                    anchor.innerHTML = v;
                    li.appendChild( anchor );
                    self.list.push( li );
                });
            }
            
            // the main navbar
            var ul = document.createElement('ul');
            ul.className = "nav nav-pills";
            for( var i=0; i<self.list.length; i++) ul.appendChild( self.list[i] );
            this.el.dom.appendChild( ul );
            
            // the hidden field
            self.$field = document.createElement('input');
            self.$field.type = 'hidden';
            self.$field.value = self.value;
            self.$field.name = self.name;
            this.el.dom.appendChild( self.$field );
        },
        // private
        redraw : function(){ 
        },
        initEvents : function(){
            this.originalValue = this.getValue();
        },
        // These are all private overrides
        getValue: function(){
            return this.value;
        },
        setValue: function( v ){
            this.value = v;
            this.redraw();
        },
        setSize : Ext.emptyFn,
        setWidth : Ext.emptyFn,
        setHeight : Ext.emptyFn,
        setPosition : Ext.emptyFn,
        setPagePosition : Ext.emptyFn,
        markInvalid : Ext.emptyFn,
        clearInvalid : Ext.emptyFn
    });
    
    var buts = new Baseliner.Pills({
        fieldLabel: _(meta.name_field),
        name: meta.id_field,
        anchor: meta.anchor || '100%',
        height: meta.height || 30,
        options: meta['options'],
        value: value
    });
    return [
        buts
    ]
})


