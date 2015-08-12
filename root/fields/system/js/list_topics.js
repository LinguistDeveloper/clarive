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
    meta_type: 'topic'
    rel_type: 'topic_topic'
    parent_field: ''
    copy_fields: ''
    copy_fields_exclude: ''
    copy_fields_rename: ''
    tpl_cfg: ''
---
*/

(function(params){
	var meta = params.topic_meta;
	var data = params.topic_data;
	var form = params.form.getForm();
	
	var topics = new Array();
    var ps = parseInt(meta.page_size) || 10;  // for combos, 10 is a much nicer on a combo
	var id_required = Ext.id()
	//var lbl_required = 'lbl_' + meta.id_field + '_' + id
	
	if(data && data[ meta.id_field] ){
		var eval_topics = data[ meta.id_field ];
		for(i=0; i<eval_topics.length;i++){
			topics.push(eval_topics[i].mid);
		}
	}else{
		topics = [];
	}
	
    var single_mode = meta.single_mode == 'false' || (!meta.single_mode && meta.list_type && meta.list_type != 'single') ? false : true;
    var display_field = meta.display_field==undefined ? 'title' : meta.display_field;
    var tpl_cfg = meta.tpl_cfg || undefined;

    var topic_box;
    var topic_box_store = new Baseliner.store.Topics({
        baseParams: { 
            limit: ps,
            topic_child_data: true, 
            mid: data ? data.topic_mid : '', 
            show_release: 0, 
            filter: meta.filter ? meta.filter : ''
        },
        display_field: display_field,
        tpl_cfg: tpl_cfg
    });

    if( meta.list_type == 'grid' ) {
        // Grid
		
        var sm = new Baseliner.CheckboxSelectionModel({
            checkOnly: true,
            singleSelect: false
        });
		
		var readonly = Baseliner.eval_boolean(meta.readonly),
		
        topic_box = new Baseliner.TopicGrid({
			fieldLabel: _(meta.name_field),
			sm: sm ,
            //fieldLabel:_( meta.name_field ), 
            combo_store: topic_box_store,
            columns: meta.columns,
            mode: 'remote',
            //style: 'margin-bottom: 8px',
            pageSize: ps,
            name: meta.id_field,
            height: meta.height || 250,
            value: data[ meta.id_field ],
			enableDragDrop:  Baseliner.eval_boolean(meta.readonly),
			readOnly:  readonly,
			hidden: Baseliner.eval_boolean(meta.hidden),
			allowBlank: readonly ? true : Baseliner.eval_boolean(meta.allowBlank, true)
        });
		

    } else {
        topic_box = new Baseliner.TopicBox({
            fieldLabel: _(meta.name_field),
            pageSize: ps,
            name: meta.id_field,
            hiddenName: meta.id_field,          
            emptyText: _( meta.emptyText ),
            allowBlank: meta.allowBlank == undefined ? true : ( meta.allowBlank == 'false' || !meta.allowBlank ? false : true ),          
            store: topic_box_store,
            disabled: meta ? meta.readonly : true,
            value: topics,
            singleMode: single_mode,
			hidden: meta ? (meta.hidden ? meta.hidden : false): true,
            display_field: display_field,
            tpl_cfg: tpl_cfg
        });
        
        if( meta.copy_fields && meta.copy_fields != 'none' ) {
            topic_box.on( 'additem', function(sb,val,rec){

                if( topic_box.getValue() == topics ) return;
                var rec_data = rec.json;
                if( !rec_data ) return;
                var new_line = '\n - ';
                // copy fields?
                //    [["description","descripcion"], ["precondiciones", "precondiciones" ], ["pasos", "pasos"] ]
                var non_replace = ["moniker","ts","topic","txtcategory_old","versionid","m","ns","bl","priority","color_category","cancelEvent","_id","form","category_name","category_status_id","deadline_min","created_on","modified_by","category","id_category","category_status_name","category_status_seq","topic_post","name","response_time_min","id_category_status","active","username","is_release","is_changeset","created_by","short_name","status","name_category","topic_mid","category_color","mid","_cis","color","category_id","_project_security","name_status","id_priority","txt_rsptime_expr_min","progress","_sort","category_status","expr_deadline","category_status_type","modified_on","status_new","txt_deadline_expr_min"];

                // copy_fields_exclude: [ "title", "field_x"]
                if ( meta.copy_fields_exclude ) {
                    var new_fields;
                    if( Ext.isString(meta.copy_fields_exclude) ) {
                        new_fields = Ext.decode( meta.copy_fields_exclude );
                    } else if ( Ext.isArray( meta.copy_fields_exclude ) ) {
                        new_fields = meta.copy_fields_exclude;
                    }
                    Ext.each( new_fields, function(field){
                        non_replace.push(field);
                    });
                }

                // copy_fields_rename: { "template_title": "title", "field_orig": "field_target" }
                var renamed_fields = {};
                if ( meta.copy_fields_rename ) {
                    if( Ext.isString(meta.copy_fields_rename) ) {
                        renamed_fields = Ext.decode( meta.copy_fields_rename );
                    } else if ( Ext.isArray( meta.copy_fields_rename ) ) {
                        renamed_fields = meta.copy_fields_rename;
                    }
                }
                if ( meta.copy_fields != 'all' ) {
                    var ct;
                    if( Ext.isString(meta.copy_fields) ) {
                        ct = Ext.decode( meta.copy_fields );
                    } else if ( Ext.isArray( meta.copy_fields ) ) {
                        ct = meta.copy_fields;
                    }
                    var replacing_fields = [];
                    Ext.each( ct, function(frel){
                        if (non_replace.indexOf(frel[0]) != -1) return;
                        replacing_fields.push(frel[0]);
                    });
                    if (confirm( _('You are about to replace the contents of the following fields: \n - %1\n\nAre you sure?',replacing_fields.join(new_line),'\n' ) )) {
                        Ext.each( ct, function(frel){
                            if (non_replace.indexOf(frel[0]) != -1) return;
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
                    };

                } else {
                    var replacing_fields = [];
                    var replacing_fields_target = [];

                    Ext.each( Object.keys(rec_data), function(frel){
                        if (non_replace.indexOf(frel) != -1) return;
                        replacing_fields.push(frel);
                        if ( renamed_fields[frel] ) {
                            replacing_fields_target.push(renamed_fields[frel]);
                        } else {
                            replacing_fields_target.push(frel);
                        }
                    });

                    if (confirm( _('You are about to replace the contents of the following fields: \n - %1\n\nAre you sure?',replacing_fields_target.join(new_line),'\n' ) )) {
                        Ext.each( replacing_fields, function(frel){
                            if (non_replace.indexOf(frel) != -1) return;
                            var from_field = frel;
                            var to_field = renamed_fields[frel] || from_field;
                            var fdata = rec_data[ from_field ];
                            if( fdata == undefined ) return;
                            var ff = $(form.el.dom).find('[name="'+to_field+'"]');
                            ff = Ext.getCmp( ff.attr('id') );

                            if( ff ) ff.setValue( fdata );
                        });
                    };
                }
            });
        }
    }
	var obj = [];
	obj.push(topic_box);	
	
	return obj
})
