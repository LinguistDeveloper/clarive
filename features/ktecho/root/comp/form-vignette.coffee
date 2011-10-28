`Ext.ns('Ext.ux.grid');
Ext.ux.grid.CheckColumn = Ext.extend(Ext.grid.Column, {
	processEvent: function(name, e, grid, rowIndex, colIndex) {
		if (name == 'mousedown') {
			var record = grid.store.getAt(rowIndex);
			record.set(@dataIndex, ! record.data[@dataIndex]);
            modify_row(e, grid, rowIndex, colIndex);
			return false; // Cancel row selection.
		} else {
			return Ext.grid.ActionColumn.superclass.processEvent.apply(this, arguments);
		}
	},
	renderer: function(v, p, record) {
		p.css += ' x-grid3-check-col-td';
		return String.format('<div class="x-grid3-check-col{0}">&#160;</div>', v ? '-on': '');
	},
	init: Ext.emptyFn
});
Ext.preg('checkcolumn', Ext.ux.grid.CheckColumn);
Ext.grid.CheckColumn = Ext.ux.grid.CheckColumn;
Ext.grid.Column.types.checkcolumn = Ext.ux.grid.CheckColumn;
`

                                                        # INIT VARS

c_entorno = 'TEST'
c_server = ''
c_user = ''
usu = ''
vig_accion = ''
vig_pausa = ''
vig_activo = ''
ajax_vignette = new Ext.data.Connection()

                                                        # FUNCTIONS

load_store_usuario = () ->
    store_usuario.load
        params:
            env: c_entorno

reset_params = () ->
    usu = ''
    vig_accion = ''
    vig_pausa = ''
    vig_activo = ''

load_grids = () ->
    store_grid_test.load
        params:
            env: 'TEST'
    store_grid_ante.load
        params:
            env: 'ANTE'
    store_grid_prod.load
        params:
            env: 'PROD'

delete_row = (vig_env) ->
    ajax_vignette.request
        url: '/form/vignette/delete_row'
        method: 'POST'
        params:
            vig_env: vig_env
            usu: usu
            vig_accion: vig_accion
            vig_pausa: vig_pausa
            vig_activo: vig_activo
    load_grids()
    reset_params()

raise_order = (vig_env) ->
    ajax_vignette.request
        url: '/form/vignette/raise_order'
        method: 'POST'
        params:
            vig_env: vig_env
            usu: usu
            vig_accion: vig_accion
            vig_pausa: vig_pausa
            vig_activo: vig_activo
    load_grids()
    reset_params()

modify_row = (e, grid, rowIndex, colIndex) ->
    row = grid.getStore().getAt(rowIndex)
    alert row.get('pausa')
    alert row.get('active')
#    ajax_vignette.request
#        url: '/form/vignette/update_row'
#        method: 'POST'
#        params:
#            usu: row.get('usu')
#            vig_accion: row.get('code')
#            vig_pausa: row.get('pausa')
#            vig_activo: row.get('active')
#            vig_env: grid.label
#       load_grids()
                                                        # STORES

store_grid_test = new Ext.data.JsonStore
    root: 'data'
    remoteSort: true
    totalProperty: 'totalCount'
    url: '/form/vignette/get_grid'
    fields: [
        { name: 'usu' }
        { name: 'code' }
        { name: 'pausa' }
        { name: 'active' }
    ]

store_grid_ante = new Ext.data.JsonStore
    root: 'data'
    remoteSort: true
    totalProperty: 'totalCount'
    url: '/form/vignette/get_grid'
    fields: [
        { name: 'usu' }
        { name: 'code' }
        { name: 'pausa' }
        { name: 'active' }
    ]

store_grid_prod = new Ext.data.JsonStore
    root: 'data'
    remoteSort: true
    totalProperty: 'totalCount'
    url: '/form/vignette/get_grid'
    fields: [
        { name: 'usu' }
        { name: 'code' }
        { name: 'pausa' }
        { name: 'active' }
    ]

store_entorno = new Ext.data.JsonStore
    root: 'data'
    remoteSort: true
    totalProperty: 'totalCount'
    url: '/form/vignette/get_entornos'
    fields: [
        { name: 'env' }
    ]

store_server = new Ext.data.JsonStore
    root: 'data'
    remoteSort: true
    totalProperty: 'totalCount'
    url: '/form/vignette/get_servers'
    fields: [
        { name: 'server' }
    ]

store_usuario = new Ext.data.JsonStore
    root: 'data'
    remoteSort: true
    totalProperty: 'totalCount'
    url: '/form/vignette/get_usuario_funcional'
    fields: [
        { name: 'user' }
    ]

store_entorno.on 'load', () ->
    combo_entorno.setValue @getAt(0).get 'env'
    c_entorno = @getAt(0).get 'env'

store_server.on 'load', () ->
    combo_servidor.setValue @getAt(0).get 'server'
    c_server = @getAt(0).get 'server'

store_usuario.on 'load', () ->
    combo_usuario.setValue @getAt(0).get 'user'
    c_user = @getAt(0).get 'user'

