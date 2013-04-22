/*
name: Tasks
params:
    html: '/fields/system/html/field_tasks.html'
    js: '/fields/system/js/list_tasks.js'
    type: 'listbox'    
    field_order: 101
    section: 'details'
    filter: 'none'
    single_mode: 'false'    
---
*/
(function(params){
	var meta = params.topic_meta;
	var data = params.topic_data;
	
	var add_tasks = function (){
		var store_topics = new Baseliner.store.Topics({ baseParams: { mid: data ? data.topic_mid : '', show_release: 0, filter: meta.filter ? meta.filter : ''} });

		names_topics = new Array();

		var cb_topics = new Baseliner.model.Topics({
			fieldLabel: _('Tasks'),
			name: 'task',
			hiddenName: 'task',
			store: store_topics,
			singleMode: meta.single_mode
		});
		
		cb_topics.on('additem', function(combo, value, record) {
			console.log( record );
			names_topics[value] = [record.data.name, record.data.title, record.data.color];
		});
									
		var add_topics = function (){
			if (cb_topics.getValue() != ''){
				var id, d, r;
				var topics = cb_topics.getValue().split(',');
				
				Ext.each(topics, function(topic){
					id = store_tasks.getCount() + 1;
					d = { id: id, id_task: topic, task: names_topics[topic][0], description: names_topics[topic][1], color:names_topics[topic][2]};
					r = new store_tasks.recordType( d, id );
					store_tasks.add( r );								
				});
				
				store_tasks.commitChanges();
                refresh_field();
				win_tasks.close();
			}
			delete names_topics;
		};
		
		var form_tasks = new Ext.FormPanel({
			frame: true,
			padding: 15,
			defaults: {
				height: 40,
				anchor: '100%'
			},
			items: [
				cb_topics
			],
			buttons: [
				{  text: _('Cancel') , handler: function(){  win_tasks.close(); } },
				{  text: _('Accept') , handler: function(){  add_topics(); } }
			]
		});
		
		title = _('Create tasks');
		
		win_tasks = new Ext.Window({
			title: _(title),
			autoHeight: true,
			width: 730,
			closeAction: 'close',
			modal: true,
			items: form_tasks
		});
		
		win_tasks.show();			
	}

	

	var btn_add_tasks = new Baseliner.Grid.Buttons.Add({
		handler: function() {
			add_tasks();
		}
	});

	var btn_delete_tasks = new Baseliner.Grid.Buttons.Delete({
		handler: function() {
			//var sm = grid_recipients.getSelectionModel();
			//if (sm.hasSelection()) {
			//	var sel = sm.getSelected();
			//	grid_recipients.getStore().remove(sel);
			//	btn_delete_recipients.disable();
			//} else {
			//	Baseliner.message( _('ERROR'), _('Select at least one row'));    
			//};				
		}
	});
	
	var store_tasks = new Baseliner.JsonStore({
		root: 'data' , 
		remoteSort: true,
		id: 'id', 
		fields: [
			{
				name: 'id_task',
				name: 'task',
				name: 'color',
				name: 'status',
				name: 'observation'
			}
		]														   
	});
    var field = new Ext.form.TextField({ hidden: true, name: meta.id_field });
    var refresh_field = function(){
        var data = [];
        store_tasks.each( function(task){
            data.push( task.data );
        });
        field.setValue( Ext.util.JSON.encode( data ) );
    };
	
    var show_task = function(value, metadata, rec, rowIndex, colIndex, store) {
        var color = rec && rec.data ? rec.data.color : '';
        var ret = '<div id="boot"><span class="badge" style="float:left;padding:2px 8px 2px 8px;background: '+ color + '">' + value + '</span></div>';
        return ret;
    };
	
    var show_status = function(value,metadata,rec,rowIndex,colIndex,store) {
		var cad;
		if(!value){
			cad = "Seleccionar estado";
		}else{
			cad = "<div style='font-weight:bold; font-size: 12px;'>" + value + "</div>" ;
		}
        return cad;
    };
		
		
    var status = new Ext.data.SimpleStore({ fields:['status', 'name'] ,data: [['OK',_('OK')], ['PED',_('PENDIENTE')], ['ERR','ERROR']] });
    
	var grid_tasks = new Ext.grid.EditorGridPanel({
		style: 'border: solid #ccc 1px',
		store: store_tasks,
		layout: 'form',
		height: 300,
		hideHeaders: true,
		viewConfig: {
			headersDisabled: true,
			forceFit: true
		},
		tbar: [
			btn_add_tasks,
			btn_delete_tasks
		],			
		columns: [
			{ width: 80, dataIndex: 'task', renderer: show_task},
			{ width: 200, dataIndex: 'description' },
			{
				dataIndex: 'status',
				renderer: show_status,
				width: 50,
				editor: new Ext.form.ComboBox({
					//value: true, //hiddenName:'status',
					typeAhead: true, valueField: 'status', 
                    displayField: 'name', 
                    mode: 'local', store: status,
					forceSelection: true, triggerAction: 'all',
					listClass: 'x-combo-list-small'
				})
			},
			{
				dataIndex: 'observation',
				width: 100,
				editor: new Ext.form.TextArea({
					//name: 'observation',
					height: 130,
					enableKeyEvents: true,
					//fieldLabel: _('Description'),
					emptyText: _('Observation')
				})
			}			
		]
	});	
    
    grid_tasks.on('afteredit', function(){
        refresh_field();
    });
    
    console.log( data );
    var grid_data = data[ meta.id_field ];
    grid_data = Ext.util.JSON.decode( grid_data );
    if( Ext.isArray( grid_data ) ) {
        Ext.each( grid_data, function(row){
            var r = new store_tasks.recordType( row, row.id );
            store_tasks.add( r );
            store_tasks.commitChanges();
            refresh_field();
        });
    }
	
	return [
		{
		  xtype: 'box',
		  autoEl: {cn: '<br>' + _(meta.name_field) + ':'},
		  hidden: meta ? (meta.hidden ? meta.hidden : false): true
		},
		{
		  xtype: 'box',
		  autoEl: {cn: '<br>'},
		  hidden: meta ? (meta.hidden ? meta.hidden : false): true		  
		},			
		grid_tasks,
        field
    ]
})
