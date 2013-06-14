(function(params){
	var meta = params.topic_meta;
	var data = params.topic_data;
    
    Baseliner.TopicGridField = Ext.extend( Baseliner.CIGrid, {
        
    });
    var grid = new Baseliner.TopicGridField({
        fieldLabel: _( meta.name_field ),
        columns: [
            'name', 
            { header:'Description', dataIndex:'description', editor: new Ext.field.TextField() }
        ]
    });
    return [
        //{ xtype:'textarea', fieldLabel:'Data', value: Ext.encode( data ), anchor:'100%' },
        //{ xtype:'textarea', fieldLabel:'Meta', value: Ext.encode( meta ), anchor:'100%' }
        grid
    ]
})
