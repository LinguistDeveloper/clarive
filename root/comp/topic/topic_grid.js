<%perl>
    use Baseliner::Utils;
    my $id = _nowstamp;
</%perl>
(function(){
    <& /comp/search_field.mas &>
    var ps = 30; //page_size
    var filter_current;

    // Create store instances
    var store_category = new Baseliner.Topic.StoreCategory();
    var store_label = new Baseliner.Topic.StoreLabel();
    var store_topics = new Baseliner.Topic.StoreList({
		listeners: {
			'beforeload': function( obj, opt ) {
				if( opt !== undefined && opt.params !== undefined )
					filter_current = Baseliner.merge( filter_current, opt.params );
			}
		}
    });
   
    var init_buttons = function(action) {
        eval('btn_edit.' + action + '()');
        eval('btn_delete.' + action + '()');
    }
    
    var button_create_view = new Ext.Button({
        icon:'/static/images/icons/add.gif',
		tooltip: _('Create view'),
        cls: 'x-btn-icon',
		disabled: false,
        handler: function(){
			add_view();
        }
    });
	
	
	
	var button_delete_view = new Baseliner.Grid.Buttons.Delete({
		tooltip: _('Delete view'),
        cls: 'x-btn-icon',
		disabled: true,
        handler: function() {
            Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the views selected?'), 
				function(btn){ 
					if(btn=='yes') {
						var views_delete = new Array();
						selNodes = tree_filters.getChecked();
						Ext.each(selNodes, function(node){
							var type = node.parentNode.attributes.id;
							if(type !== 'V'){
								return false;
							}else{
								if(!node.attributes.default){
									views_delete.push(node.attributes.idfilter);
									node.remove();
								}
							}
						});

						Baseliner.ajaxEval( '/topic/view_filter?action=delete',{ ids_view: views_delete },
							function(response) {
								if ( response.success ) {
									Baseliner.message( _('Success'), response.msg );
									//tree_filters.getLoader().load(tree_root);
									loadfilters();
									button_delete_view.disable();
								} else {
									Baseliner.message( _('ERROR'), response.msg );
								}
							}
						);
					}
				}
			);
        }
	});	
	
	
	var add_view = function() {
		var win;
		
		var title = 'Create view';
		
		var form_view = new Ext.FormPanel({
			frame: true,
			url: '/topic/view_filter',
			buttons: [
				{
					text: _('Accept'),
					type: 'submit',
					handler: function() {
						var form = form_view.getForm();
						if (form.isValid()) {
							form.submit({
								params: {action: 'add', filter: Ext.util.JSON.encode( filter_current )},
								success: function(f,a){
									Baseliner.message(_('Success'), a.result.msg );
									var parent_node = tree_filters.getNodeById('V');
									var ff;
									ff = form_view.getForm();
									var name = ff.findField("name").getValue();
									parent_node.appendChild({id:a.result.data.id, idfilter: a.result.data.idfilter, text:name, filter:  Ext.util.JSON.encode( filter_current ), default: false, cls: 'forum', iconCls: 'icon-no', checked: false, leaf: true});
									win.close();
								},
								failure: function(f,a){
									Ext.Msg.show({  
									title: _('Information'), 
									msg: a.result.msg , 
									buttons: Ext.Msg.OK, 
									icon: Ext.Msg.INFO
									});                      
								}
						   });
						}					
					}
				},
				{
				text: _('Close'),
				handler: function(){ 
						win.close();
					}
				}
			],
			defaults: { width: 400 },
			items: [
			    {
					xtype:'textfield',
					fieldLabel: _('Name view'),
					name: 'name',
					width: '100%',
					allowBlank: false
				}
			]
		});
		
		win = new Ext.Window({
			title: _(title),
			width: 550,
			autoHeight: true,
			items: form_view
		});
		win.show();		
	};
	
	var btn_add = new Baseliner.Grid.Buttons.Add({
		handler: function() {
			add_topic();
	    }		
	});
	
	var add_topic = function() {
		var win;
		
		var combo_category = new Ext.form.ComboBox({
			mode: 'local',
            editable: false,
            autoSelect: true,
            selectOnFocus: true,
			forceSelection: true,
			emptyText: 'select a category',
			triggerAction: 'all',
			fieldLabel: _('Category'),
			name: 'category',
			hiddenName: 'category',
			displayField: 'name',
			valueField: 'id',
			store: store_category,
            tpl: '<tpl for="."><div id="boot" class="x-combo-list-item"><span class="badge" style="float:left;padding:2px 8px 2px 8px;background: {color}">{name}</span></div></tpl>', 
			allowBlank: false
		});

        var combo_select = function() {
            var title = combo_category.getRawValue();
            Baseliner.add_tabcomp('/topic/view?swEdit=1', title , { title: title, new_category_id: combo_category.getValue(), new_category_name: combo_category.getRawValue() } );
            win.close();
        };
        combo_category.on('select', combo_select );

		var title = 'Create topic';
		
		var form_topic = new Ext.FormPanel({
			frame: true,
			buttons: [
				{
				text: _('Accept'),
				type: 'submit',
				handler: function() {
                    var form = form_topic.getForm();
                    if (form.isValid()) { combo_select() }
				}
				},
				{
				text: _('Close'),
				handler: function(){ 
						win.close();
					}
				}
			],
			defaults: { width: 400 },
			items: [
				combo_category
			]
		});

		store_category.load();
        store_category.on( 'load', function(){ combo_category.setValue( store_category.getAt(0).id );  });
		
		win = new Ext.Window({
			title: _(title),
			width: 550,
			autoHeight: true,
            closeAction: 'close',
            modal: true,
			items: form_topic
		});
		win.show();		
	};
	
	
	var btn_edit = new Baseliner.Grid.Buttons.Edit({
		handler: function() {
			var sm = grid_topics.getSelectionModel();
				if (sm.hasSelection()) {
					var r = sm.getSelected();
					var topic_mid = r.get('topic_mid');
					var title = _(r.get( 'category_name' )) + ' #' + topic_mid;
					
					Baseliner.add_tabcomp('/topic/view?topic_mid=' + topic_mid + '&swEdit=1', title , { topic_mid: topic_mid, title: title } );
					
				} else {
					Baseliner.message( _('ERROR'), _('Select at least one row'));    
				};
        }
	});
	
	var btn_delete = new Baseliner.Grid.Buttons.Delete({
        handler: function() {
            var sm = grid_topics.getSelectionModel();
            var sel = sm.getSelected();
			var topico = sel.data.category_name + ' ' + sel.data.topic_mid;
            Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the topic') + ' <b>' + topico + '</b>?', 
				function(btn){ 
					if(btn=='yes') {
						Baseliner.ajaxEval( '/topic/update?action=delete',{ topic_mid: sel.data.topic_mid },
							function(response) {
								if ( response.success ) {
									grid_topics.getStore().remove(sel);
									Baseliner.message( _('Success'), response.msg );
									init_buttons('disable');
								} else {
									Baseliner.message( _('ERROR'), response.msg );
								}
							}
						
						);
					}
				}
			);
        }
	});
	
	var btn_comprimir = new Ext.Toolbar.Button({
        icon:'/static/images/icons/updown_.gif',
        cls: 'x-btn-text-icon',
        enableToggle: true, pressed: false, allowDepress: true,
        handler: function() {
			store_topics.reload();
        }		
    }); 
    
	
	//var btn_labels = new Ext.Toolbar.Button({
    //    text: _('Labels'),
    //    icon:'/static/images/icons/color_swatch.png',
    //    cls: 'x-btn-text-icon',
    //    disabled: true,
    //    handler: function() {
    //        var sm = grid_topics.getSelectionModel();
    //        if (sm.hasSelection()) {
    //            var sel = sm.getSelected();
    //            add_labels(sel);
    //        }
    //    }
    //}); 
    

    //var btn_close = new Ext.Toolbar.Button({
    //    text: _('Close'),
    //    icon:'/static/images/icons/cerrar.png',
    //    cls: 'x-btn-text-icon',
    //    disabled: true,
    //    handler: function() {
    //        var sm = grid_topics.getSelectionModel();
    //        var sel = sm.getSelected();
    //        Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to close the topic') + ' <b># ' + sel.data.topic_mid + '</b>?', 
    //        function(btn){ 
    //            if(btn=='yes') {
    //                Baseliner.ajaxEval( '/topic/update?action=close',{ id: sel.data.topic_mid },
    //                    function(response) {
    //                        if ( response.success ) {
    //                            grid_topics.getStore().remove(sel);
    //                            Baseliner.message( _('Success'), response.msg );
    //                            init_buttons('disable');
    //                        } else {
    //                            Baseliner.message( _('ERROR'), response.msg );
    //                        }
    //                    }
    //                
    //                );
    //            }
    //        } );
    //    }
    //});

