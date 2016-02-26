/*
name: Pagedown Editor
params:
    origin: 'template'
    html: '/fields/templates/html/markdown.html'
    js: '/fields/templates/js/pagedown.js'
    field_order: 1
    field_order_html: 1000
    allowBlank: 'false'
    section: 'head'
    height: 400
    meta_type: 'content'
*/

(function(params){
    var meta = params.topic_meta;
    var data = params.topic_data;
    
    var value = data[ meta.bd_field ] || meta.default_value ;
    var editor = new Baseliner.Pagedown({
        font: meta.font,
        anchor: meta.anchor || '100%',
        height: meta.height || 30,
        value: value || ''
    });
    
    var allow = Baseliner.eval_boolean(meta.allowBlank);
    var readonly = Baseliner.eval_boolean(meta.readonly);
    
    return [
        //Baseliner.field_label_top( meta.name_field, meta.hidden, allow, readonly ),
        new Ext.Panel({
            layout:'fit',
            name: meta.id_field,
            fieldLabel: _(meta.name_field),
            allowBlank: readonly ? true : allow,
            readOnly: readonly,
            hidden: Baseliner.eval_boolean(meta.hidden),
            anchor: meta.anchor || '100%',
            height: meta.height,
            border: false,
            items: editor,
            get_save_data : function(){
                return editor.getValue();
            },
            is_valid : function(){
				var is_valid = editor.getValue() != '' ? true : false;
				if (is_valid && this.on_change_lab){
					this.getEl().applyStyles('border: none; margin_bottom: 0px');
					this.on_change_lab.style.display = 'none';
				}
				return is_valid;
            }             
        })
    ]
})



