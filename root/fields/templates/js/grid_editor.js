/*
name: Grid Editor
params:
    origin: 'template'
    html: ''
    js: '/fields/templates/js/grid_editor.js'
    field_order: 100
    section: 'details'
---
*/
(function(params){
	var meta = params.topic_meta;
	var data = params.topic_data;
	var ff = params.form.getForm();
	
	var fields = [
		{name: 'id'},
		{name: 'descripcion'},
		{name: 'manual'},
		{name: 'sct'},
		{name: 'rs_esperado'},
		{name: 'sda_obtenida'}
	];
	
	var reader = new Ext.data.JsonReader({
		totalProperty: 'total',
		successProperty: 'success',
		idProperty: 'id',
		fields: fields
	});
	
	var records = data ? data[ meta.bd_field ] : '[]';
	
	var store = new Ext.data.Store({
		reader: reader,
		data:  records ? Ext.util.JSON.decode(records) : []
	});

	
    var groupRow = [
		{colspan: 2},
        {header: 'Datos Entrada', colspan: 2, align: 'center'},
		{colspan: 2}
    ];

    var group = new Ext.ux.grid.ColumnHeaderGroup({
        rows: [groupRow]
    });
    
    var columns = [
		  {dataIndex: 'id', hidden: true},
          {dataIndex: 'descripcion', header: 'Descripción', editor: new Ext.form.TextField({})},
          {dataIndex: 'manual', header: 'Manual', editor: new Ext.form.TextField({})},
          {dataIndex: 'sct', header: 'SCT', editor: new Ext.form.TextField({})},
          {dataIndex: 'rs_esperado', header: 'Resultado Esperado', editor: new Ext.form.TextField({})},
		  {dataIndex: 'sda_obtenida', hidden: meta.typeForm == 'EJC' ? false : true ,header: 'Salida Obtenida', editor: new Ext.form.TextField({})}
    ];
     
    var button_add = new Baseliner.Grid.Buttons.Add({
		text:'',
        tooltip: _('Create'),
        disabled: false,		
        handler: function() {
			var u = new grid.store.recordType({
				descripcion : '',
				manual: '',
				sct : '',
				rs_esperado : '',
				sda_obtenida : ''
			});				

			editor.stopEditing();
			grid.store.insert(0, u);
			editor.startEditing(0,0);
			}
    });
	
    var button_delete = new Baseliner.Grid.Buttons.Delete({
        text: _(''),
        tooltip: _('Delete'),
        cls: 'x-btn-icon',	
        disabled: false,		
        handler: function() {
            //add_step()
        }
    });
	
	
    // use RowEditor for editing
    var editor = new Ext.ux.grid.RowEditor({
        clicksToMoveEditor: 1,
        autoCancel: false,
		listeners: {
			afteredit: function(obj,row){
				obj.grid.store.commitChanges();
				var rows = [];
				obj.grid.store.each( function(rec) {
					var d = rec.data;
					rows.push( d ); 
				});				
				ff.findField( meta.id_field ).setValue(Ext.util.JSON.encode( rows ));
			}
		}		
    });	
	
    var grid = new Ext.grid.GridPanel({
        width: '100%',
        height: 300,
		store: store,
        columns: columns,
        viewConfig: {
            forceFit: true
        },
        plugins: [group, editor],
        tbar: [
			button_add,
			'-',
			button_delete,
			'-'
		]		
    });

	
	
	return [
		{ xtype: 'hidden', name: meta.id_field },
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
		grid
    ]
})

