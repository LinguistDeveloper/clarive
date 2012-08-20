(function() {
  Ext.ns('Ext.ux.grid');
  Ext.ux.grid.CheckColumn = Ext.extend(Ext.grid.Column, {
    processEvent: function (name, e, grid, rowIndex, colIndex) {
      if (name == 'mousedown') {
        var record = grid.store.getAt(rowIndex);
        record.set(this.dataIndex, !record.data[this.dataIndex]);
        modify_row(e, grid, rowIndex, colIndex);
        return false; // Cancel row selection.
      } else {
        return Ext.grid.ActionColumn.superclass.processEvent.apply(this, arguments);
      }
    },
    renderer: function (v, p, record) {
      p.css += ' x-grid3-check-col-td';
      return String.format('<div class="x-grid3-check-col{0}">&#160;</div>', v ? '-on' : '');
    },
    init: Ext.emptyFn
  });
  Ext.preg('checkcolumn', Ext.ux.grid.CheckColumn);
  Ext.grid.CheckColumn = Ext.ux.grid.CheckColumn;
  Ext.grid.Column.types.checkcolumn = Ext.ux.grid.CheckColumn;
  var ajax_biztalk, button_agregar_proyectos, button_remove_proyectos, c_almacen, c_distribucion, c_proyecto, checkbox_net, column_aplicacion, column_gac, column_proyecto, column_re_aplicacion, column_re_libreria, column_re_store, column_re_subaplicacion, column_re_tipo, column_subaplicacion, column_tipo, combo_almacen, combo_distribucion, combo_proyecto, fieldset_agregar, fieldset_proyectos, fieldset_recursos, form_biztalk, grid_proyectos, grid_recursos, handler_agregar_proyectos, handler_remove_proyectos, pr_aplicacion, pr_gac, pr_proyecto, pr_subaplicacion, pr_tipo, re_aplicacion, re_libreria, re_store, re_subaplicacion, re_tipo, store_almacen, store_combo_distribucion, store_combo_proyecto, store_proyectos, store_recursos, toolbar_proyectos_top, toolbar_recursos_bottom;
  ajax_biztalk = new Ext.data.Connection();
  c_proyecto = '';
  c_distribucion = '';
  c_almacen = '';
  re_aplicacion = '';
  re_subaplicacion = '';
  re_tipo = '';
  re_libreria = '';
  re_store = '';
  pr_aplicacion = '';
  pr_subaplicacion = '';
  pr_proyecto = '';
  pr_tipo = '';
  pr_gac = '';
  checkbox_net = new Ext.form.Checkbox({
    fieldLabel: 'Naturaleza .NET?',
    checked: false
  });
  store_combo_proyecto = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/bizprojects/combo_proyecto',
    fields: [
      {
        name: 'value'
      }
    ]
  });
  store_combo_proyecto.on('load', function() {
    combo_proyecto.setValue(this.getAt(0).get('value'));
    return c_proyecto = this.getAt(0).get('value');
  });
  combo_proyecto = new Ext.form.ComboBox({
    width: 400,
    mode: 'local',
    triggerAction: 'all',
    forceSelection: true,
    store: store_combo_proyecto,
    fieldLabel: 'Proyecto',
    valueField: 'value',
    displayField: 'value',
    selectOnFocus: true,
    editable: false,
    listeners: {
      select: function() {
        return c_proyecto = this.getValue();
      }
    }
  });
  store_combo_distribucion = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/bizprojects/combo_distribucion',
    fields: [
      {
        name: 'value'
      }, {
        name: 'show'
      }
    ]
  });
  store_combo_distribucion.on('load', function() {
    combo_distribucion.setValue(this.getAt(0).get('show'));
    return c_distribucion = this.getAt(0).get('value');
  });
  combo_distribucion = new Ext.form.ComboBox({
    width: 400,
    mode: 'local',
    triggerAction: 'all',
    forceSelection: true,
    store: store_combo_distribucion,
    fieldLabel: 'Tipo Distribucion',
    valueField: 'value',
    displayField: 'show',
    selectOnFocus: true,
    editable: false,
    listeners: {
      select: function() {
        return c_distribucion = this.getValue();
      }
    }
  });
  handler_remove_proyectos = function() {
    ajax_biztalk.request({
      url: '/form/bizprojects/delete_project',
      method: 'POST',
      params: {
        prj_env: pr_aplicacion,
        prj_proyecto: pr_proyecto,
        prj_tipo: pr_tipo,
        prj_subaplicacion: pr_subaplicacion,
        prj_registro_gac: pr_gac
      }
    });
    return store_proyectos.load({
      params: {
        cam: "<% $cam %>"
      }
    });
  };
  button_remove_proyectos = new Ext.Button({
    text: 'Borrar',
    icon: '/static/images/icons/delete.png',
    handler: handler_remove_proyectos
  });
  toolbar_proyectos_top = new Ext.Toolbar({
    autoHeight: true,
    autoWidth: true,
    items: [button_remove_proyectos]
  });
  store_proyectos = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/bizprojects/grid_proyectos',
    fields: [
      {
        name: 'aplicacion'
      }, {
        name: 'subaplicacion'
      }, {
        name: 'proyecto'
      }, {
        name: 'tipo'
      }, {
        name: 'gac'
      }
    ]
  });
  store_recursos = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/bizprojects/grid_recursos',
    fields: [
      {
        name: 'aplicacion'
      }, {
        name: 'subaplicacion'
      }, {
        name: 'tipo'
      }, {
        name: 'proyecto'
      }, {
        name: 'store'
      }
    ]
  });
  handler_agregar_proyectos = function() {
    if (checkbox_net.getValue() === true) {
      ajax_biztalk.request({
        url: '/form/bizprojects/add_project_net',
        method: 'POST',
        params: {
          proyecto: c_proyecto,
          distribucion: c_distribucion,
          cam: "<% $cam %>"
        }
      });
    } else {
      ajax_biztalk.request({
        url: '/form/bizprojects/add_project',
        method: 'POST',
        params: {
          proyecto: c_proyecto,
          prj_tipo: c_distribucion,
          cam: "<% $cam %>"
        }
      });
    }
    return store_proyectos.load({
      params: {
        cam: "<% $cam %>"
      }
    });
  };
  button_agregar_proyectos = new Ext.Button({
    text: 'Agregar',
    icon: '/static/images/icons/add.png',
    handler: handler_agregar_proyectos
  });
  column_aplicacion = new Ext.grid.Column({
    header: 'Aplicacion',
    width: 120,
    sortable: true,
    dataIndex: 'aplicacion'
  });
  column_subaplicacion = new Ext.grid.Column({
    header: 'Subaplicacion',
    width: 120,
    sortable: true,
    dataIndex: 'subaplicacion'
  });
  column_proyecto = new Ext.grid.Column({
    header: 'Proyecto',
    width: 120,
    sortable: true,
    dataIndex: 'proyecto'
  });
  column_tipo = new Ext.grid.Column({
    header: 'Tipo',
    width: 120,
    sortable: true,
    dataIndex: 'tipo'
  });
  column_gac = new Ext.grid.CheckColumn({
    header: 'Registrar GAC',
    dataIndex: 'gac',
    width: 40
  });
  column_re_aplicacion = new Ext.grid.Column({
    header: 'Aplicacion',
    width: 120,
    sortable: true,
    dataIndex: 'aplicacion'
  });
  column_re_subaplicacion = new Ext.grid.Column({
    header: 'Subaplicacion',
    width: 120,
    sortable: true,
    dataIndex: 'subaplicacion'
  });
  column_re_tipo = new Ext.grid.Column({
    header: 'Tipo',
    width: 120,
    sortable: true,
    dataIndex: 'tipo'
  });
  column_re_libreria = new Ext.grid.Column({
    header: 'Libreria',
    width: 120,
    sortable: true,
    dataIndex: 'proyecto'
  });
  column_re_store = new Ext.grid.Column({
    header: 'Store',
    width: 120,
    sortable: true,
    dataIndex: 'store'
  });
  grid_proyectos = new Ext.grid.GridPanel({
    autoWidth: true,
    autoHeight: true,
    store: store_proyectos,
    border: false,
    viewConfig: {
      forceFit: true
    },
    cm: new Ext.grid.ColumnModel([new Ext.grid.RowNumberer, column_aplicacion, column_subaplicacion, column_proyecto, column_tipo, column_gac])
  });
  grid_proyectos.on('rowclick', function(grid, rowIndex, e) {
    var row;
    row = grid.getStore().getAt(rowIndex);
    pr_aplicacion = row.get('aplicacion');
    pr_subaplicacion = row.get('subaplicacion');
    pr_proyecto = row.get('proyecto');
    pr_tipo = row.get('tipo');
    return pr_gac = row.get('gac');
  });
  store_almacen = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/bizprojects/combo_almacen',
    fields: [
      {
        name: 'value'
      }, {
        name: 'show'
      }
    ]
  });
  combo_almacen = new Ext.form.ComboBox({
    width: 150,
    mode: 'local',
    triggerAction: 'all',
    forceSelection: true,
    store: store_almacen,
    fieldLabel: 'Almacen Biztalk',
    valueField: 'value',
    displayField: 'show',
    selectOnFocus: true,
    editable: false,
    listeners: {
      select: function() {
        c_almacen = this.getValue();
        ajax_biztalk.request({
          url: '/form/bizprojects/mod_almacen',
          method: 'POST',
          params: {
            prj_item: re_libreria,
            prj_store: this.getValue(),
            cam: "<% $cam %>"
          }
        });
        return store_recursos.load({
          params: {
            cam: "<% $cam %>"
          }
        });
      }
    }
  });
  grid_recursos = new Ext.grid.GridPanel({
    autoWidth: true,
    autoHeight: true,
    store: store_recursos,
    border: false,
    viewConfig: {
      forceFit: true
    },
    cm: new Ext.grid.ColumnModel([new Ext.grid.RowNumberer, column_re_aplicacion, column_re_subaplicacion, column_re_tipo, column_re_libreria, column_re_store])
  });
  grid_recursos.on('rowclick', function(grid, rowIndex, e) {
    var row;
    row = grid.getStore().getAt(rowIndex);
    re_aplicacion = row.get('aplicacion');
    re_subaplicacion = row.get('subaplicacion');
    re_tipo = row.get('tipo');
    re_libreria = row.get('proyecto');
    re_store = row.get('store');
    return combo_almacen.setValue(re_store);
  });
  toolbar_recursos_bottom = new Ext.Toolbar({
    autoHeight: true,
    autoWidth: true,
    items: ['Almacen Biztalk', combo_almacen]
  });
  fieldset_agregar = new Ext.form.FieldSet({
    title: 'Agregar nuevo elemento',
    autoHeight: true,
    items: [combo_proyecto, combo_distribucion, checkbox_net, button_agregar_proyectos]
  });
  fieldset_proyectos = new Ext.form.FieldSet({
    title: 'Catalogo de Proyectos Biztalk',
    autoHeight: true,
    items: [fieldset_agregar, toolbar_proyectos_top, grid_proyectos]
  });
  fieldset_recursos = new Ext.form.FieldSet({
    title: 'Catalogo de Recursos en el almacen Biztalk',
    autoHeight: true,
    items: [grid_recursos, toolbar_recursos_bottom]
  });
  form_biztalk = new Ext.form.FormPanel({
    title: 'title',
    items: [fieldset_proyectos, fieldset_recursos]
  });
  store_proyectos.load({
    params: {
      cam: "<% $cam %>"
    }
  });
  store_combo_distribucion.load();
  store_almacen.load();
  store_recursos.load({
    params: {
      cam: "<% $cam %>"
    }
  });
  store_combo_proyecto.load({
    params: {
      cam: "<% $cam %>"
    }
  });
  return form_biztalk;
}).call(this);

<%args>
  $cam => $ARGS{cam}
  $fid => $ARGS{fid}
</%args>
