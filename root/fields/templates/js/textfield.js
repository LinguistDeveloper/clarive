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
    var meta = params.topic_meta;
    var data = params.topic_data;
    var style = { 'font-size': '16px', float: 'left', 
            'font-weight': meta.font_weight || ( meta.id_field == 'title' ? 'bold' : 'normal' ), 
            'font-family':'Helvetica Neue,Helvetica,Arial,sans-serif' };
    if( Ext.isIE ) style['margin-top'] = '1px';

    return [
        {
            xtype:'textfield',
            fieldLabel: _(meta.name_field),
            name: meta.id_field,
            value: data && data[ meta.bd_field ]!=undefined  ? data[ meta.bd_field ] : ( meta.default_value || '' ), 
            style: style,
            //width: meta.width || '97%',
            anchor: meta.anchor || '100%',
            height: meta.height || 30,
            allowBlank: meta ? !!meta.allowBlank : false,
            readOnly: meta ? meta.readonly : true,
            listeners: {
                'resize': function(a,b,v,d,e){
                    //this.el.setWidth( Math.floor( this.ownerCt.el.getWidth() / 2 ) );
                    //this.el.setWidth( Math.floor( this.ownerCt.ownerCt.el.getWidth() / 2 ) - 125 );
                }
            },
            hidden: meta ? (meta.hidden ? meta.hidden : false): true
        }
    ]
})
