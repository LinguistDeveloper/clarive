c_cam = ''
tiene_java = false
text_pre = 'Despliegue de la aplicacion '
entorno = ''
url = '/consola/index'
sub_apl = ''
tiene_test = ''
tiene_ante = ''
tiene_prod = ''

createGridButton = (value, id, record) ->
  new Ext.Button
    text: value
    iconCls: IconManager.getIcon 'package_add'
    handler: (btn, e) ->
      alert 'hello world'
  .render(document.body, id)

store_tiene_java = new Ext.data.JsonStore
  root: 'data'
  remoteSort: true
  totalProperty: 'totalCount'
  url: '/consolaj2ee/has_java'
  fields: [
    { name: 'value' } ]

store_tiene_entorno = new Ext.data.JsonStore
  root: 'data'
  remoteSort: true
  totalProperty: 'totalCount'
  url: '/consolaj2ee/get_entornos'
  fields: [
    { name: 'test' }
    { name: 'ante' }
    { name: 'prod' } ]

store_tiene_java.on 'load', () ->
  has_java = @getAt(0).get 'value'
  if has_java is 1
    show_all()
    tiene_java = true
    store_grid_consola.load
      params:
        cam: c_cam
    label_cam.setText text_pre + c_cam
  else
    tiene_java = false
    hide_all()
    alert 'El CAM seleccionado no tiene aplicaciones JAVA'

store_cams = new Ext.data.JsonStore
  root: 'data'
  remoteSort: true
  totalProperty: 'totalCount'
  url: '/consolaj2ee/get_list_of_cams'
  fields: [
    { name: 'cam' } ]

panel_grid = new Ext.Panel
  title: 'Search CAM'
  style: 'margin-bottom: 10px'
  autoHeight: true
  autoWidth: true
  bodyPadding: 10
  layout: 'anchor'
  items: [ {
      xtype: 'combo'
      store: store_cams
      mode: 'local'
      forceSelection: true
      triggerAction: 'all'
      displayField: 'cam'
      valueField: 'cam'
      typeAhead: false
      hideLabel: true
      hideTrigger: true
      anchor: '100%'
      listConfig:
        loadingText: 'Searching...'
        emptyText: 'No matching posts found.'
      listeners:
        select: () ->
          c_cam = @getValue()
          store_tiene_java.load
            params:
              cam: c_cam
          store_tiene_entorno.load
            params:
              cam: c_cam } ]

# Oculta los tabs cuando la aplicación no esté desplegada en un determinado entorno
store_tiene_entorno.on 'load', () ->
  row = @getAt(0)
  tiene_test = row.get 'test'
  tiene_ante = row.get 'ante'
  tiene_prod = row.get 'prod'
  if tiene_test is 0
    tabpanel_entorno.hideTabStripItem 'tab_test'
  else
    tabpanel_entorno.unhideTabStripItem 'tab_test'
  if tiene_ante is 0
    tabpanel_entorno.hideTabStripItem 'tab_ante'
  else
    tabpanel_entorno.unhideTabStripItem 'tab_ante'
  if tiene_prod is 0
    tabpanel_entorno.hideTabStripItem 'tab_prod'
  else
    tabpanel_entorno.unhideTabStripItem 'tab_prod'

column_sub_apl = new Ext.grid.Column
  header: 'Subaplicacion'
  width: 40
  sortable: true
  dataIndex: 'sub_appl'

call_component = (op, title) ->
  params =
    env_name: c_cam
    env: entorno
    sub_apl: sub_apl
    operator: op
  Baseliner.addNewWindowComp url, title, params

store_grid_consola = new Ext.data.JsonStore
  root: 'data'
  remoteSort: true
  totalProperty: 'totalCount'
  url: '/consolaj2ee/get_sub_appl'
  fields: [
    { name: 'sub_appl' } ]

label_cam = new Ext.form.Label
  text: text_pre

toolbar_consola = new Ext.Toolbar
  autoHeight: true
  autoWidth: true
  items: [
    label_cam ]

tabpanel_entorno = new Ext.TabPanel
  activeTab: 0
  items: [
    {
      title: 'TEST'
      itemId: 'tab_test'
    }
    {
      title: 'ANTE'
      itemId: 'tab_ante'
    }
    {
      title: 'PROD'
      itemId: 'tab_prod'
    } ]

hide_buttons = () ->
  button_start.disable()
  button_stop.disable()
  button_reset.disable()

show_buttons = () ->
  button_start.enable()
  button_stop.enable()
  button_reset.enable()

tabpanel_entorno.on 'tabChange', () ->
  activeTab = @getActiveTab()
  entorno = activeTab.title
  if entorno is 'PROD'
    hide_buttons()
  else
    show_buttons()

button_start = new Ext.Button
  text: 'Iniciar'
  icon: 'static/images/start.gif'
  handler: () ->
    op = 'START'
    call_component op, @text

button_stop = new Ext.Button
  text: 'Parar'
  icon: 'static/images/stop.gif'
  handler: () ->
    op = 'STOP'
    call_component op, @text

button_reset = new Ext.Button
  text: 'Reiniciar'
  icon: 'static/images/reload.gif'
  handler: () ->
    op = 'RESTART'
    call_component op, @text

logs_was =
  text: 'Logs de WAS'
  icon: 'static/images/icons/television.png'
  handler: () ->
    op = 'LOGWAS'
    call_component op, @text

logs_aplicacion =
  text: 'Logs de Aplicacion'
  icon: 'static/images/icons/television.png'
  handler: () ->
    op = 'LOGAPL'
    call_component op, @text

config_ls =
  text: 'LS'
  icon: 'static/images/icons/television.png'
  handler: () ->
    op = 'CONFIGLS'
    call_component op, @text

config =
  text: 'Configuracion'
  icon: 'static/images/icons/television.png'
  menu:
    showSeparator: false
    items:
      config_ls
  handler: () ->
    op = 'CONFIG'
    call_component op, @text

acciones = new Ext.Toolbar.Button
  text: 'Acciones'
  menu: [
    logs_was
    logs_aplicacion
    config ]
    
toolbar_opciones = new Ext.Toolbar
  autoHeight: true
  autoWidth: true
  items: [
    button_start
    button_stop
    button_reset
    '-'
    acciones ]

grid_consola = new Ext.grid.GridPanel
  autoWidth: true
  autoHeight: true
  store: store_grid_consola
  border: false
  viewConfig:
    forceFit: true
  cm: new Ext.grid.ColumnModel [
      new Ext.grid.RowNumberer
      column_sub_apl ]

grid_consola.on 'rowclick', (grid, rowIndex, e) ->
  row = grid.getStore().getAt(rowIndex)
  sub_apl = row.get('sub_appl')
 
fieldset_consola = new Ext.form.FieldSet
  title: 'Consola de Aplicaciones J2EE'
  width: 640
  autoHeight: true
  items: [
    panel_grid
    tabpanel_entorno
    toolbar_opciones
    grid_consola
    toolbar_consola ]

form_consola = new Ext.form.FormPanel
  title: 'Consola de Aplicaciones J2EE'
  items: [
    fieldset_consola ]

show_all = () ->
  tabpanel_entorno.show()
  toolbar_opciones.show()
  grid_consola.show()
  toolbar_consola.show()

hide_all = () ->
  tabpanel_entorno.hide()
  toolbar_opciones.hide()
  grid_consola.hide()
  toolbar_consola.hide()

store_cams.load()
grid_consola.hide()
hide_all()

return form_consola
