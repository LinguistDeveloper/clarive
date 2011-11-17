(function() {
  var button_agregar, button_delete, button_delete_handler, combo_proyectos, combo_proyectos_store, combo_tipo_dist_store, combo_tipo_distribucion, conn, form, grid, grid_net_store, toolbar;
  conn = new Ext.data.Connection();
  combo_proyectos_store = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    //url: 'form/netprojects/combo_proyectos',
    url: '/form/netprojects/combo_proyectos',
    fields: [
      {
        name: 'show'
      }, {
        name: 'value'
      }
    ]
  });
  combo_tipo_dist_store = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/netprojects/tipo_distribucion',
    fields: [
      {
        name: 'show'
      }, {
        name: 'value'
      }
    ]
  });
  grid_net_store = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: "totalCount",
    url: '/form/netprojects/net_grid',
    fields: [
      {
        name: 'env'
      }, {
        name: 'proyecto'
      }, {
        name: 'subaplicacion'
      }, {
        name: 'tipo'
      }, {
        name: 'fullname'
      }
    ]
  });
  combo_proyectos = new Ext.form.ComboBox({
    width: 600,
    mode: 'local',
    triggerAction: 'all',
    forceSelection: true,
    store: combo_proyectos_store,
    fieldLabel: 'Proyecto',
    valueField: 'value',
    displayField: 'show',
    selectOnFocus: true,
    editable: false
  });
  combo_tipo_distribucion = new Ext.form.ComboBox({
    width: 600,
    mode: 'local',
    triggerAction: 'all',
    forceSelection: true,
    store: combo_tipo_dist_store,
    fieldLabel: 'Tipo Distribucion',
    valueField: 'value',
    displayField: 'show',
    selectOnFocus: true,
    editable: false
  });
  button_agregar = new Ext.Button({
    text: 'Agregar',
    icon: '/static/images/icons/add.png'
  });
  button_delete_handler = function() {
    alert('click');
    alert('hola');
    conn.request({
      url: '/form/netprojects/delete_row',
      method: 'POST',
      params: {
        env: delete_env,
        proyecto: delete_proyecto,
        subaplicacion: delete_subaplicacion,
        tipo: delete_tipo
      }
    });
    return grid_net_store.load();
  };
  button_delete = new Ext.Button({
    text: 'Borrar',
    handler: button_delete_handler,
    icon: '/static/images/icons/delete.png'
  });
  toolbar = new Ext.Toolbar({
    autoWidth: true,
    autoHeight: true,
    items: button_delete
  });
  grid = new Ext.grid.GridPanel({
    autoWidth: true,
    autoHeight: true,
    store: grid_net_store,
    border: false,
    viewConfig: {
      forceFit: true
    },
    cm: new Ext.grid.ColumnModel([
      new Ext.grid.RowNumberer, {
        header: 'Aplicacion',
        width: 120,
        sortable: true,
        dataIndex: 'env'
      }, {
        header: 'Subaplicacion',
        width: 120,
        sortable: true,
        dataIndex: 'subaplicacion'
      }, {
        header: 'Proyecto',
        width: 120,
        sortable: true,
        dataIndex: 'proyecto'
      }, {
        header: 'Tipo',
        width: 120,
        sortable: true,
        dataIndex: 'tipo'
      }
    ])
  });
  grid.on('rowclick', function(grid, rowIndex, e) {
    var delete_env, delete_proyecto, delete_subaplicacion, delete_tipo, row;
    row = grid.getStore().getAt(rowIndex);
    delete_env = row.get('env');
    delete_proyecto = row.get('proyecto');
    delete_subaplicacion = row.get('subaplicacion');
    return delete_tipo = row.get('tipo');
  });
  form = new Ext.form.FormPanel({
    title: 'Proyectos .NET',
    items: [
      {
        xtype: 'fieldset',
        autoHeight: true,
        title: 'Agregar nuevo elemento',
        items: [combo_proyectos, combo_tipo_distribucion, button_agregar]
      }, {
        xtype: 'fieldset',
        autoHeight: true,
        title: 'Despliegue Proyectos',
        items: [toolbar, grid]
      }
    ]
  });
  grid_net_store.load();
  combo_tipo_dist_store.load();
  combo_proyectos_store.load();
  combo_proyectos_store.on('load', function() {
    combo_proyectos.setValue(this.getAt(0).get('show'));
    return;
  });
//  loadProjects = function() {
//    alert("estoy dentro de la funcion loadProjects"); // XXX
//    combo_proyectos_store.load({
//      params: {
//        fid: "<% $fid %>"
//      }
//    });
//  };
//  loadProjects();
  return form;
}).call(this);

<%args>
  $cam => $ARGS{cam}
  $fid => $ARGS{fid}
</%args>
