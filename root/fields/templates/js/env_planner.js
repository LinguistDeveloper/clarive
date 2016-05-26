
(function(params){
    var meta = params.topic_meta;
    var data = params.topic_data;

    var value = data[ meta.bd_field ] || meta.default_value ;
    var records = data && data[ meta.bd_field ]? data[ meta.bd_field ] : '[]';
    var columns = meta.columns;

    var allow = Baseliner.eval_boolean(meta.allowBlank);
    var readonly = Baseliner.eval_boolean(meta.readonly);

    var geditor = new Baseliner.GridEditor({
        fieldLabel: _(meta.name_field),
        cls:'planner',
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
    if ( geditor && geditor.editor ) {
        geditor.editor.on('validateedit',function(ed, changes, r, rowIndex){
            var row_final = Ext.apply({},changes);
            var r_data = Ext.apply({},r.data);

            if( row_final.plan_start_date > row_final.plan_end_date ) {
                Cla.warning(_(meta.name_field),_('Start date is after end date'));
                return false;
            }

            if( row_final.plan_start_date && !row_final.plan_end_date){
                if(row_final.plan_start_date > r_data.plan_end_date && r_data.plan_end_date != ''){
                    row_final.plan_start_date = r_data.plan_start_date;
                    Cla.warning(_(meta.name_field),_('Start date is after end date'));
                    return false;
                }
            }

            if( !row_final.plan_start_date && row_final.plan_end_date){
                if(r_data.plan_start_date > row_final.plan_end_date){
                    row_final.plan_end_date = r_data.plan_end_date;
                    Cla.warning(_(meta.name_field),_('Start date is after end date'));
                    return false;
                }

            }

            var ret = true;
            geditor.store.each(function(row){
                if( row.data.slotname===undefined || row.data.slotname.length==0 ) return;
                if(row.data.slotname==changes.slotname){
                    Baseliner.message(_(meta.name_field),_('Environment `%1` already exists', changes.slotname));
                    ret=false;
                }
            });
            return ret;
        });
    }
    return [
        geditor
    ]
})


