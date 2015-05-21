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
            names_topics[value] = [record.data.name, record.data.title, record.data.color];
        });
                                    
        var add_topics = function (){
            if (cb_topics.getValue() != ''){
                var id, d, r;
                var topics = cb_topics.getValue().split(',');
                
                Ext.each(topics, function(topic){
                    id = store_tasks.getCount() + 1;
                    d = { id: id, mid: topic, id_task: topic, task: names_topics[topic][0], description: names_topics[topic][1], color:names_topics[topic][2]};
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
            var sm = grid_tasks.getSelectionModel();
            if (sm.hasSelection()) {
              var sel = sm.getSelected();
              grid_tasks.getStore().remove(sel);
              btn_delete_tasks.disable();
            } else {
              Baseliner.message( _('ERROR'), _('Select at least one row'));    
            };                
        }
    });
    
    var store_tasks = new Baseliner.JsonStore({
        root: 'data' , 
        remoteSort: true,
        id: 'id', 
        fields: [
            {
                name: 'mid',
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
    
    var render_topic_name = function(value, metadata, rec, rowIndex, colIndex, store) {
        var d = rec.data;
        return Baseliner.topic_name({
            mid: d.mid, 
            mini: true,
            size: '9',
            category_name: value,
            category_color:  d.color,
            category_icon: d.category_icon,
            is_changeset: d.is_changeset,
            is_release: d.is_release
        });
    };
    
    var show_status = function(value,metadata,rec,rowIndex,colIndex,store) {
        var cad;
        if(!value){
            cad = "Seleccionar estado";
        }else{
            //cad = "<div style='font-weight:bold; font-size: 12px;'>" + value + "</div>" ;
            var img = value=="OK" ? "drop-yes.gif" : value=="KO" ? "cancel.png" : "help.png";
            cad = String.format('<img src="/static/images/icons/{0}" />', img );
        }
        return cad;
    };
        
    var status = new Ext.data.SimpleStore({ fields:['status', 'name'],
        data: [['OK',_('OK')], ['?',_('PENDING')], ['KO',_('ERROR')]] });
    
    var time_tpl = new Ext.XTemplate(
        '<tpl for=".">',
        '<div class="search-item">', 
        '<table><tr><td><img src="/static/images/icons/{[ values.status=="OK" ? "drop-yes.gif" : values.status=="KO" ? "cancel.png" : "help.png" ]}"/></td>',
        '<td><span><b>{name}</span></b></td></tr></table></div>',
        '</tpl>'
    );
    /*
        name: 'job_combo',
        hiddenName: 'job_combo',
        fieldLabel: '<% _loc('Franja horaria') %>',
        valueField: 'valueJson',
        displayField:'displayText',
        itemSelector: 'div.search-item',
        store: time_store,
        allowBlank: false,
        width: 150,
        labelWidth: 250,
        typeAhead: true,
        mode: 'local',
        forceSelection: true,
        triggerAction: 'all',
        tpl: time_tpl,
        disabled: true,
        selectOnFocus:true
     */
    
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
            { width: 80, dataIndex: 'task', renderer: render_topic_name},
            { width: 200, dataIndex: 'description' },
            {
                dataIndex: 'status',
                renderer: show_status,
                width: 50,
                editor: new Ext.form.ComboBox({
                    //value: true, //hiddenName:'status',
                    typeAhead: true, 
                    valueField: 'status', 
                    displayField: 'name', 
                    tpl: time_tpl,
                    itemSelector: 'div.search-item',
                    mode: 'local', store: status,
                    editable: false,
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
	
	grid_tasks.on('rowclick', function(grid, rowIndex, e) {
		btn_delete_tasks.enable();
	});		
    
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
          hidden: Baseliner.eval_boolean(meta.hidden)
        },
        {
          xtype: 'box',
          autoEl: {cn: '<br>'},
          hidden: Baseliner.eval_boolean(meta.hidden)        
        },          
        grid_tasks,
        field
    ]
})
