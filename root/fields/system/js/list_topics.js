/*
name: Topics
params:
    html: '/fields/system/html/field_topics.html'
    js: '/fields/system/js/list_topics.js'
    relation: 'system'
    type: 'listbox'    
    get_method: 'get_topics'    
    set_method: 'set_topics'
    field_order: 14
    section: 'details'
    page_size: 20
    filter: 'none'
    single_mode: 'false'    
---
*/

(function(params){
	var meta = params.topic_meta;
	var data = params.topic_data;
	var form = params.form.getForm();
	
	var topics = new Array();
    var ps = meta.page_size || 10;  // for combos, 10 is a much nicer on a combo
	
	if(data && data[ meta.bd_field] ){
		var eval_topics = data[ meta.bd_field ];
		for(i=0; i<eval_topics.length;i++){
			topics.push(eval_topics[i].mid);
		}
	}else{
		topics = [];
	}
	
    var topic_box;
    var topic_box_store = new Baseliner.store.Topics({
        baseParams: { 
            limit: ps,
            topic_child_data: true, 
            mid: data ? data.topic_mid : '', 
            show_release: 0, 
            filter: meta.filter ? meta.filter : ''
        } 
    });
    if( meta.list_type == 'grid' ) {
        // Grid
		
        var sm = new Baseliner.CheckboxSelectionModel({
            checkOnly: true,
            singleSelect: false
        });
		
        topic_box = new Baseliner.TopicGrid({
			sm: sm ,
            //fieldLabel:_( meta.name_field ), 
            combo_store: topic_box_store,
            columns: meta.columns,
            mode: 'remote',
            pageSize: ps,
            name: meta.id_field, 
            height: meta.height || 250,
            value: data[ meta.id_field ],
			enableDragDrop:  meta && meta.readonly ? !meta.readonly : true,
			readOnly:  meta && meta.readonly ? meta.readonly : false,
			hidden: meta ? (meta.hidden ? meta.hidden : false): true
        });

    } else {
        var topic_box = new Baseliner.TopicBox({
            fieldLabel: _(meta.name_field),
            pageSize: ps,
            name: meta.id_field,
            hiddenName: meta.id_field,          
            emptyText: _( meta.emptyText ),
            allowBlank: meta.allowBlank == undefined ? true : ( meta.allowBlank == 'false' || !meta.allowBlank ? false : true ),          
            store: topic_box_store,
            disabled: meta ? meta.readonly : true,
            value: topics,
            singleMode: meta.single_mode == 'false' || !meta.single_mode ? false : true,
			hidden: meta ? (meta.hidden ? meta.hidden : false): true
        });
        
        if( meta.copy_fields ) {
            topic_box.on( 'additem', function(sb,val,rec){
                if( topic_box.getValue() == topics ) return;
                var rec_data = rec.json.data;
                if( !rec_data ) return;

                // copy fields?
                //    [["description","descripcion"], ["precondiciones", "precondiciones" ], ["pasos", "pasos"] ]
                var ct;
                if( Ext.isString(meta.copy_fields) ) {
                    ct = Ext.decode( meta.copy_fields );
                } else if ( Ext.isArray( meta.copy_fields ) ) {
                    ct = meta.copy_fields;
                }
                Ext.each( ct, function(frel){
                    var from_field = frel[0];
                    var to_field = frel[1] || from_field;
                    var fdata = rec_data[ from_field ];
                    //console.log( [from_field,to_field,fdata].join('\n') );
                    if( fdata == undefined ) return;
                    var ff = $(form.el.dom).find('[name="'+to_field+'"]');
                    ff = Ext.getCmp( ff.attr('id') );

                    //var ff = form.findField( to_field ); // this wont find fields within tbar
                    if( ff ) ff.setValue( fdata );
                    //if( ff ) ff.val( fdata ); // this does not fire the setValue()
                });
            });
        }
    }
	var obj = [];
	if (meta.list_type == 'grid') {
		obj.push(Baseliner.field_label_top( _(meta.name_field), meta.hidden, meta.allowBlank ))	;
	}
	obj.push(topic_box);
	
	return obj
})
