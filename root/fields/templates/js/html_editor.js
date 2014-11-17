/*
name: HTML/Editor
params:
    origin: 'template'
    type: 'html/editor'
    html: '/fields/templates/html/dbl_row_body.html'
    js: '/fields/templates/js/html_editor.js'
    field_order: 2
    section: 'body'
    data: 'clob'
    field_order_html: 99
    meta_type: 'content'
---
*/
(function(params){
    var data = params.topic_data;
    var meta = params.topic_meta;
    
    allow = meta.allowBlank == undefined ? true : ( meta.allowBlank == 'false' || !meta.allowBlank ? false : true );
    readonly = meta.readonly == undefined ? true : meta.readonly;

    var editor = new Baseliner.CLEditor({
        width: '99%',
        value: data ? data[meta.bd_field] : '',
        height: meta.height ? parseInt(meta.height) : 397,
        submitValue: false, 
        readOnly:  meta && meta.readonly ? meta.readonly : false
    });


    return [
        {   xtype: 'panel',
            border: false,  
            name: meta.id_field,
            margin: 0, padding: 0,
            fieldLabel: _(meta.name_field),
            allowBlank: allow,
            hidden: meta ? (meta.hidden ? meta.hidden : false): true,
            //style: 'margin-bottom: 15px',
            readOnly : readonly,
            listeners: {
                'afterrender':function(){
                    var disable = meta && meta.readonly ? meta.readonly : false;
                    if(disable){
                        var mask = this.el.mask();
                        mask.setStyle('opacity', 0.6);
                        mask.setStyle('height', 5000);
                    }
                }
            },
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
        }               
    ]
})
