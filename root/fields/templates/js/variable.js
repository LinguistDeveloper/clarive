/*
name: Variable
params:
    origin: 'template'
    type: 'variable'
    html: '/fields/templates/html/row_body.html'
    js: '/fields/templates/js/variable.js'
    field_order: 3
    allowBlank: 0
    section: 'body'
*/

(function(params){
    var meta = params.topic_meta;
    var data = params.topic_data;

    var id_field = meta.id_field;
    var from_data = meta.from ? '_' + meta.from : '';

    var store_vars = new Baseliner.store.CI({ baseParams: { role:'Variable', with_data: 1, order_by:'name' } });
    var field = {};

    var pn = new Ext.Container({ 
        layout:'form',
        frame: false,
        border: false,
        labelAlign: 'top'
    });

    store_vars.on("load", function() {
        var rowIndex, sel;                                        
        rowIndex = store_vars.find('name', id_field);
        sel = store_vars.getAt(rowIndex);
        if(sel){
            var d = Ext.apply({}, sel.data);
            d = Ext.apply(d, sel.data.data );

            var data_var;
            if( meta.scope && meta.scope == 'project'){
                if(data._catalog_stash){
                    if( data._catalog_stash.variables && data._catalog_stash.variables[id_field] && data._catalog_stash.variables[id_field].split ){
                        data_var = data._catalog_stash.variables[id_field].split(",");
                    }else{
                        data_var = data._catalog_stash.variables[id_field];
                    }


                    if (d.var_type != 'ci'){
                        if ( data.variables_output && data.ci_task_variables_output['*'] && data.ci_task_variables_output['*'][id_field + '_action'] && data.ci_task_variables_output['*'][id_field + '_action'] == 'modify') {
                            data[meta.id_field + from_data] = data[meta.id_field + from_data] || data_var;
                        }else{
                            d.var_combo_options = [];
                            
                            if (data_var.length > 0){
                                for(var i=0; i< data_var.length;i++){
                                    d.var_combo_options.push(data_var[i]);       
                                }                    
                            }else{
                                d.var_combo_options.push(data._catalog_stash.variables[id_field]);     
                            }

                            function onlyUnique(value, index, self) { 
                                return self.indexOf(value) === index;
                            }

                            var new_values = data[meta.id_field];
                            var all_options = d.var_combo_options.concat(new_values);
                            var unique = all_options.filter( onlyUnique ); 
                            d.var_combo_options = unique;

                            d.var_type = 'superbox';
                            d.var_ci_mandatory = meta.allowBlank && meta.allowBlank == 'false' ? 1 : 0;  
                            d.var_ci_multiple = meta.single_mode && meta.single_mode == 'false' ? 1 : 0; 
                        }
                    }
                }else{
                    if ( data.variables_output && data.variables_output['*'] && data.variables_output['*'][id_field + '_action'] && data.variables_output['*'][id_field + '_action'] == 'modify') {
                        data[meta.id_field + from_data] = data[meta.id_field + from_data] || data_var;    
                    }else{
                        if (d.var_type != 'ci'){
                            d.var_ci_mandatory = 0;
                            var hash_options = {};
                            if (data[id_field + '_options'].constructor === Array){
                                for(var i=0; i< data[id_field + '_options'].length;i++){
                                    d.var_combo_options.push(data[id_field + '_options'][i]);
                                    hash_options[data[id_field + '_options'][i]] = 1;
                                }   
                            }else{
                                d.var_combo_options.push(data[id_field + '_options']);
                                hash_options[data[id_field + '_options']] = 1;
                            }

                            if (data[ meta.id_field + from_data]) {
                                if (data[meta.id_field + from_data].constructor === Array){
                                    for (var i=0; i<data[meta.id_field + from_data].length;i++){
                                        if( hash_options[data[meta.id_field + from_data][i]] ){
                                            continue;
                                        }else{
                                            d.var_combo_options.push(data[meta.id_field + from_data][i]); 
                                        }
                                    }
                                }else{
                                    if( !hash_options[data[meta.id_field + from_data]] ){  
                                        d.var_combo_options.push(data[meta.id_field + from_data]);     
                                    }  
                                }
                            }
                            
                            d.var_type = 'superbox';
                            d.var_ci_mandatory = meta.allowBlank && meta.allowBlank == 'false' ? 1 : 0;  
                            d.var_ci_multiple = meta.single_mode && meta.single_mode == 'false' ? 1 : 0; 
                        }
                        else{
                            data_var = data[id_field + from_data] && data[id_field + from_data].length ? data[id_field + from_data].join() : undefined;
                        }
                    }
                }
            }else{
                data_var = data[id_field] && data[id_field].length ? data[id_field].join() : undefined;
            }

            var variable_meta = Baseliner.build_var_to_meta( d );
            variable_meta.label = meta.name_field; 
            variable_meta.data = {};

            if( data[meta.id_field + from_data]){
                variable_meta.data = data._catalog_stash ? data[ meta.id_field + from_data] : data[ meta.id_field + from_data] ? data[ meta.id_field + from_data ] : undefined;                
            }else{
                variable_meta.data = data._catalog_stash ? data[ meta.id_field ] : data[ meta.id_field ] ? data[ meta.id_field ] : undefined;    
            }

            // if (d.var_type == 'ci'){
            //     variable_meta.mids = data_var;
            // }

            variable_meta.id += meta.from ? '_' + meta.from : '';

            field = Baseliner.build_to_field(variable_meta);
            field._no_event_field_changed = true;
            field.submitValue = true;
            pn.add(field);
            pn.doLayout();

        }
    });

    return pn;
})

