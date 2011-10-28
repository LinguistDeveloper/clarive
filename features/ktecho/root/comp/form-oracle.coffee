c_des_entorno = ''
c_des_red = ''
c_des_folder = ''
c_des_instancia = ''
c_ins_entorno = ''
c_ins_red = ''
c_ins_owner = ''
c_ins_instancia = ''
ora_entorno = ''
ora_redes = ''
ora_fullname = ''
ora_instancia = ''
ins_entorno = ''
ins_instancia = ''
ins_propietario = ''
ins_red = ''

ajax_oracle = new Ext.data.Connection()

load_owners = () ->
    store_combo_ins_owner.load
        params:
            i_red: c_ins_red
            i_entorno: c_ins_entorno

load_ins_instancia = () ->
    store_combo_ins_instancia.load
        params:
            env: c_ins_entorno

load_des_instancia = () ->
    store_combo_des_instancia.load
        params:
            env: c_des_entorno

store_combo_des_entorno = new Ext.data.JsonStore
    root: 'data'
    remoteSort: true
    totalProperty: 'totalCount'
    url: '/form/oraprojects/get_entornos'
    fields: [
        { name: 'entorno' }
    ]

store_combo_des_entorno.on 'load', () ->
    combo_des_entorno.setValue @getAt(0).get 'entorno'
    c_des_entorno = @getAt(0).get 'entorno'
    load_des_instancia()

store_combo_des_red = new Ext.data.JsonStore
    root: 'data'
    remoteSort: true
    totalProperty: 'totalCount'
    url: '/form/oraprojects/get_redes'
    fields: [
        { name: 'value' }
        { name: 'show' }
    ]

store_combo_des_red.on 'load', () ->
    combo_des_red.setValue @getAt(0).get 'show'
    c_des_red = @getAt(0).get 'value'

store_combo_des_folder = new Ext.data.JsonStore
    root: 'data'
    remoteSort: true
    totalProperty: 'totalCount'
    url: '/form/oraprojects/get_folders'
    fields: [
        { name: 'folder' }
    ]

store_combo_des_folder.on 'load', () ->
    combo_des_folder.setValue @getAt(0).get 'folder'
    c_des_folder = @getAt(0).get 'folder'

store_combo_des_instancia = new Ext.data.JsonStore
    root: 'data'
    remoteSort: true
    totalProperty: 'totalCount'
    url: '/form/oraprojects/get_instancias_despliegue'
    fields: [
        { name: 'value' }
        { name: 'instancia_real' }
    ]

store_combo_des_instancia.on 'load', () ->
    combo_des_instancia.setValue @getAt(0).get 'instancia_real'
    c_des_instancia = @getAt(0).get 'instancia_real'

store_grid_des = new Ext.data.JsonStore
    root: 'data'
    remoteSort: true
    totalProperty: 'totalCount'
    url: '/form/oraprojects/grid_despliegue'
    fields: [
        { name: 'entorno' }
        { name: 'red' }
        { name: 'carpeta' }
        { name: 'instancia' }
    ]

store_combo_ins_entorno = new Ext.data.JsonStore
    root: 'data'
    remoteSort: true
    totalProperty: 'totalCount'
    url: '/form/oraprojects/get_entornos'
    fields: [
        { name: 'entorno' }
    ]

store_combo_ins_entorno.on 'load', () ->
    combo_ins_entorno.setValue @getAt(0).get 'entorno'
    c_ins_entorno = @getAt(0).get 'entorno'
    load_owners()
    load_ins_instancia()

store_combo_ins_red = new Ext.data.JsonStore
    root: 'data'
    remoteSort: true
    totalProperty: 'totalCount'
    url: '/form/oraprojects/get_redes'
    fields: [
        { name: 'value' }
        { name: 'show' }
    ]

store_combo_ins_red.on 'load', () ->
    combo_ins_red.setValue @getAt(0).get 'show'
    c_ins_red = @getAt(0).get 'value'
    load_owners()

store_combo_ins_owner = new Ext.data.JsonStore
    root: 'data'
    remoteSort: true
    totalProperty: 'totalCount'
    url: '/form/oraprojects/get_owners'
    fields: [
        { name: 'owner' }
    ]

store_combo_ins_owner.on 'load', () ->
    combo_ins_owner.setValue @getAt(0).get 'owner'
    c_ins_owner = @getAt(0).get 'owner'

store_combo_ins_instancia = new Ext.data.JsonStore
    root: 'data'
    remoteSort: true
    totalProperty: 'totalCount'
    url: '/form/oraprojects/get_instancias'
    fields: [
        { name: 'instancia' }
    ]

store_combo_ins_instancia.on 'load', () ->
    combo_ins_instancia.setValue @getAt(0).get 'instancia'
    c_ins_instancia = @getAt(0).get 'instancia'

store_grid_ins = new Ext.data.JsonStore
    root: 'data'
    remoteSort: true
    totalProperty: 'totalCount'
    url: '/form/oraprojects/grid_instancia'
    fields: [
        { name: 'entorno' }
        { name: 'red' }
        { name: 'owner' }
        { name: 'oracle' }
    ]

