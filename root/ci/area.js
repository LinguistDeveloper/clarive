(function(params){
    var data_value = params.rec.data || {};
    var data_value_json = Ext.util.JSON.encode( data_value );
    var store_vars = new Baseliner.store.CI({ baseParams: { role:'Variable'} });
    var combo_vars = new Ext.form.ComboBox({ 
           width: 350,
           //name: 'ci', 
           //hiddenName: 'ci', 
           submitValue: false,
           valueField: 'name', 
           displayField: 'name',
           mode:'remote',
           emptyText: _('<select variable>'),
           typeAhead: false,
           minChars: 1, 
           store: store_vars, 
           editable: false, forceSelection: true, triggerAction: 'all',
           allowBlank: true
    });
    
    var del_var = function(){
        de.del_row();
    };

    var variables_field = new Ext.form.Hidden({ name: 'data', value: data_value_json });
    /*
        not working:
        variables_field.getRawValue = function(){
            var ret = Ext.util.JSON.encode( de.data );
            console.log( ret );
            return ret;
        };
    */

    var combo_bl = Baseliner.combo_baseline({ value: '*' }); 

    var de = new Baseliner.DataEditor({
        fieldLabel: _('Variables'),
        height: 300,
        //hide_type: true,
        //cols: [{header: _("Baseline"), width: 80, sortable: true, dataIndex: 'bl', editor: new Ext.form.TextArea() }],
        col_key_width: 100, 
        col_value_width: 100, 
        tbar: [
            combo_bl,
            combo_vars, 
            { icon:'/static/images/icons/delete_.png', handler: del_var }
        ],
        data: data_value
    });

    de.on('xafterrender', function(){
      var cm = de.editor.getColumnModel();
      var ix = cm.findColumnIndex( 'type' );
      var id = cm.getColumnId( ix );
      var col = cm.getColumnById( id );
      col.hidden = true;
      de.editor.doLayout();
    });

    combo_vars.on('select', function(){
        var key = combo_vars.getValue();
        var flag = true;
        de.store.each( function(row){
            if( row.data.key == key )  flag=false;
        });
        variables_field.setValue( Ext.util.JSON.encode( de.data ) );
        if( flag ) de.add_var( key, 'Value', '');
    });
    var on_submit = function( form ){
        var d = de.getData();
        var vf = Ext.util.JSON.encode( d );
        variables_field.setValue( vf );
    };
    //var var_panel = new Ext.Panel({ layout:'fit', items: de
    return {
        beforesubmit: on_submit,
        fields: [
           variables_field 
        ]
    }
})
