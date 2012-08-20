(function() {
  var column_activo, column_codigo, column_desc, column_responsables, column_unidad, form_hsp, grid_hsp, store_grid_hsp;
  store_grid_hsp = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/main/load_grid_hsp',
    fields: [
      {
        name: 'procodigo'
      }, {
        name: 'prodesc'
      }, {
        name: 'prounidad'
      }, {
        name: 'proresp'
      }, {
        name: 'proactivo'
      }
    ]
  });
  column_codigo = new Ext.grid.Column({
    header: 'Codigo',
    width: 120,
    sortable: true,
    dataIndex: 'procodigo'
  });
  column_desc = new Ext.grid.Column({
    header: 'Descripcion',
    width: 120,
    sortable: true,
    dataIndex: 'prodesc'
  });
  column_unidad = new Ext.grid.Column({
    header: 'Unidad',
    width: 120,
    sortable: true,
    dataIndex: 'prounidad'
  });
  column_responsables = new Ext.grid.Column({
    header: 'Responsables',
    width: 120,
    sortable: true,
    dataIndex: 'proresp'
  });
  column_activo = new Ext.grid.Column({
    header: 'Activo?',
    width: 120,
    sortable: true,
    dataIndex: 'proactivo'
  });
  grid_hsp = new Ext.grid.GridPanel({
    autoWidth: true,
    autoHeight: true,
    store: store_grid_hsp,
    border: false,
    viewConfig: {
      forceFit: true
    },
    cm: new Ext.grid.ColumnModel([new Ext.grid.RowNumberer, column_codigo, column_desc, column_unidad, column_responsables, column_activo])
  });
  form_hsp = new Ext.form.FormPanel({
    title: 'Despliegue de TODO',
    items: [grid_hsp]
  });
  store_grid_hsp.load({
    params: {
      tipo: '<% $tipo %>'
    }
  });
  return form_hsp;

<%args>
    $tipo => $ARGS{tipo}
</%args>
;
}).call(this);