combo_des_entorno = new Ext.form.ComboBox
    width: 400
    mode: 'local'
    triggerAction: 'all'
    forceSelection: true
    store: store_combo_des_entorno
    fieldLabel: 'Entorno'
    valueField: 'entorno'
    displayField: 'entorno'
    selectOnFocus: true
    editable: false
    listeners:
        select: () ->
            c_des_entorno = @getValue()
            load_des_instancia()

combo_des_red = new Ext.form.ComboBox
    width: 400
    mode: 'local'
    triggerAction: 'all'
    forceSelection: true
    store: store_combo_des_red
    fieldLabel: 'Red'
    valueField: 'value'
    displayField: 'show'
    selectOnFocus: true
    editable: false
    listeners:
        select: () ->
            c_des_red = @getValue()

combo_des_folder = new Ext.form.ComboBox
    width: 400
    mode: 'local'
    triggerAction: 'all'
    forceSelection: true
    store: store_combo_des_folder
    fieldLabel: 'Carpeta'
    valueField: 'folder'
    displayField: 'folder'
    selectOnFocus: true
    editable: false
    listeners:
        select: () ->
            c_des_folder = @getValue()

combo_des_instancia = new Ext.form.ComboBox
    width: 400
    mode: 'local'
    triggerAction: 'all'
    forceSelection: true
    store: store_combo_des_instancia
    fieldLabel: 'Instancia'
    valueField: 'instancia_real'
    displayField: 'value'
    selectOnFocus: true
    editable: false
    listeners:
        select: () ->
            c_des_instancia = @getValue()

combo_ins_entorno = new Ext.form.ComboBox
    width: 400
    mode: 'local'
    triggerAction: 'all'
    forceSelection: true
    store: store_combo_ins_entorno
    fieldLabel: 'Entorno'
    valueField: 'entorno'
    displayField: 'entorno'
    selectOnFocus: true
    editable: false
    listeners:
        select: () ->
            c_ins_entorno = @getValue()
            load_owners()
            load_ins_instancia()

combo_ins_red = new Ext.form.ComboBox
    width: 400
    mode: 'local'
    triggerAction: 'all'
    forceSelection: true
    store: store_combo_ins_red
    fieldLabel: 'Red'
    valueField: 'value'
    displayField: 'show'
    selectOnFocus: true
    editable: false
    listeners:
        select: () ->
            c_ins_red  = @getValue()
            load_owners

combo_ins_owner = new Ext.form.ComboBox
    width: 400
    mode: 'local'
    triggerAction: 'all'
    forceSelection: true
    store: store_combo_ins_owner
    fieldLabel: 'Owner'
    valueField: 'owner'
    displayField: 'owner'
    selectOnFocus: true
    editable: false
    listeners:
        select: () ->
            c_ins_owner = @getValue()

combo_ins_instancia = new Ext.form.ComboBox
    width: 400
    mode: 'local'
    triggerAction: 'all'
    forceSelection: true
    store: store_combo_ins_instancia
    fieldLabel: 'Instancia'
    valueField: 'instancia'
    displayField: 'instancia'
    selectOnFocus: true
    editable: false
    listeners:
        select: () ->
            c_ins_instancia  = @getValue()

handler_agregar_des = () ->
    ajax_oracle.request
        url: '/form/oraprojects/add_despliegue'
        method: 'POST'
        params:
            ora_entorno: c_des_entorno
            ora_redes: c_des_red
            ora_fullname: c_des_folder
            del_instancia: c_des_instancia
    store_grid_des.load()

handler_agregar_ins = () ->
    ajax_oracle.request
        url: '/form/oraprojects/add_instancia'
        method: 'POST'
        params:
            entorno: c_ins_entorno
            red: c_ins_red
            propietario: c_ins_owner
            instancia: c_ins_instancia
    store_grid_ins.load()
    

handler_delete_ins = () ->
    ajax_oracle.request
        url: '/form/oraprojects/delete_ins'
        method: 'POST'
        params:
            entorno: ins_entorno
            instancia: ins_instancia
            propietario: ins_propietario
            red: ins_red
    store_grid_ins.load()

handler_delete_des = () ->
    ajax_oracle.request
        url: '/form/oraprojects/delete_des'
        method: 'POST'
        params:
            ora_entorno: ora_entorno
            ora_redes: ora_redes
            ora_fullname: ora_fullname
            ora_instancia: ora_instancia
    store_grid_des.load()

handler_button_desplegar = () ->
    alert 'ClickClick!'

button_agregar_des = new Ext.Button
    text: 'Agregar'
    icon: 'static/images/icons/add.png'
    handler: handler_agregar_des

button_agregar_ins = new Ext.Button
    text: 'Agregar'
    icon: 'static/images/icons/add.png'
    handler: handler_agregar_ins

