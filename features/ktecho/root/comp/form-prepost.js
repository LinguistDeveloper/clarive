(function () {
  var env_name;
  var nature;
  var prepost;
  var server;
  var user;
  var btn_entorno; // La que se enviara al hacer click en delete
  var btn_naturaleza;
  var btn_prepost;
  var btn_exec;
  var btn_usumaq;
  var conn = new Ext.data.Connection(); // Conexion ajax
  // Variables de los combos para hacer inserts
  var insert_proyecto;
  var insert_naturaleza;
  var insert_prepost;
  var insert_servidor;
  var insert_usuario;
  var insert_bloquear;

  function query_params(env_name, prepost, nature, server, user) {
    combo_query_store.load({
      params: {
        env_name: env_name,
        prepost: prepost,
        nature: nature,
        server: server,
        user: user
      }
    });
  };

  function query_combo_server_params(env_name) {
    combo_server_store.load({
      params: {
        entorno: env_name,
        cam: "<% $cam %>"
      }
    });
  };

  function delete_row(text) {
    btn_entorno = text;
    conn.request({
      url: '/form/prepost/delete_row',
      method: 'POST',
      params: {
        p_entorno: btn_entorno,
        p_naturaleza: btn_naturaleza,
        p_prepost: btn_prepost,
        p_exec: btn_exec,
        p_usumaq: btn_usumaq,
        cam: "<% $cam %>"
      }
    });
    grid_test_store.load();
    grid_ante_store.load();
    grid_prod_store.load();
  };

  var txtfield_programa = new Ext.form.TextField({
    fieldLabel: 'Programa',
    value: '',
    disabled: false,
    width: 400
  });

  var combo_entorno_store = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: "totalCount",
    url: '/form/prepost/combo_entorno',
    fields: [{
      name: 'value'
    }, {
      name: 'show'
    }]
  });

  var combo_naturaleza_store = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: "totalCount",
    url: '/form/prepost/combo_naturaleza',
    fields: [{
      name: 'nat'
    }]
  });

  var combo_os_store = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: "totalCount",
    url: '/form/prepost/combo_os',
    fields: [{
      name: 'os'
    }]
  });

  var combo_prepost_store = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: "totalCount",
    url: '/form/prepost/combo_prepost',
    fields: [{
      name: 'value'
    }]
  });

  var combo_query_store = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: "totalCount",
    url: '/form/prepost/combo_query',
    fields: [{
      name: 'pp_maq'
    }, {
      name: 'pp_usu'
    }]
  });

  var combo_server_store = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: "totalCount",
    url: '/form/prepost/combo_server',
    fields: [{
      name: 'pp_maq'
    }]
  });

  var combo_block_store = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: "totalCount",
    url: '/form/prepost/combo_block',
    fields: [{
      name: 'value'
    }, {
      name: 'show'
    }]
  });

  var grid_test_store = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: "totalCount",
    url: '/form/prepost/grid_test',
    fields: [{
      name: 'pp_naturaleza'
    }, {
      name: 'pp_prepost'
    }, {
      name: 'pp_block'
    }, {
      name: 'pp_exec'
    }, {
      name: 'pp_activo'
    }, {
      name: 'pp_os'
    }, {
      name: 'pp_usumaq'
    }]
  });

  var grid_ante_store = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: "totalCount",
    url: '/form/prepost/grid_ante',
    fields: [{
      name: 'pp_naturaleza'
    }, {
      name: 'pp_prepost'
    }, {
      name: 'pp_block'
    }, {
      name: 'pp_exec'
    }, {
      name: 'pp_activo'
    }, {
      name: 'pp_os'
    }, {
      name: 'pp_usumaq'
    }]
  });

  var grid_prod_store = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: "totalCount",
    url: '/form/prepost/grid_prod',
    fields: [{
      name: 'pp_naturaleza'
    }, {
      name: 'pp_prepost'
    }, {
      name: 'pp_block'
    }, {
      name: 'pp_exec'
    }, {
      name: 'pp_activo'
    }, {
      name: 'pp_os'
    }, {
      name: 'pp_usumaq'
    }]
  });

  // Combo entorno
  var combo_entorno = new Ext.form.ComboBox({
    width: 400,
    mode: 'local',
    triggerAction: 'all',
    forceSelection: true,
    store: combo_entorno_store,
    fieldLabel: "Entorno",
    valueField: 'value',
    displayField: 'show',
    selectOnFocus: true,
    editable: false,
    hiddenName: 'c_env_val',
    submitValue: true,
    listeners: {
      select: function () {
        env_name = this.getValue();
        insert_proyecto = this.getValue();
        query_params(env_name, prepost, nature, server, user);
        query_combo_server_params(env_name);
      }
    }
  });

  // Combo naturaleza
  var combo_naturaleza = new Ext.form.ComboBox({
    width: 400,
    mode: 'local',
    triggerAction: 'all',
    forceSelection: true,
    store: combo_naturaleza_store,
    fieldLabel: "Naturaleza",
    valueField: 'nat',
    displayField: 'nat',
    selectOnFocus: true,
    editable: false,
    hiddenName: 'c_nat_val',
    submitValue: true,
    listeners: {
      select: function () {
        nature = this.getValue();
        insert_naturaleza = this.getValue();
        query_params(env_name, prepost, nature, server, user);
      }
    }
  });

  // Combo prepost
  var combo_prepost = new Ext.form.ComboBox({
    width: 400,
    mode: 'local',
    triggerAction: 'all',
    forceSelection: true,
    store: combo_prepost_store,
    fieldLabel: "Pre o Post",
    valueField: 'value',
    displayField: 'value',
    selectOnFocus: true,
    editable: false,
    hiddenName: 'c_pp_val',
    submitValue: true,
    listeners: {
      select: function () {
      	insert_prepost = this.getValue();
      }
    }
  });

  // Combo server
  var combo_server = new Ext.form.ComboBox({
    width: 400,
    mode: 'local',
    triggerAction: 'all',
    forceSelection: true,
    store: combo_server_store,
    fieldLabel: "Servidor",
    valueField: 'pp_maq',
    displayField: 'pp_maq',
    selectOnFocus: true,
    editable: false,
    hiddenName: 'c_srv_val',
    submitValue: true,
    listeners: {
      select: function () {
        server = this.getValue();
        insert_servidor = this.getValue();
      }
    }
  });

  var combo_os = new Ext.form.ComboBox({
    width: 400,
    mode: 'local',
    triggerAction: 'all',
    forceSelection: true,
    store: combo_os_store,
    fieldLabel: "Sistema Operativo",
    valueField: 'os',
    displayField: 'os',
    selectOnFocus: true,
    editable: false,
    hiddenName: 'os',
    submitValue: true,
    listeners: {
      select: function () {
        insert_so = this.getValue();
      }
    }
  });

  // Combo user
  var combo_user = new Ext.form.ComboBox({
    width: 400,
    mode: 'local',
    triggerAction: 'all',
    forceSelection: true,
    store: combo_query_store,
    fieldLabel: "Usuario Funcional",
    valueField: 'pp_usu',
    displayField: 'pp_usu',
    selectOnFocus: true,
    editable: false,
    hiddenName: 'c_usu_val',
    submitValue: true,
    listeners: {
      select: function () {
        user = this.getValue();
        insert_usuario = this.getValue();
        query_params(env_name, prepost, nature, server, user);
      }
    }
  });

  // Combo bloquea
  var combo_block = new Ext.form.ComboBox({
    width: 400,
    mode: 'local',
    triggerAction: 'all',
    forceSelection: true,
    store: combo_block_store,
    fieldLabel: "Bloquear Pase en caso de Error",
    valueField: 'value',
    displayField: 'show',
    selectOnFocus: true,
    editable: false,
    listeners: {
      select: function () {
        insert_bloquear = this.getValue();
      }
    }
  })

  // Columna naturaleza
  var column_nature = new Ext.grid.Column({
    header: 'Naturaleza',
    width: 120,
    sortable: true,
    dataIndex: 'pp_naturaleza'
  });

  // Columna Pre/Post
  var column_prepost = new Ext.grid.Column({
    header: 'Tipo',
    width: 120,
    sortable: true,
    dataIndex: 'pp_prepost'
  });

  // Columna usuario
  var column_user = new Ext.grid.Column({
    header: 'Usuario@Maq',
    width: 120,
    sortable: true,
    dataIndex: 'pp_usumaq'
  });

  // Columna Bloquea
  var column_block = new Ext.grid.Column({
    header: 'Bloquea',
    width: 120,
    sortable: true,
    dataIndex: 'pp_block'
  });

  // Columna Programa
  var column_exec = new Ext.grid.Column({
    header: 'Programa',
    width: 120,
    sortable: true,
    dataIndex: 'pp_exec'
  });

  var column_os = new Ext.grid.Column({
    header: 'Sistema Operativo',
    width: 120,
    sortable: true,
    dataIndex: 'pp_os'
  });

  // Evento al hacer click en el boton delete
  var delete_handler_test = function (btn) {
      delete_row('TEST');
      }
      
      
      
  var delete_handler_ante = function (btn) {
      delete_row('ANTE');
      }
      
      
      
  var delete_handler_prod = function (btn) {
      delete_row('PROD');
      }
      
      
      
  var handler_add = function () {
      conn.request({
        url: 'form/prepost/create_row',
        method: 'POST',
        params: {
          insert_proyecto: insert_proyecto,
          insert_naturaleza: insert_naturaleza,
          insert_prepost: insert_prepost,
          insert_servidor: insert_servidor,
          insert_usuario: insert_usuario,
          insert_bloquear: insert_bloquear,
          insert_so: insert_so,
          insert_programa: txtfield_programa.getValue(),
          cam: "<% $cam %>"
        }
      });
      grid_test_store.load();
      grid_ante_store.load();
      grid_prod_store.load();
      }
      
      
      
      // Boton delete
      
  var button_delete_test = new Ext.Button({
    text: 'Borrar',
    handler: delete_handler_test,
    icon: '/static/images/icons/delete.png'
  });

  var button_delete_ante = new Ext.Button({
    text: 'Borrar',
    handler: delete_handler_ante,
    icon: '/static/images/icons/delete.png'
  });

  var button_delete_prod = new Ext.Button({
    text: 'Borrar',
    handler: delete_handler_prod,
    icon: '/static/images/icons/delete.png'
  });

  var button_agregar = new Ext.Button({
    text: 'Agregar',
    handler: handler_add,
    icon: '/static/images/icons/add.png'
  });

  // Toolbar de test
  var toolbar_test = new Ext.Toolbar({
    autoWidth: true,
    autoHeight: true,
    items: ['Acciones: ', button_delete_test]
  });

  // Toolbar de ante
  var toolbar_ante = new Ext.Toolbar({
    autoWidth: true,
    autoHeight: true,
    items: ['Acciones: ', button_delete_ante]
  });

  // Toolbar de prod
  var toolbar_prod = new Ext.Toolbar({
    autoWidth: true,
    autoHeight: true,
    items: ['Acciones: ', button_delete_prod]
  });

  ////////////////////////////////////////////////////////////////////////////
  // FORM
  //
  var grid_test = new Ext.grid.GridPanel({
    autoHeight: true,
    border: false,
    selModel: new Ext.grid.RowSelectionModel({
      singleSelect: true
    }),
    viewConfig: {
      forceFit: true
    },
    store: grid_test_store,
    cm: new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(), column_nature, column_prepost, column_user, column_os, column_exec, column_block])
  });

  var grid_ante = new Ext.grid.GridPanel({
    autoHeight: true,
    border: false,
    selModel: new Ext.grid.RowSelectionModel({
      singleSelect: true
    }),
    viewConfig: {
      forceFit: true
    },
    store: grid_ante_store,
    cm: new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(), column_nature, column_prepost, column_user, column_os, column_exec, column_block])
  });

  var grid_prod = new Ext.grid.GridPanel({
    autoHeight: true,
    border: false,
    selModel: new Ext.grid.RowSelectionModel({
      singleSelect: true
    }),
    viewConfig: {
      forceFit: true
    },
    store: grid_prod_store,
    cm: new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(), column_nature, column_prepost, column_user, column_os, column_exec, column_block])
  });

  var form = new Ext.form.FormPanel({
    xtype: "form",
    title: "Formulario PrePost",
    items: [{
      xtype: "fieldset",
      autoHeight: true,
      title: "Agregar nuevo elemento",
      items: [combo_entorno, combo_naturaleza, combo_prepost, combo_server, combo_user, combo_os, combo_block, txtfield_programa, button_agregar]
    }, {
      xtype: "fieldset",
      autoHeight: true,
      title: "Test",
      items: [toolbar_test, grid_test]
    }, {
      xtype: "fieldset",
      autoHeight: true,
      title: "Ante",
      items: [toolbar_ante, grid_ante]
    }, {
      xtype: "fieldset",
      autoHeight: true,
      title: "Prod",
      items: [toolbar_prod, grid_prod]
    }],
    json: {
      size: {
        width: 1047,
        height: 568
      }
    }
  });

  grid_test.on('rowclick', function (grid, rowIndex, e) {
    var row = grid.getStore().getAt(rowIndex);
    btn_naturaleza = row.get("pp_naturaleza");
    btn_prepost = row.get("pp_prepost");
    btn_exec = row.get("pp_exec");
    btn_usumaq = row.get("pp_usumaq");
  });

  grid_ante.on('rowclick', function (grid, rowIndex, e) {
    var row = grid.getStore().getAt(rowIndex);
    btn_naturaleza = row.get("pp_naturaleza");
    btn_prepost = row.get("pp_prepost");
    btn_exec = row.get("pp_exec");
    btn_usumaq = row.get("pp_usumaq");
  });

  grid_prod.on('rowclick', function (grid, rowIndex, e) {
    var row = grid.getStore().getAt(rowIndex);
    btn_naturaleza = row.get("pp_naturaleza");
    btn_prepost = row.get("pp_prepost");
    btn_exec = row.get("pp_exec");
    btn_usumaq = row.get("pp_usumaq");
  });

  // Cargo los JsonStores...  algunos no me interesa cargarlos al iniciar el
  // formulario (daran errores falsos), sino que los cargo al hacer click en
  // alguno de los combobox
  combo_entorno_store.load();
  combo_naturaleza_store.load();
  combo_prepost_store.load();
  combo_block_store.load();
  combo_os_store.load();
  grid_test_store.load();
  grid_ante_store.load();
  grid_prod_store.load();

  // Llamo al formulario...
  return form;
}).call(this);

<%args>
  $cam => $ARGS{cam}
  $fid => $ARGS{fid}
</%args>
