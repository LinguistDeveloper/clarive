/*
name: Calculated Numberfield
params:
    origin: 'template'
    type: 'calculated_numberfield'
    html: '/fields/templates/html/row_body.html'
    js: '/fields/templates/js/calculated_numberfield.js'
    field_order: 1
    allowBlank: true
    section: 'body'
    meta_type: 'number'
    operation: '$1 + $2'
    operation_fields: ''
*/

(function(params){
    Ext.BLANK_IMAGE_URL = '/static/ext/resources/images/default/s.gif';
    var meta = params.topic_meta;
    var data = params.topic_data;
    var style = { 'font-size': '16px',  
            'font-weight': meta.font_weight || ( meta.id_field == 'title' ? 'bold' : 'normal' ), 
            'font-family':'Helvetica Neue,Helvetica,Arial,sans-serif' };
    if( Ext.isIE ) style['margin-top'] = '1px';
    
    
    return [
        {
            xtype:'numberfield',
            fieldLabel: _(meta.name_field),
            name: meta.id_field,
            value: data && data[ meta.bd_field ]!=undefined  ? data[ meta.bd_field ] : ( meta.default_value || '' ), 
            style: style,
            //width: meta.width || '97%',
            anchor: meta.anchor || '100%',
            height: meta.height || 30,
            allowBlank: Baseliner.eval_boolean(meta.allowBlank),
            readOnly: Baseliner.eval_boolean(meta.readonly),
            preventMark: true,
            listeners: {
                'resize': function(a,b,v,d,e){
                    //this.el.setWidth( Math.floor( this.ownerCt.el.getWidth() / 2 ) );
                    //this.el.setWidth( Math.floor( this.ownerCt.ownerCt.el.getWidth() / 2 ) - 125 );
                },
                'afterrender': function() {
                    this.preventMark = false;
                    var calculatedValue = function () {
                        var operation = meta.operation;
                        var fields = meta.operation_fields;
                        var name_fields = fields.split(',');
                        var form = params.form.getForm();

                        for (i=0;i<name_fields.length;i++) {
                            var cad = i+1;
                            cad = "$" + cad;
                            var obj_field = form.findField(name_fields[i]);
                            if ( obj_field ) {                            
                                if ( !obj_field.on_change ) {
                                    obj_field.on_change = true;            
                                    obj_field.on('change', function() {
                                        var obj_this = form.findField(meta.id_field);
                                        obj_this.setValue(calculatedValue());
//                                        console.dir(obj_field);
                                    });
                                }
                                var field_value = obj_field.getValue() != '' ? obj_field.getValue():0;
                                operation = operation.replace(cad, field_value);
                            }
                        }
                        if ( operation != meta.operation) {
                            return eval(operation);
                        }
                    }
                    calculatedValue();
                }
            },
            hidden: Baseliner.eval_boolean(meta.hidden),
            msgTarget: 'under'
        }
    ]
})