button_delete_des = new Ext.Button
    text: 'Borrar'
    icon: 'static/images/icons/delete.png'
    handler: handler_delete_des

button_delete_ins = new Ext.Button
    text: 'Borrar'
    icon: 'static/images/icons/delete.png'
    handler: handler_delete_ins

button_desplegar = new Ext.Button
    text: 'Desplegar'
    icon: 'static/images/icons/step_run.png'
    handler: handler_button_desplegar

toolbar_des = new Ext.Toolbar
    autoHeight: true
    autoWidth: true
    items: [
        button_delete_des
        button_desplegar
    ]

toolbar_ins = new Ext.Toolbar
    autoHeight: true
    autoWidth: true
    items: [
        button_delete_ins
    ]

column_des_entorno = new Ext.grid.Column
    header: 'Entorno'
    width: 120
    sortable: true
    dataIndex: 'entorno'

column_des_red = new Ext.grid.Column
    header: 'Red'
    width: 120
    sortable: true
    dataIndex: 'red'

column_des_carpeta = new Ext.grid.Column
    header: 'Carpeta'
    width: 120
    sortable: true
    dataIndex: 'carpeta'

column_des_instancia = new Ext.grid.Column
    header: 'Instancia'
    width: 120
    sortable: true
    dataIndex: 'instancia'

column_ins_entorno = new Ext.grid.Column
    header: 'Entorno'
    width: 120
    sortable: true
    dataIndex: 'entorno'

column_ins_red = new Ext.grid.Column
    header: 'Red'
    width: 120
    sortable: true
    dataIndex: 'red'

column_ins_owner = new Ext.grid.Column
    header: 'Owner'
    width: 120
    sortable: true
    dataIndex: 'owner'

column_ins_oracle = new Ext.grid.Column
    header: 'Instancia Oracle'
    width: 120
    sortable: true
    dataIndex: 'oracle'

grid_des = new Ext.grid.GridPanel
    autoWidth: true
    autoHeight: true
    store: store_grid_des
    border: false
    viewConfig:
        forceFit: true
    cm: new Ext.grid.ColumnModel [
        new Ext.grid.RowNumberer
        column_des_entorno
        column_des_red
        column_des_carpeta
        column_des_instancia
    ]

grid_des.on 'rowclick', (grid, rowIndex, e) ->
    row = grid.getStore().getAt(rowIndex)
    ora_entorno = row.get('entorno')
    ora_redes = row.get('red')
    ora_fullname = row.get('carpeta')
    ora_instancia = row.get('instancia')

grid_ins = new Ext.grid.GridPanel
    autoWidth: true
    autoHeight: true
    store: store_grid_ins
    border: false
    viewConfig:
        forceFit: true
    cm: new Ext.grid.ColumnModel [
        new Ext.grid.RowNumberer
        column_ins_entorno
        column_ins_red
        column_ins_owner
        column_ins_oracle
    ]

grid_ins.on 'rowclick', (grid, rowIndex, e) ->
    row = grid.getStore().getAt(rowIndex)
    ins_entorno = row.get('entorno')
    ins_instancia = row.get('oracle')
    ins_propietario = row.get('owner')
    ins_red = row.get('red')

fieldset_des_configurar = new Ext.form.FieldSet
    title: 'Configuracion del Despliegue de Elementos ORACLE'
    autoHeight: true
    items: [
        combo_des_entorno
        combo_des_red
        combo_des_folder
        combo_des_instancia
        button_agregar_des
    ]

fieldset_des_grid = new Ext.form.FieldSet
    title: 'Configuracion del despliegue de elementos ORACLE para SCT'
    autoHeight: true
    items: [
        toolbar_des
        grid_des
    ]

fieldset_ins_conf = new Ext.form.FieldSet
    title: 'Configuracion de Instancias ORACLE'
    autoHeight: true
    items: [
        combo_ins_entorno
        combo_ins_red
        combo_ins_owner
        combo_ins_instancia
        button_agregar_ins
    ]

fieldset_ins_grid = new Ext.form.FieldSet
    title: 'Instancias ORACLE configuradas para SCT'
    autoHeight: true
    items: [
        toolbar_ins
        grid_ins
    ]

panel_despliegue = new Ext.Panel
    title: 'Despliegue'
    autoHeight: true
    items: [
        fieldset_des_configurar
        fieldset_des_grid
    ]

panel_instancias = new Ext.Panel
    title: 'Instancias'
    autoHeight: true
    items: [
        fieldset_ins_conf
        fieldset_ins_grid
    ]

tabpanel_oracle = new Ext.TabPanel
    activeTab: 0
    items: [
        panel_despliegue
        panel_instancias
    ]

form_oracle = new Ext.form.FormPanel
    title: 'Proyectos Oracle'
    items: [
        tabpanel_oracle
    ]

store_combo_des_entorno.load()
store_combo_des_red.load()
store_combo_des_folder.load()
store_grid_des.load()
store_combo_ins_entorno.load()
store_combo_ins_red.load()
store_grid_ins.load()

return form_oracle
