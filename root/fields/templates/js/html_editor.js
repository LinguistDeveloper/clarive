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
    
    allow = Baseliner.eval_boolean(meta.allowBlank);
    readonly = Baseliner.eval_boolean(meta.readonly);

    var editor = new Baseliner.CLEditor({
        width: '99%',
        value: data ? data[meta.bd_field] : '',
        height: meta.height ? parseInt(meta.height) : 397,
        submitValue: false, 
        readOnly: Baseliner.eval_boolean(meta.readonly)
    });

    function strip_html(html){
       var tmp = document.createElement("DIV");
       tmp.innerHTML = html;
       return tmp.textContent || tmp.innerText || "";
    }


    return [
        {   xtype: 'panel',
            border: false,  
            name: meta.id_field,
            margin: 0, padding: 0,
            fieldLabel: _(meta.name_field),
            allowBlank: allow,
            hidden: Baseliner.eval_boolean(meta.hidden),
            //style: 'margin-bottom: 15px',
            readOnly : readonly,
            listeners: {
                'afterrender':function(){
                    var disable = Baseliner.eval_boolean(meta.readonly);
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
                var text = strip_html(editor.getValue());
                text = text.replace(/\s+/g, '');
                var is_valid = text != '' ? true : false;
                if (is_valid && this.on_change_lab){
                    this.getEl().applyStyles('border: none; margin_bottom: 0px');
                    this.on_change_lab.style.display = 'none';
                }
                                                
                                
                return is_valid;
            }               
        }               
    ]
});
