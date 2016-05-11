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
    } else {
        var arr_columns = columns.split(';');
        var found = false;
        for (var column = 0; column < arr_columns.length; column++) {
            if ( arr_columns[column].indexOf('[slotname]') ) {
                found = true;
            }
        };
        if ( !found ) {
            arr_columns.unshift('Milestone[slotname],textfield,200');
            columns = arr_columns.join(';');
        };
    }

    var allow = Baseliner.eval_boolean(meta.allowBlank);
    var readonly = Baseliner.eval_boolean(meta.readonly);

    var editor = new Baseliner.GridEditor({
        fieldLabel: _(meta.name_field),
        cls: 'milestone_table',
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
        hidden : Baseliner.eval_boolean(!meta.active),
        enableDragDrop: !readonly,
        use_row_editor: !readonly
    });
    if ( editor && editor.editor ) {
        editor.editor.on('validateedit',function(ed, changes, r, rowIndex){

            var row_final = Ext.apply({},changes);
            var r_data = Ext.apply({},r.data);

            if( row_final.start_date > row_final.end_date && row_final.plan_start_date > row_final.plan_end_date ) {
                Cla.warning(_(meta.name_field),_('Planned start and start date are after ends dates'));
                return false;
            }else{
                if( row_final.plan_start_date > row_final.plan_end_date ) {
                    Cla.warning(_(meta.name_field),_('Planned start date is after planned end date'));
                    return false;
                }
                if( row_final.start_date > row_final.end_date ) {
                    Cla.warning(_(meta.name_field),_('Start date is after end date'));
                    return false;
                }
            }

            if( row_final.plan_start_date && !row_final.plan_end_date){
                if(row_final.plan_start_date > r_data.plan_end_date && r_data.plan_end_date != ''){
                    row_final.plan_start_date = r_data.plan_start_date;
                    Cla.warning(_(meta.name_field),_('Planned start date is after planned end date'));
                    return false;
                }
            }

            if( !row_final.plan_start_date && row_final.plan_end_date){
                if(r_data.plan_start_date > row_final.plan_end_date){
                    row_final.plan_end_date = r_data.plan_end_date;
                    Cla.warning(_(meta.name_field),_('Planned start date is after planned end date'));
                    return false;
                }

            }

            if( row_final.start_date && !row_final.end_date){
                if(row_final.start_date > r_data.end_date && r_data.end_date != ''){
                    row_final.start_date = r_data.start_date;
                    Cla.warning(_(meta.name_field),_('Start date is after end date'));
                    return false;
                }
            }

            if( !row_final.start_date && row_final.end_date){
                if(r_data.start_date > row_final.end_date){
                    row_final.end_date = r_data.end_date;
                    Cla.warning(_(meta.name_field),_('Start date is after end date'));
                    return false;
                }

            }

            var ret = true;
            return ret;
        });
    }
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

