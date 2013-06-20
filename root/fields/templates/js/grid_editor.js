/*
name: Grid Editor
params:
    origin: 'template'
    js: '/fields/templates/js/grid_editor.js'
    html: '/fields/templates/html/grid_editor.html'
    field_order: 100
    field_order_html: 1000
    section: 'head'
---
*/
(function(params){
	var meta = params.topic_meta;
	var data = params.topic_data;
	var ff = params.form.getForm();
	
    /*
    var groupRow = [
		{colspan: 2},
        {header: 'Datos Entrada', colspan: 2, align: 'center'},
		{colspan: 2}
    ];

    var group = new Ext.ux.grid.ColumnHeaderGroup({
        rows: [groupRow]
    });
    */
    
    var render_checkbox = function(v){
        return v 
            ? '<img src="/static/images/icons/checkbox.png">'
            : '<img src="/static/images/icons/delete.gif">';
    }
    
    var sm = new Baseliner.RowSelectionModel({ singleSelect: true }); 
    //var sm = new Baseliner.CheckboxSelectionModel({ checkOnly: true, singleSelect: false });
    
	
    var cols, fields;
    var cols_templates = {
          id : function(){ return {width: 10 } },
          index : function(){ return {width: 10, renderer:function(v,m,r,i){return i+1} } },
          htmleditor: function(){ return { editor: new Ext.form.HtmlEditor(), default_value:'' } },
          textfield : function(){ return { width: 100, editor: new Ext.form.TextField({}), default_value:'' } },
          checkbox  : function(){ return { align: 'center', width: 10, editor: new Ext.form.Checkbox({}), default_value:false, renderer: render_checkbox } },
          textarea  : function(){ return { editor: new Ext.form.TextArea({}), default_value:'', renderer: Baseliner.render_wrap } }
    };
    if( meta.columns != undefined ) {
        cols=[]; fields=[];
        var cc = Ext.isArray( meta.columns ) ? meta.columns : meta.columns.split(';');
        Ext.each( cc, function(col){
            var ct;
            if( Ext.isObject( col ) ) {
                ct = col;
            } else {
                var col_s = col.split(',');
                if( col_s[0] == undefined ) return;
                ct = cols_templates[ col_s[1] ] || cols_templates['textarea'];
                ct = ct();
                ct.header = col_s[0];
                if( col_s[2] != undefined ) ct.width = col_s[2];
                ct.sortable = true;
                if( col_s[3] ) ct.default_value = col_s[3];
                ct.dataIndex = Baseliner.name_to_id( col_s[0] );
            }
            cols.push( ct );
            fields.push( ct.dataIndex );
        });
    } else {
        cols = [
          {dataIndex: 'description', header: _('Description'), width: 100, editor: new Ext.form.TextArea({}) }
        ];
        fields = [
            {name: 'description'}
        ];
    }
    
    // default record for adding
    var rec_default = {};
    Ext.each( cols, function(col){
        rec_default[ col.dataIndex ] = col.default_value || '';
    });
	
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
     	
    var button_add = new Baseliner.Grid.Buttons.Add({
		text:'',
        tooltip: _('Create'),
        disabled: false,
        handler: function() {
			var u = new grid.store.recordType(rec_default);
			var index = grid.store.getCount();
			editor.stopEditing();
			grid.store.insert(index, u);
			grid.getSelectionModel().selectRow(index);			
			editor.startEditing(index);
        }
    });
	
	
	
    var button_delete = new Baseliner.Grid.Buttons.Delete({
        text: _(''),
        tooltip: _('Delete'),
        cls: 'x-btn-icon',	
        disabled: false,		
        handler: function() {
            var sm = grid.getSelectionModel();
            Ext.each( sm.getSelections(), function(r) {
				var index =store.indexOf(r);
                grid.store.remove( r );
				rows.splice(index, 1);
				grid.store.commitChanges();
				grid.getView().refresh();
            });
		
			ff.findField( meta.id_field ).setValue(Ext.util.JSON.encode( rows ));
        }
    });
	
	var rows = records ? Ext.util.JSON.decode(records) : [];
    // use RowEditor for editing
	
    var editor = new Ext.ux.grid.RowEditor({
        clicksToMoveEditor: 1,
        autoCancel: false,
        enableDragDrop: true, 
		listeners: {
			afteredit: function(roweditor, changes, record, rowIndex){
				console.dir(changes);
				console.dir(record);
				roweditor.grid.store.commitChanges();
				delete record.data.id;
				rows[rowIndex] = record.data;
				ff.findField( meta.id_field ).setValue(Ext.util.JSON.encode( rows ));
			}
		}		
    });	
	
    var grid = new Ext.grid.GridPanel({
        width: meta.width || '100%',
        height: meta.height || 300,
		store: store,
        columns: cols,
        sm: sm,
        enableDragDrop: true, 
        viewConfig: {
            forceFit: meta.forceFit || true
        },
        plugins: [ editor],
        tbar: [
			button_add,
			'-',
			button_delete
		]
    });
    var self = grid;
 
    grid.on( 'afterrender', function(){
        self.ddGroup = 'bali-grid-html-' + self.id;
        var ddrow = new Baseliner.DropTarget(self.container, {
            comp: self,
            ddGroup : self.ddGroup,
            copy: false,
            notifyDrop : function(dd, e, data){
                var ds = self.store;
                var sm = self.getSelectionModel();
                var rows = sm.getSelections();
                if(dd.getDragData(e)) {
                    var cindex=dd.getDragData(e).rowIndex;
                    if(typeof(cindex) != "undefined") {
                        for(i = 0; i <  rows.length; i++) {
                            ds.remove(ds.getById(rows[i].id));
                        }
                        ds.insert(cindex,data.selections);
                        sm.clearSelections();
                    }
                    self.refresh_field();
                }
            }
        }); 
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

