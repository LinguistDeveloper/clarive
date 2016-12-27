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
    var DEFAULT_TEXTPLAIN_MAX_LENGTH = 524288;
    var DEFAULT_TEXTFIELD_MAX_LENGTH = 255;
    var DEFAULT_TEXTPLAIN_HEIGHT = 400;
    var DEFAULT_TEXTFIELD_HEIGHT = 30 ;
    Ext.BLANK_IMAGE_URL = '/static/ext/resources/images/default/s.gif';
    var meta = params.topic_meta;
    var data = params.topic_data;
    var allowBlank = meta.key == 'fieldlet.system.title' ? false : Baseliner.eval_boolean(meta.allowBlank, true);

    var height = meta.height ? meta.height : ( meta.type === 'textarea' ? DEFAULT_TEXTPLAIN_HEIGHT: DEFAULT_TEXTFIELD_HEIGHT );
    var maxLength = meta.maxLength ? meta.maxLength : ( meta.type === 'textarea' ? DEFAULT_TEXTPLAIN_MAX_LENGTH : DEFAULT_TEXTFIELD_MAX_LENGTH );

    var style = { 'font-size': '16px',
            'font-weight': meta.font_weight || ( meta.key == 'fieldlet.system.title' ? 'bold' : 'normal' ),
            'font-family':'Helvetica Neue,Helvetica,Arial,sans-serif' };
    if( Ext.isIE ) style['margin-top'] = '1px';
    return [
        {
            xtype: meta.type,
            fieldLabel: _(meta.name_field),
            name: meta.id_field,
            value: data && data[ meta.id_field ]!=undefined  ? data[ meta.id_field ] : ( meta.default_value || '' ),
            style: style,
            //width: meta.width || '97%',
            anchor: meta.anchor || '100%',
            height: height,
            allowBlank: allowBlank,
            readOnly: Baseliner.eval_boolean(meta.readonly, true),
            maxLength: maxLength,
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
            hidden: Baseliner.eval_boolean(!meta.active),
            msgTarget: 'under'
        }
    ]
})