//    var add_labels = function(rec) {
//        var win;
//        var title = 'Labels';
//		
//        var btn_cerrar_labels = new Ext.Toolbar.Button({
////            icon:'/static/images/icons/door_out.png',
//            cls: 'x-btn-text-icon',
//            text: _('Close'),
//            handler: function() {
//                win.close();
//            }
//        });
//        
//        var btn_grabar_labels = new Ext.Toolbar.Button({
//            icon:'/static/images/icons/database_save.png',
//            cls: 'x-btn-text-icon',
//            text: _('Save'),
//            handler: function(){
//                var labels_checked = new Array();
//                check_ast_labels_sm.each(function(rec){
//                    labels_checked.push(rec.get('id'));
//                });
//                Baseliner.ajaxEval( '/topic/update_topic_labels',{ topic_mid: rec.data.topic_mid, label_ids: labels_checked },
//                    function(response) {
//                        if ( response.success ) {
//                            Baseliner.message( _('Success'), response.msg );
//							loadfilters();
//                        } else {
//                            Baseliner.message( _('ERROR'), response.msg );
//                        }
//                    }
//                );
//            }
//        });
//
//        var check_ast_labels_sm = new Ext.grid.CheckboxSelectionModel({
//            singleSelect: false,
//            sortable: false,
//            checkOnly: true
//        });
//    
//        
//        var grid_ast_labels = new Ext.grid.GridPanel({
//            title : _('Labels'),
//            sm: check_ast_labels_sm,
//            autoScroll: true,
//            header: false,
//            stripeRows: true,
//            autoScroll: true,
//            height: 300,
//            enableHdMenu: false,
//            store: store_label,
//            viewConfig: {forceFit: true},
//            selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
//            loadMask:'true',
//            columns: [
//                { hidden: true, dataIndex:'id' },
//                check_ast_labels_sm,
//                { header: _('Color'), dataIndex: 'color', width:15, sortable: false, renderer: render_color },
//                { header: _('Label'), dataIndex: 'name', sortable: false }
//            ],
//            autoSizeColumns: true,
//            deferredRender:false,
//            bbar: [
//                btn_grabar_labels,
//                btn_cerrar_labels
//            ],
//            listeners: {
//                viewready: function() {
//                    var me = this;
//                    var datas = me.getStore();
//                    var recs = [];
//                    datas.each(function(row, index){
//                        if(rec.data.labels){
//                            for(i=0;i<rec.data.labels.length;i++){
//								var label = rec.data.labels[i].split(';');
//								var label_id = label[0];
//                                if(row.get('id') == label_id){
//                                    recs.push(index);   
//                                }
//                            }
//                        }                       
//                    });
//                    me.getSelectionModel().selectRows(recs);                    
//                
//                }
//            }       
//        });
//        
//        //Ext.util.Observable.capture(grid_ast_labels, console.info);
//    
//        win = new Ext.Window({
//            title: _(title),
//            width: 400,
//            modal: true,
//            autoHeight: true,
//            items: grid_ast_labels
//        });
//        
//        win.show();
//    };


    var render_id = function(value,metadata,rec,rowIndex,colIndex,store) {
        return "<div style='font-weight:bold; font-size: 14px; color: #808080'> #" + value + "</div>" ;
    };

    function returnOpposite(hexcolor) {
        var r = parseInt(hexcolor.substr(0,2),16);
        var g = parseInt(hexcolor.substr(2,2),16);
        var b = parseInt(hexcolor.substr(4,2),16);
        var yiq = ((r*299)+(g*587)+(b*114))/1000;
        return (yiq >= 128) ? '000000' : 'FFFFFF';
    }

    var render_title = function(value,metadata,rec,rowIndex,colIndex,store) {
        var tag_color_html;
		var date_created_on;
        tag_color_html = '';
		date_created_on =  rec.data.created_on.dateFormat('M j, Y, g:i a');
        var strike = ( rec.data.is_closed ? 'text-decoration: line-through' : '' );
		
        if(rec.data.labels){
            for(i=0;i<rec.data.labels.length;i++){
				var label = rec.data.labels[i].split(';');
				var label_name = label[1];
				var label_color = label[2];
				tag_color_html = tag_color_html + "<div id='boot'><span class='label' style='font-size: 9px; float:left;padding:1px 4px 1px 4px;margin-right:4px;color:#" + returnOpposite(label_color) + ";background-color:#" + label_color + "'>" + label_name + "</span></div>";				
            }
        }
		if(btn_comprimir.pressed){
			return tag_color_html + "<div style='font-weight:bold; font-size: 14px; "+strike+"' >" + value + "</div>";			
		}else{
			return tag_color_html + "<div style='font-weight:bold; font-size: 14px; "+strike+"' >" + value + "</div><br><div><b>" + date_created_on + "</b> <font color='808080'></br>by " + rec.data.created_by + "</font ></div>";						
		}
        
    };
	
    var render_title_comprimido = function(value,metadata,rec,rowIndex,colIndex,store) {
        var tag_color_html = '';
        var strike = ( rec.data.is_closed ? 'text-decoration: line-through' : '' );
		
        if(rec.data.labels){
            for(i=0;i<rec.data.labels.length;i++){
				var label = rec.data.labels[i].split(';');
				var label_name = label[1];
				var label_color = label[2];
				tag_color_html = tag_color_html + "<div id='boot'><span class='label' style='font-size: 9px; float:left;padding:1px 4px 1px 4px;margin-right:4px;color:#" + returnOpposite(label_color) + ";background-color:#" + label_color + "'>" + label_name + "</span></div>";				
            }
        }
        return tag_color_html + "<div style='font-weight:bold; font-size: 14px; "+strike+"' >" + value + "</div>";
    };	
    
    var render_comment = function(value,metadata,rec,rowIndex,colIndex,store) {
        var tag_comment_html;
        if(rec.data.numcomment){
            tag_comment_html = [
                "<span style='color: #808080'><img border=0 src='/static/images/icons/comment_blue.gif' /> ",
                rec.data.numcomment,
                "</span>",
                "<span style='color: #808080'><img border=0 src='/static/images/icons/comment_blue.gif' /> ",
                rec.data.numfile,
                "</span>"
            ].join("");
			//tag_comment_html = "<span style='color: #808080'><img border=0 src='/static/images/icons/comment_blue.gif' /></span>";
        } else {       
            tag_comment_html='';
        }
        return tag_comment_html;
    };
    
    var render_project = function(value,metadata,rec,rowIndex,colIndex,store){
		var tag_project_html = '';
        if(rec.data.projects){
            for(i=0;i<rec.data.projects.length;i++){
				var project = rec.data.projects[i].split(';');
				var project_name = project[1];				
                tag_project_html = tag_project_html ? tag_project_html + ',' + project_name: project_name;
            }
        }
        return tag_project_html;
    };

    var render_status = function(value,metadata,rec,rowIndex,colIndex,store){
        var ret = 
            '<small><b><span style="text-transform:uppercase;font-family:Helvetica Neue,Helvetica,Arial,sans-serif;color:#555">' + value + '</span></b></small>';
           //+ '<div id="boot"><span class="label" style="float:left;padding:2px 8px 2px 8px;background:#ddd;color:#222;font-weight:normal;text-transform:lowercase;text-shadow:none;"><small>' + value + '</small></span></div>'
        return ret;
    };

    var render_category = function(value,metadata,rec,rowIndex,colIndex,store){
        var id = rec.data.topic_mid; //Cambiarlo en un futuro por un contador de categorias
        var color = rec.data.category_color;
        var cls = rec.data.is_release ? 'label' : 'badge';
        //if( color == undefined ) color = '#777';
        var ret = '<div id="boot"><span class="'+cls+'" style="float:left;padding:2px 8px 2px 8px;background: '+ color + '">' + value + ' #' + id + '</span></div>';
        return ret;
    };

     var search_field = new Ext.app.SearchField({
                store: store_topics,
                params: {start: 0, limit: ps},
                emptyText: _('<Enter your search string>')
    });
 
    var grid_topics = new Ext.grid.GridPanel({
        title: _('Topics'),
        header: false,
        stripeRows: true,
        autoScroll: true,
        enableHdMenu: false,
        store: store_topics,
        enableDragDrop: true,
        ddGroup: 'lifecycle_dd',
        viewConfig: {forceFit: true},
        selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
        loadMask:'true',
        columns: [
            { header: _('Category'), dataIndex: 'category_name', width: 80, sortable: true, renderer: render_category },
            { header: _('Status'), dataIndex: 'category_status_name', width: 50, renderer: render_status },
            { header: _('Title'), dataIndex: 'title', width: 250, sortable: true, renderer: render_title},
            { header: '', dataIndex: 'numcomment', width: 10, renderer: render_comment },			
            { header: _('Projects'), dataIndex: 'projects', width: 60, renderer: render_project },
            { header: _('Topic'), hidden: true, dataIndex: 'topic_mid'},    
        ],
        tbar:   [ _('Search') + ' ', ' ',
                search_field,
                btn_add,
                btn_edit,
                btn_delete,
                //btn_labels
                '->',
                btn_comprimir
                //btn_close
        ], 		
        autoSizeColumns: true,
        deferredRender:true,
        bbar: new Ext.PagingToolbar({
            store: store_topics,
            pageSize: ps,
            displayInfo: true,
            displayMsg: _('Rows {0} - {1} of {2}'),
            emptyMsg: _('There are no rows available')
        })
    });
    
    grid_topics.on('rowclick', function(grid, rowIndex, columnIndex, e) {
        init_buttons('enable');
    });

    grid_topics.on("rowdblclick", function(grid, rowIndex, e ) {
        var r = grid.getStore().getAt(rowIndex);
        var title = _(r.get( 'category_name' )) + ' #' + r.get('topic_mid');
        Baseliner.add_tabcomp('/topic/view?topic_mid=' + r.get('topic_mid') , title , { topic_mid: r.get('topic_mid'), title: title, _parent_grid: grid } );
    });
    
    grid_topics.on( 'render', function(){
        var el = grid_topics.getView().el.dom.childNodes[0].childNodes[1];
        var grid_topics_dt = new Ext.dd.DropTarget(el, {
            ddGroup: 'lifecycle_dd',
            copy: true,
            notifyDrop: function(dd, e, id) {
                var n = dd.dragData.node;
                var s = grid_topics.store;
                var add_node = function(node) {
                    var data = node.attributes.data;
                    // determine the row
                    var t = Ext.lib.Event.getTarget(e);
                    var rindex = grid_topics.getView().findRowIndex(t);
                    if (rindex === false ) return false;
                    var row = s.getAt( rindex );
                    var swSave = true;
                    var projects = row.get('projects');
                    if( typeof projects != 'object' ) projects = new Array();
                    for (i=0;i<projects.length;i++) {
						var project = projects[i].split(';');
						var project_name = project[1];
                        if(project_name == data.project){
                            swSave = false;
                            break;
                        }
                    }

                    //if( projects.name.indexOf( data.project ) == -1 ) {
                    if( swSave ) {
                        row.beginEdit();
						
                        projects.push( data.id_project + ';' + data.project );
                        row.set('projects', projects );
                        row.endEdit();
                        row.commit();
                        
                        Baseliner.ajaxEval( '/topic/update_project',{ id_project: data.id_project, topic_mid: row.get('topic_mid') },
                            function(response) {
                                if ( response.success ) {
                                    //store_label.load();
                                    Baseliner.message( _('Success'), response.msg );
                                    //init_buttons('disable');
                                } else {
                                    //Baseliner.message( _('ERROR'), response.msg );
                                    Ext.Msg.show({
                                        title: _('Information'), 
                                        msg: response.msg , 
                                        buttons: Ext.Msg.OK, 
                                        icon: Ext.Msg.INFO
                                    });
                                }
                            }
                        
                        );
                    } else {
                        Baseliner.message( _('Warning'), _('Project %1 is already assigned', data.project));
                    }
                    
                };
				
                var add_label = function(node) {
                    var text = node.attributes.text;
                    // determine the row
                    var t = Ext.lib.Event.getTarget(e);
                    var rindex = grid_topics.getView().findRowIndex(t);
                    if (rindex === false ) return false;
                    var row = s.getAt( rindex );
                    var swSave = true;
                    var labels = row.get('labels');
                    if( typeof labels != 'object' ) labels = new Array();
                    for (i=0;i<labels.length;i++) {
						var label = labels[i].split(';');
						var label_name = label[1];
                        if(label_name == text){
                            swSave = false;
                            break;
                        }
                    }

                    //if( projects.name.indexOf( data.project ) == -1 ) {
                    if( swSave ) {
                        row.beginEdit();
						
                        labels.push( node.attributes.idfilter + ';' + text + ';' + node.attributes.color );
                        row.set('labels', labels );
                        row.endEdit();
                        row.commit();
                        
						var label_ids = new Array();
						for(i=0;i<labels.length;i++){
							var label = labels[i].split(';');
							label_ids.push(label[0]);
						}
						Baseliner.ajaxEval( '/topic/update_topic_labels',{ topic_mid: row.get('topic_mid'), label_ids: label_ids },
                            function(response) {
                                if ( response.success ) {
                                    //store_label.load();
                                    Baseliner.message( _('Success'), response.msg );
                                    //init_buttons('disable');
                                } else {
                                    //Baseliner.message( _('ERROR'), response.msg );
                                    Ext.Msg.show({
                                        title: _('Information'), 
                                        msg: response.msg , 
                                        buttons: Ext.Msg.OK, 
                                        icon: Ext.Msg.INFO
                                    });
                                }
                            }
                        
                        );
                    } else {
                        Baseliner.message( _('Warning'), _('Label %1 is already assigned', text));
                    }
                    
                };				
				
				
                var attr = n.attributes;
				if(attr.data){
					if( typeof attr.data.id_project == 'undefined' ) {  // is a project?
						//Baseliner.message( _('Error'), _('Node is not a project'));
					} else {
						add_node(n);
					}
				}
				else{
					if(n.parentNode.attributes.id == 'L'){
						add_label(n);
					}else{
						//Baseliner.message( _('Error'), _('Node is not a label'));
					}
					
				}
                // multiple? Ext.each(dd.dragData.selections, add_node );
                return (true); 
             }
        });
		
    }); 

   
    var render_color = function(value,metadata,rec,rowIndex,colIndex,store) {
        return "<div width='15' style='border:1px solid #cccccc;background-color:" + value + "'>&nbsp;</div>" ;
    };  

    function loadfilters(){
		var labels_checked = new Array();
		var statuses_checked = new Array();
		var categories_checked = new Array();
		var priorities_checked = new Array();
		var type;
		var merge_filters = {};
		selNodes = tree_filters.getChecked();
		Ext.each(selNodes, function(node){
			type = node.parentNode.attributes.id;
			switch (type){
				//Views
				case 'V':	merge_filters = Baseliner.merge(merge_filters, Ext.util.JSON.decode(node.attributes.filter));
							break;
				//Labels
				case 'L':  	labels_checked.push(node.attributes.idfilter);
							break;
				//Statuses
				case 'S':   statuses_checked.push(node.attributes.idfilter);
							break;
				//Categories
				case 'C':   categories_checked.push(node.attributes.idfilter);
							break;
				//Priorities
				case 'P':   priorities_checked.push(node.attributes.idfilter);
							break;
			}
		});
		//alert('merge views: ' + Ext.util.JSON.encode(merge_filters));
		filtrar_topics(merge_filters, labels_checked, categories_checked, statuses_checked, priorities_checked);
	}
	
    function filtrar_topics(merge_filters, labels_checked, categories_checked, statuses_checked, priorities_checked){
        var bp = store_topics.baseParams;
        var base_params;
        if( bp !== undefined )
            base_params= { query: bp.query, start: bp.start, limit: ps, sort: bp.sort, dir: bp.dir };
        var filter = {labels: labels_checked, categories: categories_checked, statuses: statuses_checked, priorities: priorities_checked};
		
		//alert('filters: ' + Ext.util.JSON.encode(filter));
		merge_filters = Baseliner.merge( merge_filters, filter);
		filter_current = Baseliner.merge( merge_filters, base_params );
        store_topics.baseParams = filter_current;
        store_topics.load();
    };


    var tree_root = new Ext.tree.AsyncTreeNode({
				text: 'Filters',
				expanded:true
			});

	var tree_filters = new Ext.tree.TreePanel({
						region : 'east',
						width: 180,
						split: true,
						collapsible: true,
        tbar: [ '->', button_create_view, button_delete_view ],
		dataUrl: "topic/filters_list",
		split: true,
		colapsible: true,
		useArrows: true,
		animate: true,
		autoScroll: true,
		rootVisible: false,
		root: tree_root,
		enableDD: true,
		ddGroup: 'lifecycle_dd'
    });

	tree_filters.on('click', function(node, event){

	});
	
	tree_filters.on('checkchange', function(node, checked) {
		var swDisable = true;
		var selNodes = tree_filters.getChecked();
		var tot_view_defaults = 1;
		Ext.each(selNodes, function(node){
			var type = node.parentNode.attributes.id;
			if(type == 'V'){
				if(!node.attributes.default){
					button_delete_view.enable();
					swDisable = false;
					return false;
				}else{
					if(selNodes.length == tot_view_defaults){
						swDisable = true;
					}else{
						swDisable = false;
					}
				}
			}else{
				swDisable = true;
			}
		});
		if (swDisable)
			button_delete_view.disable();
		loadfilters();
	});	
		
    // expand the whole tree
	tree_filters.getLoader().on( 'load', function(){
        tree_root.expandChildNodes();
    });
		
    var panel = new Ext.Panel({
        layout : "border",
		defaults: {layout:'fit'},
        items : [
			 
					{
						region:'center',
						collapsible: false,
						items: [
							grid_topics
						]
				    },   
                    tree_filters
        ]
    });
    
    var query_id = '<% $c->stash->{query_id} %>';
    store_topics.load({params:{start:0 , limit: ps, query_id: '<% $c->stash->{query_id} %>', id_project: '<% $c->stash->{id_project} %>'}});
	store_label.load();
    
    return panel;
})
