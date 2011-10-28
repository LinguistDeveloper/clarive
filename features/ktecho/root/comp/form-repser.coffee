delete_env = ''
delete_fullname = ''
delete_item = ''
insert_item = ''

conn = new Ext.data.Connection()

combo_recursos_store = new Ext.data.JsonStore
   root: 'data'
   remoteSort: true
   totalProperty: 'totalCount'
   url: 'form/reportingservices/combo_recursos_data'
   fields: [
       name: 'item'
   ]

grid_store = new Ext.data.JsonStore
   root: 'data'
   remoteSort: true
   totalProperty: 'totalCount'
   url: 'form/reportingservices/grid_data'
   fields: [
       {name: 'env'}
       {name: 'fullname'}
       {name: 'item'}
   ]

combo_recursos = new Ext.form.ComboBox
   width: 600
   mode: 'local'
   triggerAction: 'all'
   forceSelection: true
   store: combo_recursos_store
   fieldLabel: 'Recursos'
   valueField: 'item'
   displayField: 'item'
   selectOnFocus: true
   editable: false
   listeners:
       select: () ->
           insert_item = @getValue()

textfield_carpeta_destino = new Ext.form.TextField
   fieldLabel: 'Carpeta Destino'
   id: 'hello'
   value: '\\SCT'

boton_agregar_handler = () ->
   insert_fullname = textfield_carpeta_destino.getValue()
   conn.request
      url: 'form/reportingservices/add_row'
      method: 'POST'
      params:
         item: insert_item
         fullname: insert_fullname
   grid_store.load()

boton_agregar = new Ext.Button
   text: 'Agregar'
   icon: 'static/images/icons/add.png'
   handler: boton_agregar_handler

boton_delete_handler = () ->
   conn.request
      url: 'form/reportingservices/delete_row'
      method: 'POST'
      params:
         env: delete_env
         item: delete_item
         fullname: delete_fullname
   grid_store.load()

boton_delete = new Ext.Button
   text: 'Borrar'
   icon: 'static/images/icons/delete.png'
   handler: boton_delete_handler

column_aplicacion = new Ext.grid.Column
   header: 'Aplicacion'
   width: 120
   sortable: false
   dataIndex: 'env'

column_elementos = new Ext.grid.Column
   header: 'Elementos'
   width: 120
   sortable: false
   dataIndex: 'item'

column_carpeta = new Ext.grid.Column
   header: 'Carpeta'
   width: 120
   sortable: false
   dataIndex: 'fullname'

toolbar = new Ext.Toolbar
   autoHeight: true
   autoWidth: true
   items: [boton_delete]

toolbar_bottom = new Ext.Toolbar
   autoHeight: true
   autoWidth: true
   items: [
       'Nota: Aquellos elementos que no esten catalogados se desplegaran en el directorio \\SCT'
   ]

grid = new Ext.grid.GridPanel
    autoWidth: true
    autoHeight: true
    store: grid_store
    border: false
    viewConfig:
        forceFit: true
    cm: new Ext.grid.ColumnModel [
        new Ext.grid.RowNumberer
        column_aplicacion
        column_elementos
        column_carpeta
    ]

grid.on('rowclick', (grid, rowIndex, e) ->
    row = grid.getStore().getAt(rowIndex)
    delete_env = row.get('env')
    delete_item = row.get('item')
    delete_fullname = row.get('fullname')
)

fieldset_agregar = new Ext.form.FieldSet
   title: 'Agregar nuevo elemento'
   autoHeight: true
   items: [
       combo_recursos
       textfield_carpeta_destino
       boton_agregar
   ]

fieldset_grid = new Ext.form.FieldSet
   autoHeight: true
   items: [
       toolbar
       grid
       toolbar_bottom
   ]

form = new Ext.form.FormPanel
    title: 'Reporting Services'
    items: [
        fieldset_agregar
        fieldset_grid
    ]

combo_recursos_store.load()
grid_store.load()
return form
