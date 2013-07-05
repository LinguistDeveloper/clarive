/*
name: Topic Grid
params:
    origin: 'template'
    relation: 'system'
    js: '/fields/templates/js/topic_grid.js'
    html: '/fields/templates/html/topic_grid.html'
    get_method: 'get_topics'    
    set_method: 'set_topics'
    field_order: 100
    field_order_html: 1200
    section: 'head'
---
*/
(function(params){
	var meta = params.topic_meta;
	var data = params.topic_data;
    
    /*
    Baseliner.TopicGridField = Ext.extend( Baseliner.CIGrid, {
    });
    var grid = new Baseliner.TopicGridField({
        fieldLabel: _( meta.name_field ),
        columns: [
            'name', 
            { header:'Description', dataIndex:'description', editor: new Ext.field.TextField() }
        ]
    });
    */
    var p = { 
        fieldLabel:_( meta.name_field ), 
        name: meta.id_field, 
        value: data[ meta.id_field ]
    };
    if( meta.filter!=undefined ) {
        p['combo_store'] = new Baseliner.store.Topics({ baseParams: { mid: data ? data.topic_mid : '', show_release: 0, filter: meta.filter } });
    }
    var grid = new Baseliner.TopicGrid( p );
    return [
        //{ xtype:'textarea', fieldLabel:'Data', value: Ext.encode( data ), anchor:'100%' },
        //{ xtype:'textarea', fieldLabel:'Meta', value: Ext.encode( meta ), anchor:'100%' }
        grid
    ]
})

