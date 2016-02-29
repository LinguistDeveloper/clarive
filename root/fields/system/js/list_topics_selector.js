/*
name: Filtered by selector Topics
params:
    html: '/fields/system/html/field_topics.html'
    js: '/fields/system/js/list_topics_selector.js'
    relation: 'system'
    type: 'listbox'    
    get_method: 'get_topics'    
    set_method: 'set_topics'
    field_order: 14
    section: 'details'
    page_size: 20
    filter: 'none'
    single_mode: 'false'    
    meta_type: 'topic'
    rel_type: 'topic_topic'
    parent_field: ''
    filter_field: ''
    filter_data: ''
---
*/

(function(params){
    var meta = params.topic_meta;
    var data = params.topic_data;
    var form = params.form.getForm();
    // console.log(data);

    var topics = new Array();
    var ps = parseInt(meta.page_size) || 10;  // for combos, 10 is a much nicer on a combo
    var id_required = Ext.id()
    //var lbl_required = 'lbl_' + meta.id_field + '_' + id
    
    if(data && data[ meta.bd_field] ){
        var eval_topics = data[ meta.bd_field ];
        for(i=0; i<eval_topics.length;i++){
            topics.push(eval_topics[i].mid);
        }
    }else{
        topics = [];
    }
    var single_mode = Baseliner.eval_boolean(meta.single_mode) || (!meta.single_mode && meta.list_type && meta.list_type != 'single') ? false : true;
    var display_field = meta.display_field || undefined;
    var tpl_cfg = meta.tpl_cfg || undefined;
    if (meta.dir == 'ASC') 
        {order_sort =1} 
    else {order_sort = -1}
    var topic_box;
    var topic_box_store = new Baseliner.store.Topics({
        baseParams: { 
            limit: ps,
            topic_child_data: true, 
            mid: data ? data.topic_mid : '', 
            show_release: 0, 
            filter: meta.filter ? meta.filter : '',
            sort_field: meta.sort,
            dir: order_sort,
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
        
        var readonly = meta && meta.readonly ? meta.readonly : false,
        
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
            enableDragDrop:  meta && meta.readonly ? !meta.readonly : true,
            readOnly:  readonly,
            hidden: Baseliner.eval_boolean(meta.hidden),
            allowBlank: readonly ? true : meta.allowBlank == undefined ? true : ( meta.allowBlank == 'false' || !meta.allowBlank ? false : true )
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
            hidden: Baseliner.eval_boolean(meta.hidden),
            display_field: display_field,
            tpl_cfg: tpl_cfg
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
//  if (meta.list_type == 'grid') {
//        var allow;
//        allow = meta.allowBlank == undefined ? true : ( meta.allowBlank == 'false' || !meta.allowBlank ? false : true );
//        // alert(meta.name_field + " " + allow);
//      obj.push(Baseliner.field_label_top( _(meta.name_field), meta.hidden, allow, meta.readonly ))    ;
//  }
    obj.push(topic_box);
    
    params.form.on('afterrender', function(){
        var filter_field = form.findField( meta.filter_field );
        if ( filter_field ) {
            function generate_txt (mids){
                var meta_filter = meta.filter;
                var txt_filter;
                if ( meta.filter != 'none' && meta_filter.length>0 ) {
                   meta_filter = "," + meta_filter.replace("{","");
                } else {
                  meta_filter = "}";
                }
                if (meta.filter_data) { 
                    txt_filter = '{ "'+ meta.filter_data +'":["' + mids + '"]' + meta_filter;
                } else {
                    txt_filter = '{ "'+ filter_field.name +'":["' + mids + '"]' + meta_filter;
                };
                topic_box_store.baseParams['filter'] = txt_filter;
                if( meta.list_type == 'grid' ) {
                    topic_box.removeAll();
                }
            };

            function extract_mids (field){
                var mids = "";
                var value;

                if (filter_field.items) {
                    value = filter_field.items.items;
                } else {
                    value = [filter_field];
                }
                value.forEach(function(val){
                    mids += val.value + ",";
                });
                mids = mids.substr(0, mids.length-1);
                return mids;
            };

            if(filter_field.store){
                filter_field.store.on('load',function(res, records, options){
                    var mids = extract_mids(res);
                    generate_txt(mids);
                });
            }
            filter_field.on('change',function (res) {
                var mids = extract_mids(res);
                generate_txt(mids);
                topic_box_store.load();
            });
            filter_field.on('removeItem',function (res) {
                var mids = extract_mids(res);
                generate_txt(mids);
                topic_box_store.load();
            });
        }
    });
    return obj
})
