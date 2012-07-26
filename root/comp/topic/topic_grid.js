<%perl>
    use Baseliner::Utils;
    my $id = _nowstamp;
</%perl>
(function(){
    var ps = 25; //page_size
    var filter_current;

    // Create store instances
    var store_category = new Baseliner.Topic.StoreCategory();
    var store_label = new Baseliner.Topic.StoreLabel();
    var store_topics = new Baseliner.Topic.StoreList({
        baseParams: { start: 0, limit: ps },
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
		text: _(''),
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
			emptyText: _('select a category'),
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
	
	
    var make_title = function(){
        var title = [];
		var selNodes = tree_filters.getChecked();
		Ext.each(selNodes, function(node){
			//var type = node.parentNode.attributes.id;
            title.push(node.text);
        }); 
        return title.length > 0 ? title.join(', ') : _('(no filter)');
    };

    var form_report = new Ext.form.FormPanel({
        url: '/topic/report_html', renderTo:'run-panel', style:{ display: 'none'},
        items: [
           { xtype:'hidden', name:'data_json'},
           { xtype:'hidden', name:'title' },
           { xtype:'hidden', name:'rows' },
           { xtype:'hidden', name:'total_rows' }
        ]
    });
    
    var form_report_submit = function(args) {
        var data = { rows:[], columns:[] };
        // find current columns
        var cfg = grid_topics.getColumnModel().config;
        //Baseliner.xx = grid_topics.getView();
        //console.log( grid_topics.getView() );
        for( var i=0; i<cfg.length; i++ ) {
            if( ! cfg[i].hidden )
                data.columns.push({ id: cfg[i].dataIndex, name: cfg[i].report_header || cfg[i].header });
        }
        // get the grid store data
        store_topics.each( function(rec) {
            var d = rec.data;
            var topic_name = String.format('{0} #{1}', d.category_name, d.topic_mid )
            d.topic_name = topic_name;
            data.rows.push( d ); 
        });
        var form = form_report.getForm(); 
        form.findField('data_json').setValue( Ext.util.JSON.encode( data ) );
        form.findField('title').setValue( make_title() );
        form.findField('rows').setValue( store_topics.getCount() );
        form.findField('total_rows').setValue( store_topics.getTotalCount() );
        var el = form.getEl().dom;
        var target = document.createAttribute("target");
        target.nodeValue = args.target || "_blank";
        el.setAttributeNode(target);
        el.action = args.url;
        el.submit(); 
    };

	var btn_html = {
        icon: '/static/images/icons/html.png',
        text: _('Basic HTML Report'),
		handler: function() {
            form_report_submit({ url: '/topic/report_html' });
        }
	};

	var btn_yaml = {
        icon: '/static/images/icons/yaml.png',
        text: _('YAML'),
		handler: function() {
            form_report_submit({ url: '/topic/report_yaml' });
        }
	};

	var btn_csv = {
        icon: '/static/images/icons/csv.png',
        text: _('CSV'),
		handler: function() {
            form_report_submit({ url: '/topic/report_csv', target: 'FrameDownload' });
        }
	};

	var btn_reports = new Ext.Button({
        icon: '/static/images/icons/reports.png',
        iconCls: 'x-btn-icon',
        menu: [ btn_html, btn_csv, btn_yaml ]
    });
	
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
    
    var kanban_show = function(){
        var topics = [];
        var statuses_hash = {};
        store_topics.each( function(rec) {
            topics.push( rec.data.topic_mid );
        });
        Baseliner.ajaxEval( '/topic/kanban_status', { topics: topics }, function(res){
            if( res.success ) {
                //console.log( res.workflow );
                var statuses = res.statuses;
                var workflow = res.workflow;
                var col_num = statuses.length;
                var col_width = 1 / col_num;
                var cols = [];
                var btns = [];

                // Each column is a Panel (so that we have a title)
                Baseliner.KanbanColumn = Ext.extend(Ext.Panel, {
                    layout: 'anchor',
                    autoEl: 'div',
                    border: true,
                    resizeable: true,
                    tools: [{
                        id:'close',
                        hidden: true,
                        handler: function(e, target, panel){
                            panel.hide();
                            //panel.ownerCt.remove(panel, true);
                            kanban.reconfigure_columns();
                            // remove check from menu
                            var id_status = panel.initialConfig.id_status;
                            status_btn.menu.items.each( function(i) {
                                if( i.initialConfig.id_status == id_status  )
                                    i.setChecked(  false );
                            });
                        }
                    }],
                    headerCfg: {
                        style: { 'background-color': '#eee', color: '#555', height: '30px', 'text-transform': 'uppercase', 'font-weight':'bold',
                            'margin-bottom': '10px', padding: '2px 2px 2px 2px', 'font-size':'10px' }
                    },
                    bodyCfg: { 
                        style: {
                            'background': "#555 url('/static/images/bg/grey070.jpg')", 
                            'background-repeat': 'repeat'
                        }
                    },
                    defaultType: 'portlet',
                    cls:'x-portal-column'
                });
                Ext.reg('kanbancolumn', Baseliner.KanbanColumn);

                var status_pressed = function(b){
                    alert( b.initialConfig.id_cat );
                };

                var add_column = function( id_status, name ) {
                   var status_title = '<span style="font-family:Helvetica Neue,Helvetica,Arial,sans-serif; padding: 4px 4px 4px 4px">' + name + '</span>';
                   // create columns
                   var col_obj = new Baseliner.KanbanColumn({
                      xtype: 'kanbancolumn',
                      title: status_title,
                      columnWidth: col_width,
                      id_status: id_status,
                      style: 'padding:10px 0px 10px 10px' 
                   });
                   cols.push( col_obj );
                };
                for( var i=0; i<col_num; i++ ) {
                    add_column( statuses[i].id, statuses[i].name );
                    statuses_hash[ statuses[i].name ] = i;  // store colnum for status
                }

                var status_btn = new Ext.Button({ text:_('Statuses'), menu:[] });
                for( var k=0; k< statuses.length; k++ ) {
                    status_btn.menu.addMenuItem({ id_status: statuses[k].id, text: statuses[k].name, checked: true, checkHandler:remove_column });
                }
                var tab_btn = new Ext.Button({ 
                    icon:'/static/images/icons/tab.png', iconCls:'x-btn-icon', handler: function(){
                    kanban.in_tab = true;
                    var id = Baseliner.addNewTabItem( kanban, 'Kanban', { tab_icon: '/static/images/icons/kanban.png' } );
                    Baseliner.viewport.remove( kanban, false );
                    Baseliner.main.getEl().show();
                    Baseliner.viewport.getLayout().setActiveItem( 0 );
                }});

                var kanban =  new Ext.ux.Portal({
                    margins:'5 5 5 0',
                    height: 400, width: 800,
                    items: cols,
                    tbar: [ 
                        '<img src="/static/images/icons/kanban.png" />',
                        'KANBAN',
                        '-',
                        status_btn,
                        '->',
                        tab_btn,
                        { icon:'/static/images/icons/close.png', iconCls:'x-btn-icon', handler: function(){ 
                                Baseliner.viewport.remove( kanban );
                                Baseliner.main.getEl().show();
                                Baseliner.viewport.getLayout().setActiveItem( 0 );
                            }
                        }
                    ],
                    bodyCfg: { 
                        style: {
                         'background': "#555 url('/static/images/bg/grey070.jpg')", 
                         'background-repeat': 'repeat'
                        }
                    },
                    layoutCfg: {
                        renderHidden: true
                    },
                    listeners: {
                        'dragstart' : function(){ Baseliner.message( 'dkjfkd','jjkjk' ) },
                        'beforedrop': function(e){
                            var wk = workflow[ e.panel.initialConfig.mid ];
                            var id_status_current = e.panel.initialConfig.id_status;
                            var dests = {};
                            for( var i=0; i<wk.length; i++ ) {
                                if( wk[i].id_status_from == id_status_current ) 
                                    dests[ wk[i].id_status_to ] = true;
                            }
                            //var col_obj = 
                            var id_status_dest = e.column.initialConfig.id_status;
                            //Baseliner.message('Portlet Dropped', e.panel.title + '<br />Column: ' + 
                             // e.columnIndex + '<br />Position: ' + e.position);
                            if( dests[ id_status_dest ] === true ) {
                                e.panel.initialConfig.id_status = id_status_dest;
                                return true;
                            } 
                            return false;
                        }
                    }
                });
                // method to reconfigure all columnwidths
                kanban.reconfigure_columns = function(){
                    var cols = kanban.items.items;
                    var col_num = 0;
                    for( var i = 0; i<cols.length; i++ ) {
                        if( ! cols[i].hidden ) col_num++;
                    }
                    var col_width = 1/col_num;
                    for( var i = 0; i<cols.length; i++ ) {
                        cols[i].columnWidth = col_width;
                    };
                    kanban.doLayout();
                };
                kanban.load_store = function( store, id_status ){
                    store.each( function(rec) {
                        if( id_status != undefined && rec.data.category_status_id != id_status ) return;
                        var t = String.format('{0} #{1}', rec.data.category_name, rec.data.topic_mid );
                        var cat = '<div id="boot"><span class="label" style="float:left;width:95%;background: '+ rec.data.category_color + '">' + rec.data.category_name + ' #' + rec.data.topic_mid + '</span></div>';
                        var txt = String.format('<span id="boot">{0}<br /><h5>{1}</h5></span>', cat, rec.data.title);
                        //var txt = String.format('<span id="boot"><h5>{0}</h5></span>', rec.data.title);
                        var col = statuses_hash[ rec.data.category_status_name ];
                        var comp = new Ext.Container({ html: txt, style:'padding: 2px 2px 2px 2px', autoHeight: true, mid: rec.data.topic_mid });
                        comp.on('afterrender', function(){ 
                            this.ownerCt.body.on('dblclick',function(){ 
                                var mid = rec.data.topic_mid;
                                var title = rec.data.topic_name;
                                var params = { topic_mid: mid, title: title };
                                if( kanban.in_tab ) {
                                    Baseliner.add_tabcomp( '/topic/view?topic_mid=' + mid, title, params );
                                } else {
                                    Baseliner.ajaxEval( '/topic/view?topic_mid=' + mid, params, function(topic_panel) {
                                        var win = new Ext.Window({
                                            layout: 'fit', 
                                            modal: true,
                                            autoScroll: true,
                                            style: { overflow: 'hide' },
                                            border: false,
                                            title: title,
                                            height: 600, width: 800, 
                                            maximizable: true,
                                            items: topic_panel
                                        });
                                        //topic_panel.on('afterrender', function(){ topic_panel.header.hide() } );
                                        topic_panel.title = undefined;
                                        win.show();
                                    });
                                }
                            });
                        });
                        add_comp({ 
                          title: t,
                          comp: comp, 
                          mid: rec.data.topic_mid,
                          id_status: rec.data.category_status_id,
                          portlet_type: 'comp',
                          col: col,
                          url_portlet: 'http://xxxx', url_max: 'http://xxxx'
                        });
                    });
                };
                // add portlet to column
                var add_comp = function( params ) {
                        var col = params.col || 0;
                        var comp = params.comp;
                        comp.height = comp.height || 350;
                        var title = comp.title || params.title || 'Portlet';
                        //comp.collapsible = true;
                        var column_obj = kanban.findById( cols[col].id );
                        var portlet = {
                            //collapsible: true,
                            title: title,
                            height: 50,
                            mid: params.mid,
                            id_status: params.id_status,
                            //headerCfg: { style: 'background: #d44' },
                            portlet_type: params.portlet_type,
                            header: false,
                            footer: false,
                            footerCfg: { hide: true },
                            //url_portlet: params.url_portlet,
                            url_max: params.url_max,
                            //tools: Baseliner.portalTools,  // tools are visible when header: true
                            //collapsed: true,
                            autoHeight: true,
                            items: comp
                        };
                        column_obj.add( portlet );
                        //column_obj.doLayout();
                };

                var remove_column = function(opt){
                    var id_status = opt.initialConfig.id_status;
                    kanban.items.each( function(i){
                        if( i.initialConfig.id_status == id_status ) {
                            if( opt.checked ) { // show
                                i.show();
                            } else { // hide
                                i.hide();
                            }
                            kanban.reconfigure_columns();
                        }
                    });
                };

                kanban.on('afterrender', function(cmp){
                    kanban.load_store( store_topics );
                    kanban.doLayout();
                    
                    // show/hide tools for the column 
                    var cols = kanban.findByType( 'kanbancolumn' );
                    for( var i = 0; i<cols.length; i++ ) {
                        cols[i].header.on( 'mouseover', function(ev,obj){
                            var col_obj = Ext.getCmp( obj.id );
                            if( col_obj == undefined ) col_obj = Ext.getCmp( obj.parentNode.id );
                            if( col_obj == undefined ) col_obj = Ext.getCmp( obj.parentNode.parentNode.id );
                            if( col_obj == undefined ) col_obj = Ext.getCmp( obj.parentNode.parentNode.parentNode.id );
                            if( col_obj != undefined ) {
                                var t = col_obj.getTool('close');
                                var w = col_obj.el.dom.offsetWidth;
                                t.setStyle('display','block');
                                t.setStyle('position','absolute');
                                t.setStyle('margin-left', w-30 );
                            }
                        });
                        cols[i].header.on( 'mouseout', function(ev,obj){
                            var col_obj = Ext.getCmp( obj.id );
                            if( col_obj == undefined ) col_obj = Ext.getCmp( obj.parentNode.id );
                            if( col_obj == undefined ) col_obj = Ext.getCmp( obj.parentNode.parentNode.id );
                            if( col_obj == undefined ) col_obj = Ext.getCmp( obj.parentNode.parentNode.parentNode.id );
                            if( col_obj != undefined ) col_obj.getTool('close').hide();
                        });
                    };
                });
                //Baseliner.viewport.add( kanban );
                /* Baseliner.main.getEl().fadeOut({ duration: .2, easing: 'easeOut', remove: false, callback: function() {
                        Baseliner.viewport.add( kanban );
                        Baseliner.viewport.getLayout().setActiveItem( 1 );
                    }
                }); */
                Baseliner.viewport.add( kanban );
                Baseliner.viewport.getLayout().setActiveItem( 1 );
            } else {
            }
        });
    };
	var btn_kanban = new Ext.Toolbar.Button({
        icon:'/static/images/icons/kanban.png',
        cls: 'x-btn-text-icon',
        //enableToggle: true,
        pressed: false,
        handler: kanban_show
    }); 
    
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
				tag_color_html = tag_color_html
                    + "<div id='boot'><span class='label' style='font-size: 9px; float:left;padding:1px 4px 1px 4px;margin-right:4px;color:#" 
                    + returnOpposite(label_color) + ";background-color:#" + label_color + "'>" + label_name + "</span></div>";				
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
                "<span style='color: #808080'><img border=0 src='/static/images/icons/paperclip.gif' /> ",
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

    var render_progress = function(value,metadata,rec,rowIndex,colIndex,store){
        if( value == 0 ) return '';
        var cls = ( value < 20 ? 'danger' : ( value < 40 ? 'warning' : ( value < 80 ? 'info' : 'success' ) ) );
        var ret =  [
            '<span id="boot">',
            '<div class="progress progress-'+ cls +'" style="height: 8px">',
                '<div class="bar" style="width: '+value+'%">',
                '</div>',
            '</div>',
            '</span>',
        ].join('');
        return ret;
    };

    var render_category = function(value,metadata,rec,rowIndex,colIndex,store){
        var mid = rec.data.topic_mid; //Cambiarlo en un futuro por un contador de categorias
        var cat_name = rec.data.category_name; //Cambiarlo en un futuro por un contador de categorias
        var color = rec.data.category_color;
        var cls = rec.data.is_release ? 'label' : 'badge';
        //if( color == undefined ) color = '#777';
        var ret = '<div id="boot"><span class="'+cls+'" style="float:left;padding:2px 8px 2px 8px;background: '+ color + '">' + cat_name + ' #' + mid + '</span></div>';
        return ret;
    };

    var search_field = new Baseliner.SearchField({
        store: store_topics,
        params: {start: 0 },
        emptyText: _('<Enter your search string>')
    });
    var ptool = new Ext.PagingToolbar({
            store: store_topics,
            pageSize: ps,
            plugins:[
                new Ext.ux.PageSizePlugin({
                    editable: false,
                    width: 90,
                    data: [
                        ['5', 5], ['10', 10], ['15', 15], ['20', 20], ['25', 25], ['50', 50],
                        ['100', 100], ['200',200], ['500', 500], ['1000', 1000], [_('all rows'), -1 ]
                    ],
                    beforeText: _('Show'),
                    afterText: _('rows/page'),
                    value: ps,
                    listeners: {
                        'select':function(c,rec) {
                            ps = rec.data.value;
                            if( rec.data.value < 0 ) {
                                ptool.afterTextItem.hide();
                            } else {
                                ptool.afterTextItem.show();
                            }
                        }
                    },
                    forceSelection: true
                })
            ],
            displayInfo: true,
            displayMsg: _('Rows {0} - {1} of {2}'),
            emptyMsg: _('There are no rows available')
    });

    var grid_topics = new Ext.grid.GridPanel({
        title: _('Topics'),
        header: false,
        stripeRows: true,
        autoScroll: true,
        //enableHdMenu: false,
        store: store_topics,
        enableDragDrop: true,
        autoSizeColumns: true,
        deferredRender: true,
        ddGroup: 'lifecycle_dd',
        viewConfig: {forceFit: true},
        selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
        loadMask:'true',
        columns: [
            { header: _('Name'), sortable: true, dataIndex: 'topic_name', width: 80, sortable: true, renderer: render_category },
            { header: _('Category'), sortable: true, dataIndex: 'category_name', hidden: true, width: 80, sortable: true },
            { header: _('Status'), sortable: true, dataIndex: 'category_status_name', width: 50, renderer: render_status },
            { header: _('Title'), dataIndex: 'title', width: 250, sortable: true, renderer: render_title},
            { header: _('%'), dataIndex: 'progress', width: 25, sortable: true, renderer: render_progress },
            { header: '', report_header: _('Comments'), sortable: true, dataIndex: 'numcomment', width: 45, renderer: render_comment },			
            { header: _('Projects'), dataIndex: 'projects', width: 60, renderer: render_project },
            { header: _('ID'), hidden: true, sortable: true, dataIndex: 'topic_mid'},    
            { header: _('Created On'), hidden: true, sortable: true, dataIndex: 'created_on'},
            { header: _('Created By'), hidden: true, sortable: true, dataIndex: 'created_by'}
        ],
        tbar:   [ 
                search_field,
                btn_add,
                btn_edit,
                btn_delete,
                //btn_labels
                '->',
                btn_reports,
                btn_kanban,
                btn_comprimir
                //btn_close
        ], 		
        bbar: ptool
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

    function loadfilters( unselected_node ){
		var labels_checked = new Array();
		var statuses_checked = new Array();
		var categories_checked = new Array();
		var priorities_checked = new Array();
		var type;
		var selected_views = { };
		selNodes = tree_filters.getChecked();
        for( var i=0; i<selNodes.length; i++ ) {
            var node = selNodes[ i ];
			type = node.parentNode.attributes.id;
			switch (type){
				//Views
				case 'V':	
                            var d = Ext.util.JSON.decode(node.attributes.filter);
                            if( d.query !=undefined && selected_views.query !=undefined ) {
                                d.query = d.query + ' ' + selected_views.query;
                            }
                            selected_views = Baseliner.merge(selected_views, d );
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
		}
		//alert('merge views: ' + Ext.util.JSON.encode(selected_views));
		filtrar_topics(selected_views, labels_checked, categories_checked, statuses_checked, priorities_checked, unselected_node);
	}
	
    function filtrar_topics(selected_views, labels_checked, categories_checked, statuses_checked, priorities_checked, unselected_node){
        // copy baseParams for merging
        var bp = store_topics.baseParams;
        var base_params;
        if( bp !== undefined )
            base_params= { start: bp.start, limit: ps, sort: bp.sort, dir: bp.dir };
        // object for merging with views 
        var selected_filters = {labels: labels_checked, categories: categories_checked, statuses: statuses_checked, priorities: priorities_checked};
		
		//alert('selected_views ' + Ext.util.JSON.encode(selected_views));
		//alert('merge_filters: ' + Ext.util.JSON.encode(merge_filters));
		//alert('bfilters: ' + Ext.util.JSON.encode(base_params));

        // merge selected filters with views
		var merge_filters = Baseliner.merge( selected_views, selected_filters);
        // now merge baseparams (query, limit and start) over the resulting filters
		var filter_final = Baseliner.merge( merge_filters, base_params );
        // query and unselected
        if( unselected_node != undefined ) {
            var unselected_type = unselected_node.parentNode.attributes.id;
            var unselected_filter = Ext.util.JSON.decode(unselected_node.attributes.filter);
            if( unselected_type == 'V' ) {
                if( bp.query == unselected_filter.query ) {
                    filter_final.query = '';
                } else {
                    filter_final.query = bp.query.replace( unselected_filter.query, '' );
                    filter_final.query = filter_final.query.replace( /^ +/, '' );
                    filter_final.query = filter_final.query.replace( / +$/, '' );
                }
            }
        }
        else if( selected_views.query != undefined  && bp.query != undefined ) {
            //filter_final.query = bp.query + ' ' + selected_views.query;
        }

		//alert('curr ' + Ext.util.JSON.encode(filter_final));
        //if( base_params.query !== filter_final.query ) {
            //delete filter_final['query'];    
        //}
        store_topics.baseParams = filter_final;
        search_field.setValue( filter_final.query );
        store_topics.load();
        filter_current = filter_final;
    };


    var tree_root = new Ext.tree.AsyncTreeNode({
				text: 'Filters',
				expanded:true
			});

    this.collapse_me = function(obj) {
        //alert( 121 );
        //Baseliner.ooo = obj;
        ///console.log( obj );
    };
    var id_collapse = Ext.id();
	var tree_filters = new Ext.tree.TreePanel({
						region : 'east',
                        header: false,
						width: 180,
						split: true,
						collapsible: true,
        tbar: [
            '->', button_create_view, button_delete_view,
            '<div class="x-tool x-tool-expand-west" style="margin:-2px -4px 0px 0px" id="'+id_collapse+'"></div>'
        ],
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
	
	tree_filters.on('checkchange', function(node_selected, checked) {
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
        if( checked ) {
            loadfilters();
        } else {
            loadfilters( node_selected );
        }
	});	
		
    // expand the whole tree
	tree_filters.getLoader().on( 'load', function(){
        tree_root.expandChildNodes();

        // draw the collapse button onclick event 
        var el_collapse = Ext.get( id_collapse );
        if( el_collapse )
            el_collapse.dom.onclick = function(){ 
                panel.body.dom.style.overflow = 'hidden'; // collapsing shows overflow, so we hide it
                tree_filters.collapse();
            };
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
	//var category_id = '<% $c->stash->{category_id} %>';
    store_topics.load({params:{start:0 , limit: ps, query_id: '<% $c->stash->{query_id} %>', id_project: '<% $c->stash->{id_project} %>', categories: '<% $c->stash->{category_id} %>'}});
	store_label.load();
    
    return panel;
})
