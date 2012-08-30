(function() {
  var column_activa, column_clase, column_codigo, column_descripcion, column_estado, column_width, form_inc, grid_inc, store_grid_inc;
  column_width = 80;
  column_codigo = new Ext.grid.Column({
    header: 'Codigo',
    width: column_width,
    sortable: true,
    dataIndex: 'inc_codigo'
  });
  column_descripcion = new Ext.grid.Column({
    header: 'Descripcion',
    width: column_width,
    sortable: true,
    dataIndex: 'inc_descripcion'
  });
  column_clase = new Ext.grid.Column({
    header: 'Clase',
    width: column_width,
    sortable: true,
    dataIndex: 'inc_clase'
  });
  column_estado = new Ext.grid.Column({
    header: 'Estado',
    width: column_width,
    sortable: true,
    dataIndex: 'inc_estado'
  });
  column_activa = new Ext.grid.Column({
    header: '¿Activa?',
    width: column_width,
    sortable: true,
    dataIndex: 'inc_activa'
  });
  store_grid_inc = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/main/load_grid_inc',
    fields: [
      {
        name: 'inc_codigo'
      }, {
        name: 'inc_descripcion'
      }, {
        name: 'inc_clase'
      }, {
        name: 'inc_estado'
      }, {
        name: 'inc_activa'
      }, {
        name: 'inc_cam'
      }
    ]
  });
  grid_inc = new Ext.grid.GridPanel({
    autoWidth: true,
    autoHeight: true,
    store: store_grid_inc,
    border: false,
    viewConfig: {
      forceFit: true
    },
    cm: new Ext.grid.ColumnModel([new Ext.grid.RowNumberer, column_codigo, column_descripcion, column_clase, column_estado, column_activa])
  });
  form_inc = new Ext.form.FormPanel({
    title: 'Despliegue de Incidencias Activas',
    width: 600,
    items: [grid_inc]
  });
  store_grid_inc.load({
    params: {
      cam: "<% $cam %>"
    }
  });
  return form_inc;
}).call(this);

<%args>
    $cam => $ARGS{cam}
</%args>
