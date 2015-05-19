/*
name: Textfield
params:
    origin: 'template'
    type: 'textfield'
    html: '/fields/templates/html/row_body.html'
    js: '/fields/templates/js/textfield.js'
    field_order: 1
    allowBlank: true
    section: 'body'
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
            xtype:'textfield',
            fieldLabel: _(meta.name_field),
            name: meta.id_field,
            value: data && data[ meta.id_field ]!=undefined  ? data[ meta.id_field ] : ( meta.default_value || '' ), 
            style: style,
            //width: meta.width || '97%',
            anchor: meta.anchor || '100%',
            height: meta.height || 30,
            allowBlank: meta.id_field == 'title' ? false : Baseliner.eval_boolean(meta.allowBlank),
            readOnly: Baseliner.eval_boolean(meta.readonly),
            preventMark: true,
            listeners: {
                'resize': function(a,b,v,d,e){
                    //this.el.setWidth( Math.floor( this.ownerCt.el.getWidth() / 2 ) );
                    //this.el.setWidth( Math.floor( this.ownerCt.ownerCt.el.getWidth() / 2 ) - 125 );
                },
                'afterrender': function() {
                    this.preventMark = false;
                }
            },
            hidden: Baseliner.eval_boolean(meta.hidden),
            msgTarget: 'under'
        }
    ]
})