store_grid_test.on 'load', () ->
    if @getCount() isnt 0 then fieldset_test.show() else fieldset_test.hide()

store_grid_ante.on 'load', () ->
    if @getCount() isnt 0 then fieldset_ante.show() else fieldset_ante.hide()

store_grid_prod.on 'load', () ->
    if @getCount() isnt 0 then fieldset_prod.show() else fieldset_prod.hide()

                                                        # COMBOS

combo_entorno = new Ext.form.ComboBox
    width: 400
    mode: 'local'
    triggerAction: 'all'
    forceSelection: true
    store: store_entorno
    fieldLabel: 'Entorno'
    valueField: 'env'
    displayField: 'env'
    selectOnFocus: true
    editable: false
    listeners:
        select: () ->
            c_entorno = @getValue()
            load_store_usuario()

combo_servidor = new Ext.form.ComboBox
    width: 400
    mode: 'local'
    triggerAction: 'all'
    forceSelection: true
    store: store_server
    fieldLabel: 'Servidor'
    valueField: 'server'
    displayField: 'server'
    selectOnFocus: true
    editable: false
    listeners:
        select: () ->
            c_server = @getValue()

combo_usuario = new Ext.form.ComboBox
    width: 400
    mode: 'local'
    triggerAction: 'all'
    forceSelection: true
    store: store_usuario
    fieldLabel: 'Usuario Funcional'
    valueField: 'user'
    displayField: 'user'
    selectOnFocus: true
    editable: false
    listeners:
        select: () ->
            c_user = @getValue()

                                                        # TEXTFIELDS

txtfield_codigo = new Ext.form.TextField
    fieldLabel: 'Codigo de la Accion'

                                                        # CHECKBOX

checkbox_pause = new Ext.form.Checkbox
    fieldLabel: 'Realizar pausa'
    checked: true

                                                        # HANDLERS

agregar = () ->
    ajax_vignette.request
        url: 'form/vignette/add_row'
        method: 'POST'
        params:
            vig_env: c_entorno
            vig_maq: c_server
            c_user: c_user
            vig_pausa: checkbox_pause.getValue()
            vig_accion: txtfield_codigo.getValue()
    store_grid_test.load
        params:
            env: 'TEST'
    store_grid_ante.load
        params:
            env: 'ANTE'
    store_grid_prod.load
        params:
            env: 'PROD'

handler_agregar = () ->
    agregar_bool = true
    if txtfield_codigo.getValue() is ''
        alert 'Falta rellenar el codigo de la accion'
        agregar_bool = false
    agregar() if agregar_bool

handler_delete_test = () ->
    vig_env = 'TEST'
    delete_row(vig_env)

handler_delete_ante = () ->
    vig_env = 'ANTE'
    delete_row(vig_env)

handler_delete_prod = () ->
    vig_env = 'PROD'
    delete_row(vig_env)

handler_upgrade_test = () ->
    vig_env = 'TEST'
    raise_order(vig_env)

handler_upgrade_ante = () ->
    vig_env = 'ANTE'
    raise_order(vig_env)

handler_upgrade_prod = () ->
    vig_env = 'PROD'
    raise_order(vig_env)

handler_hola = () ->
    alert 'ok'
    
                                                        # BUTTONS

button_delete_test = new Ext.Button
    text: 'Borrar'
    icon: 'static/images/icons/delete.png'
    handler: handler_delete_test

button_delete_ante = new Ext.Button
    text: 'Borrar'
    icon: 'static/images/icons/delete.png'
    handler: handler_delete_ante

button_delete_prod = new Ext.Button
    text: 'Borrar'
    icon: 'static/images/icons/delete.png'
    handler: handler_delete_prod

button_agregar = new Ext.Button
    text: 'Agregar'
    icon: 'static/images/icons/add.png'
    handler: handler_agregar

button_upgrade_test = new Ext.Button
    text: 'Subir orden'
    icon: 'static/images/silk/arrow_up.gif'
    handler: handler_upgrade_test

button_upgrade_ante = new Ext.Button
    text: 'Subir orden'
    icon: 'static/images/silk/arrow_up.gif'
    handler: handler_upgrade_ante

button_upgrade_prod = new Ext.Button
    text: 'Subir orden'
    icon: 'static/images/silk/arrow_up.gif'
    handler: handler_upgrade_prod

                                                        # TOOLBARS

toolbar_grid_test = new Ext.Toolbar
    autoHeight: true
    autoWidth: true
    items: [
        button_delete_test
        button_upgrade_test
    ]

toolbar_grid_ante = new Ext.Toolbar
    autoHeight: true
    autoWidth: true
    items: [
        button_delete_ante
        button_upgrade_ante
    ]

toolbar_grid_prod = new Ext.Toolbar
    autoHeight: true
    autoWidth: true
    items: [
        button_delete_prod
        button_upgrade_prod
    ]

                                                        # COLUMNS

column_usuario_test = new Ext.grid.Column
    header: 'Usuario:Grupo@Nodo'
    width: 120
    sortable: true
    dataIndex: 'usu'

