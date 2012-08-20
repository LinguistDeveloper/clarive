(function() {
  Ext.ns('Ext.ux.grid');
  Ext.ux.grid.CheckColumn = Ext.extend(Ext.grid.Column, {
  	processEvent: function(name, e, grid, rowIndex, colIndex) {
  		if (name == 'mousedown') {
  			var record = grid.store.getAt(rowIndex);
  			record.set(this.dataIndex, ! record.data[this.dataIndex]);
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
  var agregar, ajax_vignette, button_agregar, button_delete_ante, button_delete_prod, button_delete_test, button_upgrade_ante, button_upgrade_prod, button_upgrade_test, c_entorno, c_server, c_user, checkbox_pause, column_activo_ante, column_activo_prod, column_activo_test, column_codigo_ante, column_codigo_prod, column_codigo_test, column_pausa_ante, column_pausa_prod, column_pausa_test, column_usuario_ante, column_usuario_prod, column_usuario_test, combo_entorno, combo_servidor, combo_usuario, delete_row, fieldset_agregar, fieldset_ante, fieldset_despliegue, fieldset_prod, fieldset_test, form_vignette, grid_ante, grid_prod, grid_test, handler_agregar, handler_delete_ante, handler_delete_prod, handler_delete_test, handler_hola, handler_upgrade_ante, handler_upgrade_prod, handler_upgrade_test, load_grids, load_store_usuario, modify_row, raise_order, reset_params, store_entorno, store_grid_ante, store_grid_prod, store_grid_test, store_server, store_usuario, toolbar_grid_ante, toolbar_grid_prod, toolbar_grid_test, txtfield_codigo, usu, vig_accion, vig_activo, vig_pausa;
  c_entorno = 'TEST';
  c_server = '';
  c_user = '';
  usu = '';
  vig_accion = '';
  vig_pausa = '';
  vig_activo = '';
  ajax_vignette = new Ext.data.Connection();
  load_store_usuario = function() {
    return store_usuario.load({
      params: {
        env: c_entorno,
        cam: "<% $cam %>"
      }
    });
  };
  reset_params = function() {
    usu = '';
    vig_accion = '';
    vig_pausa = '';
    return vig_activo = '';
  };
  load_grids = function() {
    store_grid_test.load({
      params: {
        env: 'TEST',
        cam: "<% $cam %>"
      }
    });
    store_grid_ante.load({
      params: {
        env: 'ANTE',
        cam: "<% $cam %>"
      }
    });
    return store_grid_prod.load({
      params: {
        env: 'PROD',
        cam: "<% $cam %>"
      }
    });
  };
  delete_row = function(vig_env) {
    ajax_vignette.request({
      url: '/form/vignette/delete_row',
      method: 'POST',
      params: {
        vig_env: vig_env,
        usu: usu,
        vig_accion: vig_accion,
        vig_pausa: vig_pausa,
        vig_activo: vig_activo,
        cam: "<% $cam %>"
      }
    });
    load_grids();
    return reset_params();
  };
  raise_order = function(vig_env) {
    ajax_vignette.request({
      url: '/form/vignette/raise_order',
      method: 'POST',
      params: {
        vig_env: vig_env,
        usu: usu,
        vig_accion: vig_accion,
        vig_pausa: vig_pausa,
        vig_activo: vig_activo,
        cam: "<% $cam %>"
      }
    });
    load_grids();
    return reset_params();
  };
  modify_row = function(e, grid, rowIndex, colIndex) {
    var row;
    row = grid.getStore().getAt(rowIndex);
    alert(row.get('pausa'));
    return alert(row.get('active'));
  };
  store_grid_test = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/vignette/get_grid',
    fields: [
      {
        name: 'usu'
      }, {
        name: 'code'
      }, {
        name: 'pausa'
      }, {
        name: 'active'
      }
    ]
  });
  store_grid_ante = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/vignette/get_grid',
    fields: [
      {
        name: 'usu'
      }, {
        name: 'code'
      }, {
        name: 'pausa'
      }, {
        name: 'active'
      }
    ]
  });
  store_grid_prod = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/vignette/get_grid',
    fields: [
      {
        name: 'usu'
      }, {
        name: 'code'
      }, {
        name: 'pausa'
      }, {
        name: 'active'
      }
    ]
  });
  store_entorno = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/vignette/get_entornos',
    fields: [
      {
        name: 'env'
      }
    ]
  });
  store_server = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/vignette/get_servers',
    fields: [
      {
        name: 'server'
      }
    ]
  });
  store_usuario = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/vignette/get_usuario_funcional',
    fields: [
      {
        name: 'user'
      }
    ]
  });
  store_entorno.on('load', function() {
    combo_entorno.setValue(this.getAt(0).get('env'));
    return c_entorno = this.getAt(0).get('env');
  });
  store_server.on('load', function() {
    combo_servidor.setValue(this.getAt(0).get('server'));
    return c_server = this.getAt(0).get('server');
  });
  store_usuario.on('load', function() {
    combo_usuario.setValue(this.getAt(0).get('user'));
    return c_user = this.getAt(0).get('user');
  });
  store_grid_test.on('load', function() {
    if (this.getCount() !== 0) {
      return fieldset_test.show();
    } else {
      return fieldset_test.hide();
    }
  });
  store_grid_ante.on('load', function() {
    if (this.getCount() !== 0) {
      return fieldset_ante.show();
    } else {
      return fieldset_ante.hide();
    }
  });
  store_grid_prod.on('load', function() {
    if (this.getCount() !== 0) {
      return fieldset_prod.show();
    } else {
      return fieldset_prod.hide();
    }
  });
  combo_entorno = new Ext.form.ComboBox({
    width: 400,
    mode: 'local',
    triggerAction: 'all',
    forceSelection: true,
    store: store_entorno,
    fieldLabel: 'Entorno',
    valueField: 'env',
    displayField: 'env',
    selectOnFocus: true,
    editable: false,
    listeners: {
      select: function() {
        c_entorno = this.getValue();
        return load_store_usuario();
      }
    }
  });
  combo_servidor = new Ext.form.ComboBox({
    width: 400,
    mode: 'local',
    triggerAction: 'all',
    forceSelection: true,
    store: store_server,
    fieldLabel: 'Servidor',
    valueField: 'server',
    displayField: 'server',
    selectOnFocus: true,
    editable: false,
    listeners: {
      select: function() {
        return c_server = this.getValue();
      }
    }
  });
  combo_usuario = new Ext.form.ComboBox({
    width: 400,
    mode: 'local',
    triggerAction: 'all',
    forceSelection: true,
    store: store_usuario,
    fieldLabel: 'Usuario Funcional',
    valueField: 'user',
    displayField: 'user',
    selectOnFocus: true,
    editable: false,
    listeners: {
      select: function() {
        return c_user = this.getValue();
      }
    }
  });
  txtfield_codigo = new Ext.form.TextField({
    fieldLabel: 'Codigo de la Accion'
  });
  checkbox_pause = new Ext.form.Checkbox({
    fieldLabel: 'Realizar pausa',
    checked: true
  });
  agregar = function() {
    ajax_vignette.request({
      url: '/form/vignette/add_row',
      method: 'POST',
      params: {
        vig_env: c_entorno,
        vig_maq: c_server,
        c_user: c_user,
        vig_pausa: checkbox_pause.getValue(),
        vig_accion: txtfield_codigo.getValue(),
        cam: "<% $cam %>"
      }
    });
    store_grid_test.load({
      params: {
        env: 'TEST',
        cam: "<% $cam %>"
      }
    });
    store_grid_ante.load({
      params: {
        env: 'ANTE',
        cam: "<% $cam %>"
      }
    });
    return store_grid_prod.load({
      params: {
        env: 'PROD',
        cam: "<% $cam %>"
      }
    });
  };
  handler_agregar = function() {
    var agregar_bool;
    agregar_bool = true;
    if (txtfield_codigo.getValue() === '') {
      alert('Falta rellenar el codigo de la accion');
      agregar_bool = false;
    }
    if (agregar_bool) {
      return agregar();
    }
  };
  handler_delete_test = function() {
    var vig_env;
    vig_env = 'TEST';
    return delete_row(vig_env);
  };
  handler_delete_ante = function() {
    var vig_env;
    vig_env = 'ANTE';
    return delete_row(vig_env);
  };
  handler_delete_prod = function() {
    var vig_env;
    vig_env = 'PROD';
    return delete_row(vig_env);
  };
  handler_upgrade_test = function() {
    var vig_env;
    vig_env = 'TEST';
    return raise_order(vig_env);
  };
  handler_upgrade_ante = function() {
    var vig_env;
    vig_env = 'ANTE';
    return raise_order(vig_env);
  };
  handler_upgrade_prod = function() {
    var vig_env;
    vig_env = 'PROD';
    return raise_order(vig_env);
  };
  handler_hola = function() {
    return alert('ok');
  };
  button_delete_test = new Ext.Button({
    text: 'Borrar',
    icon: '/static/images/icons/delete.png',
    handler: handler_delete_test
  });
  button_delete_ante = new Ext.Button({
    text: 'Borrar',
    icon: '/static/images/icons/delete.png',
    handler: handler_delete_ante
  });
  button_delete_prod = new Ext.Button({
    text: 'Borrar',
    icon: '/static/images/icons/delete.png',
    handler: handler_delete_prod
  });
  button_agregar = new Ext.Button({
    text: 'Agregar',
    icon: '/static/images/icons/add.png',
    handler: handler_agregar
  });
  button_upgrade_test = new Ext.Button({
    text: 'Subir orden',
    icon: '/static/images/silk/arrow_up.gif',
    handler: handler_upgrade_test
  });
  button_upgrade_ante = new Ext.Button({
    text: 'Subir orden',
    icon: '/static/images/silk/arrow_up.gif',
    handler: handler_upgrade_ante
  });
  button_upgrade_prod = new Ext.Button({
    text: 'Subir orden',
    icon: '/static/images/silk/arrow_up.gif',
    handler: handler_upgrade_prod
  });
  toolbar_grid_test = new Ext.Toolbar({
    autoHeight: true,
    autoWidth: true,
    items: [button_delete_test, button_upgrade_test]
  });
  toolbar_grid_ante = new Ext.Toolbar({
    autoHeight: true,
    autoWidth: true,
    items: [button_delete_ante, button_upgrade_ante]
  });
  toolbar_grid_prod = new Ext.Toolbar({
    autoHeight: true,
    autoWidth: true,
    items: [button_delete_prod, button_upgrade_prod]
  });
  column_usuario_test = new Ext.grid.Column({
    header: 'Usuario:Grupo@Nodo',
    width: 120,
    sortable: true,
    dataIndex: 'usu'
  });
  column_codigo_test = new Ext.grid.Column({
    header: 'Codigo de la accion',
    width: 120,
    sortable: true,
    dataIndex: 'code'
  });
  column_pausa_test = new Ext.grid.CheckColumn({
    header: 'Pausa',
    dataIndex: 'pausa',
    width: 40
  });
  column_activo_test = new Ext.grid.CheckColumn({
    header: 'Activo',
    dataIndex: 'active',
    width: 40
  });
  column_usuario_ante = new Ext.grid.Column({
    header: 'Usuario:Grupo@Nodo',
    width: 120,
    sortable: true,
    dataIndex: 'usu'
  });
  column_codigo_ante = new Ext.grid.Column({
    header: 'Codigo de la accion',
    width: 120,
    sortable: true,
    dataIndex: 'code'
  });
  column_pausa_ante = new Ext.grid.CheckColumn({
    header: 'Pausa',
    dataIndex: 'pausa',
    width: 40
  });
  column_activo_ante = new Ext.grid.CheckColumn({
    header: 'Activo',
    dataIndex: 'active',
    width: 40
  });
  column_usuario_prod = new Ext.grid.Column({
    header: 'Usuario:Grupo@Nodo',
    width: 120,
    sortable: true,
    dataIndex: 'usu'
  });
  column_codigo_prod = new Ext.grid.Column({
    header: 'Codigo de la accion',
    width: 120,
    sortable: true,
    dataIndex: 'code'
  });
  column_pausa_prod = new Ext.grid.CheckColumn({
    header: 'Pausa',
    dataIndex: 'pausa',
    width: 40
  });
  column_activo_prod = new Ext.grid.CheckColumn({
    header: 'Activo',
    dataIndex: 'active',
    width: 40
  });
  grid_test = new Ext.grid.GridPanel({
    label: 'TEST',
    hideLabel: true,
    autoWidth: true,
    autoHeight: true,
    store: store_grid_test,
    border: false,
    viewConfig: {
      forceFit: true
    },
    cm: new Ext.grid.ColumnModel([new Ext.grid.RowNumberer, column_usuario_test, column_codigo_test, column_pausa_test, column_activo_test])
  });
  grid_test.on('rowclick', function(grid, rowIndex, e) {
    var row;
    row = grid.getStore().getAt(rowIndex);
    usu = row.get('usu');
    vig_accion = row.get('code');
    vig_pausa = row.get('pausa');
    return vig_activo = row.get('active');
  });
  grid_ante = new Ext.grid.GridPanel({
    label: 'ANTE',
    hideLabel: true,
    autoWidth: true,
    autoHeight: true,
    store: store_grid_ante,
    border: false,
    viewConfig: {
      forceFit: true
    },
    cm: new Ext.grid.ColumnModel([new Ext.grid.RowNumberer, column_usuario_ante, column_codigo_ante, column_pausa_ante, column_activo_ante])
  });
  grid_ante.on('rowclick', function(grid, rowIndex, e) {
    var row;
    row = grid.getStore().getAt(rowIndex);
    usu = row.get('usu');
    vig_accion = row.get('code');
    vig_pausa = row.get('pausa');
    return vig_activo = row.get('active');
  });
  grid_prod = new Ext.grid.GridPanel({
    label: 'PROD',
    hideLabel: true,
    autoWidth: true,
    autoHeight: true,
    store: store_grid_prod,
    border: false,
    viewConfig: {
      forceFit: true
    },
    cm: new Ext.grid.ColumnModel([new Ext.grid.RowNumberer, column_usuario_prod, column_codigo_prod, column_pausa_prod, column_activo_prod])
  });
  grid_prod.on('rowclick', function(grid, rowIndex, e) {
    var row;
    row = grid.getStore().getAt(rowIndex);
    usu = row.get('usu');
    vig_accion = row.get('code');
    vig_pausa = row.get('pausa');
    return vig_activo = row.get('active');
  });
  fieldset_agregar = new Ext.form.FieldSet({
    title: 'Agregar nuevo elemento',
    autoHeight: true,
    items: [combo_entorno, combo_servidor, combo_usuario, checkbox_pause, txtfield_codigo, button_agregar]
  });
  fieldset_test = new Ext.form.FieldSet({
    title: 'Test',
    autoHeight: true,
    items: [toolbar_grid_test, grid_test],
    hide: true
  });
  fieldset_ante = new Ext.form.FieldSet({
    title: 'Ante',
    autoHeight: true,
    items: [toolbar_grid_ante, grid_ante]
  });
  fieldset_prod = new Ext.form.FieldSet({
    title: 'Prod',
    autoHeight: true,
    items: [toolbar_grid_prod, grid_prod]
  });
  fieldset_despliegue = new Ext.form.FieldSet({
    title: 'Despliegue de elementos',
    autoHeight: true,
    items: [fieldset_test, fieldset_ante, fieldset_prod]
  });
  form_vignette = new Ext.form.FormPanel({
    title: 'Formulario Vignette',
    items: [fieldset_agregar, fieldset_despliegue]
  });
  store_entorno.load();
  store_server.load({
    params: {
      cam: "<% $cam %>"
    }
  });
  load_store_usuario();
  load_grids();
  return form_vignette;
}).call(this);

<%args>
  $cam => $ARGS{cam}
  $fid => $ARGS{fid}
</%args>
