/*
name: Milestones
params:
    origin: 'template'
    html: '/fields/templates/html/grid_editor.html'
    js: '/fields/templates/js/milestones.js'
    set_method: set_cal
    get_method: get_cal
    field_order: 1
    field_order_html: 1000
    allowBlank: 'false'
    height: 300
    width: 100%
    columns: 'Milestone[slotname];Planned End Date[plan_end_date],datefield;End Date[end_date],datefield' 
    section: 'head'
    relation: system
    meta_type: 'calendar'
*/

(function(params){
    var meta = params.topic_meta;
    var data = params.topic_data;
    
    var value = data[ meta.bd_field ] || meta.default_value ;
    var records = data && data[ meta.bd_field ]? data[ meta.bd_field ] : '[]';
    var columns = meta.columns;
    if( !columns ) {
        var headers = Ext.isString(meta.headers) ? [ meta.headers.split(';') ] : [ _('Milestone'), _('Planned Date'), _('Real Date') ];
        columns = String.format('{0}[slotname],textfield,400;{1}[plan_end_date],datefield,80;{2}[end_date],datefield,80', headers[0],headers[1],headers[2]);
    }
    
    var allow = meta.allowBlank == 'false' ? false : true;
    var readonly = meta.readonly == undefined ? true : meta.readonly;
    
    var editor = new Baseliner.GridEditor({
        fieldLabel: _(meta.name_field),
        allowBlank: readonly ? true : allow,
        name: meta.id_field,
        id_field: meta.id_field,
        bd_field: meta.bd_field,
        records: records, 
        columns: columns,
        font: meta.font,
        //anchor: meta.anchor || '100%',
        width: meta.width || '100%',
        height: meta.height || 300,
        value: value || '',
        readOnly: readonly,
        disabled: readonly,
        hidden : meta ? (meta.hidden ? meta.hidden : false): true,
        enableDragDrop: !readonly,
        use_row_editor: !readonly
    });

    return [
        //Baseliner.field_label_top( meta.name_field, meta.hidden, allow, readonly ),
        //new Ext.Panel({
        //    layout:'fit',
        //    fieldLabel: _(meta.name_field),
        //    readOnly: readonly,
        //    allowBlank: allow,
        //    style: 'padding-bottom: 12px',
        //    anchor: meta.anchor || '100%',
        //    height: meta.height,
        //    border: false,
        //    items: editor
        //})
        editor
    ]
})