column_codigo_test = new Ext.grid.Column
    header: 'Codigo de la accion'
    width: 120
    sortable: true
    dataIndex: 'code'

column_pausa_test = new Ext.grid.CheckColumn
    header: 'Pausa'
    dataIndex: 'pausa'
    width: 40

column_activo_test = new Ext.grid.CheckColumn
    header: 'Activo'
    dataIndex: 'active'
    width: 40

column_usuario_ante = new Ext.grid.Column
    header: 'Usuario:Grupo@Nodo'
    width: 120
    sortable: true
    dataIndex: 'usu'

column_codigo_ante = new Ext.grid.Column
    header: 'Codigo de la accion'
    width: 120
    sortable: true
    dataIndex: 'code'

column_pausa_ante = new Ext.grid.CheckColumn
    header: 'Pausa'
    dataIndex: 'pausa'
    width: 40

column_activo_ante = new Ext.grid.CheckColumn
    header: 'Activo'
    dataIndex: 'active'
    width: 40

column_usuario_prod = new Ext.grid.Column
    header: 'Usuario:Grupo@Nodo'
    width: 120
    sortable: true
    dataIndex: 'usu'

column_codigo_prod = new Ext.grid.Column
    header: 'Codigo de la accion'
    width: 120
    sortable: true
    dataIndex: 'code'

column_pausa_prod = new Ext.grid.CheckColumn
    header: 'Pausa'
    dataIndex: 'pausa'
    width: 40

column_activo_prod = new Ext.grid.CheckColumn
    header: 'Activo'
    dataIndex: 'active'
    width: 40

                                                        # GRIDS

grid_test = new Ext.grid.GridPanel
    label: 'TEST'
    hideLabel: true
    autoWidth: true
    autoHeight: true
    store: store_grid_test
    border: false
    viewConfig:
        forceFit: true
    cm: new Ext.grid.ColumnModel [
        new Ext.grid.RowNumberer
        column_usuario_test
        column_codigo_test
        column_pausa_test
        column_activo_test
    ]

grid_test.on 'rowclick', (grid, rowIndex, e) ->
    row = grid.getStore().getAt(rowIndex)
    usu = row.get('usu')
    vig_accion = row.get('code')
    vig_pausa = row.get('pausa')
    vig_activo = row.get('active')

grid_ante = new Ext.grid.GridPanel
    label: 'ANTE'
    hideLabel: true
    autoWidth: true
    autoHeight: true
    store: store_grid_ante
    border: false
    viewConfig:
        forceFit: true
    cm: new Ext.grid.ColumnModel [
        new Ext.grid.RowNumberer
        column_usuario_ante
        column_codigo_ante
        column_pausa_ante
        column_activo_ante
    ]

grid_ante.on 'rowclick', (grid, rowIndex, e) ->
    row = grid.getStore().getAt(rowIndex)
    usu = row.get('usu')
    vig_accion = row.get('code')
    vig_pausa = row.get('pausa')
    vig_activo = row.get('active')

grid_prod = new Ext.grid.GridPanel
    label: 'PROD'
    hideLabel: true
    autoWidth: true
    autoHeight: true
    store: store_grid_prod
    border: false
    viewConfig:
        forceFit: true
    cm: new Ext.grid.ColumnModel [
        new Ext.grid.RowNumberer
        column_usuario_prod
        column_codigo_prod
        column_pausa_prod
        column_activo_prod
    ]

grid_prod.on 'rowclick', (grid, rowIndex, e) ->
    row = grid.getStore().getAt(rowIndex)
    usu = row.get('usu')
    vig_accion = row.get('code')
    vig_pausa = row.get('pausa')
    vig_activo = row.get('active')

                                                        # FIELDSETS

fieldset_agregar = new Ext.form.FieldSet
    title: 'Agregar nuevo elemento'
    autoHeight: true
    items: [
        combo_entorno
        combo_servidor
        combo_usuario
        checkbox_pause
        txtfield_codigo
        button_agregar
    ]

fieldset_test = new Ext.form.FieldSet
    title: 'Test'
    autoHeight: true
    items: [
        toolbar_grid_test
        grid_test
    ]
    hide: true

fieldset_ante = new Ext.form.FieldSet
    title: 'Ante'
    autoHeight: true
    items: [
        toolbar_grid_ante
        grid_ante
    ]

fieldset_prod = new Ext.form.FieldSet
    title: 'Prod'
    autoHeight: true
    items: [
        toolbar_grid_prod
        grid_prod
    ]

fieldset_despliegue = new Ext.form.FieldSet
    title: 'Despliegue de elementos'
    autoHeight: true
    items: [
        fieldset_test
        fieldset_ante
        fieldset_prod
    ]

                                                        # FORMS

form_vignette = new Ext.form.FormPanel
    title: 'Formulario Vignette'
    items: [
        fieldset_agregar
        fieldset_despliegue
    ]

                                                        # DO STUFF

store_entorno.load()
store_server.load()
load_store_usuario()
load_grids()

return form_vignette
