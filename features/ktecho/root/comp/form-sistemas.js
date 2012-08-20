(function() {
  var REGEX_PERMISO, ajax_sist, button_delete, button_modificar, button_ver, change_text, check_is_catalogued, column_elemento, column_elemento_all, column_estado, column_modificado, column_owner, column_owner_all, column_package_all, column_permisos, column_permisos_all, column_ruta_all, column_ubicacion, combo_elemento, combo_owner, combo_width, current_versionobjid, fieldset_elementos, form_sistemas, grid_elementos, grid_elementos_all, is_catalogued, store_catalogued, store_current_versionobjid, store_grid_elementos, store_main, store_owner, store_paquete_sistemas, textfield_width, toolbar_elementos, txtfield_permisos, txtfield_ubicacion;
  combo_width = 400;
  textfield_width = 400;
  is_catalogued = false;
  current_versionobjid = '';
  REGEX_PERMISO = /^[0-9]{3,4}$/;
  ajax_sist = new Ext.data.Connection();
  store_catalogued = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/sistemas/check_is_catalogued',
    fields: [
      {
        name: 'value'
      }
    ]
  });
  check_is_catalogued = function(value) {
    return store_catalogued.load({
      params: {
        versionobjid: value
      }
    });
  };
  store_catalogued.on('load', function() {
    var value;
    value = this.getAt(0).get('value');
    if (value === 0) {
      is_catalogued = true;
    }
    if (value !== 0) {
      is_catalogued = false;
    }
    if (is_catalogued === false) {
      button_modificar.setText('Catalogar');
    }
    if (is_catalogued === true) {
      return button_modificar.setText('Modificar');
    }
  });
  store_main = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/sistemas/main_data',
    fields: [
      {
        name: 'elemento'
      }, {
        name: 'versionobjid'
      }, {
        name: 'sis_path'
      }, {
        name: 'sis_owner'
      }, {
        name: 'sis_permisos'
      }
    ]
  });
  store_main.on('load', function() {
    var c_elemento, c_owner;
    c_elemento = this.getAt(0).get('versionobjid');
    c_owner = this.getAt(0).get('sis_owner');
    txtfield_ubicacion.setValue(this.getAt(0).get('sis_path'));
    txtfield_permisos.setValue(this.getAt(0).get('sis_permisos'));
    combo_elemento.setValue(c_elemento);
    combo_owner(c_owner);
    return check_is_catalogued(c_elemento);
  });
  combo_elemento = new Ext.form.ComboBox({
    width: combo_width,
    mode: 'local',
    triggerAction: 'all',
    forceSelection: true,
    store: store_main,
    fieldLabel: 'Elemento',
    valueField: 'versionobjid',
    displayField: 'elemento',
    selectOnFocus: true,
    editable: false,
    listeners: {
      select: function() {
        var c_elemento;
        c_elemento = this.getValue();
        check_is_catalogued(c_elemento);
        return current_versionobjid = c_elemento;
      }
    }
  });
  txtfield_ubicacion = new Ext.form.TextField({
    fieldLabel: 'Ubicacion',
    width: textfield_width,
    disabled: false
  });
  store_owner = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/sistemas/get_owners',
    fields: [
      {
        name: 'owner'
      }
    ]
  });
  store_owner.on('load', function() {
    var c_owner;
    c_owner = this.getAt(0).get('owner');
    return combo_owner.setValue(c_owner);
  });
  combo_owner = new Ext.form.ComboBox({
    width: combo_width,
    mode: 'local',
    triggerAction: 'all',
    forceSelection: true,
    store: store_owner,
    fieldLabel: 'Owner',
    valueField: 'owner',
    displayField: 'owner',
    selectOnFocus: true,
    editable: false,
    listeners: {
      select: function() {
        var c_owner;
        return c_owner = this.getValue();
      }
    }
  });
  txtfield_permisos = new Ext.form.TextField({
    fieldLabel: 'Permisos',
    width: textfield_width,
    disabled: false
  });
  column_estado = new Ext.grid.Column({
    header: 'Estado',
    width: 120,
    sortable: true,
    dataIndex: 'versionstatus'
  });
  column_elemento = new Ext.grid.Column({
    header: 'Elemento',
    width: 120,
    sortable: true,
    dataIndex: 'elemento'
  });
  column_ubicacion = new Ext.grid.Column({
    header: 'Ubicacion',
    width: 120,
    sortable: true,
    dataIndex: 'sis_path'
  });
  column_owner = new Ext.grid.Column({
    header: 'Owner',
    width: 120,
    sortable: true,
    dataIndex: 'sis_owner'
  });
  column_permisos = new Ext.grid.Column({
    header: 'Permisos',
    width: 120,
    sortable: true,
    dataIndex: 'sis_permisos'
  });
  column_modificado = new Ext.grid.Column({
    header: 'Modificado',
    width: 120,
    sortable: true,
    dataIndex: 'modificado'
  });
  store_grid_elementos = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/sistemas/get_grid_data',
    fields: [
      {
        name: 'versionstatus'
      }, {
        name: 'elemento'
      }, {
        name: 'pathfullname'
      }, {
        name: 'sis_owner'
      }, {
        name: 'sis_permisos'
      }, {
        name: 'modificado'
      }, {
        name: 'versionobjid'
      }, {
        name: 'elemento_full'
      }, {
        name: 'packagename'
      }, {
        name: 'sis_path'
      }
    ]
  });
  grid_elementos = new Ext.grid.GridPanel({
    autoWidth: true,
    autoHeight: true,
    store: store_grid_elementos,
    border: false,
    autoSizeColumns: true,
    viewConfig: {
      forceFit: true
    },
    cm: new Ext.grid.ColumnModel([new Ext.grid.RowNumberer, column_estado, column_elemento, column_ubicacion, column_owner, column_permisos, column_modificado])
  });
  column_package_all = new Ext.grid.Column({
    header: 'Paquete',
    width: 120,
    sortable: true,
    dataIndex: 'packagename'
  });
  column_elemento_all = new Ext.grid.Column({
    header: 'Elemento',
    width: 120,
    sortable: true,
    dataIndex: 'elemento'
  });
  column_ruta_all = new Ext.grid.Column({
    header: 'Ruta',
    width: 120,
    sortable: true,
    dataIndex: 'pathfullname'
  });
  column_owner_all = new Ext.grid.Column({
    header: 'Owner',
    width: 120,
    sortable: true,
    dataIndex: 'sis_owner'
  });
  column_permisos_all = new Ext.grid.Column({
    header: 'Permisos',
    width: 120,
    sortable: true,
    dataIndex: 'sis_permisos'
  });
  grid_elementos_all = new Ext.grid.GridPanel({
    autoWidth: true,
    autoHeight: true,
    store: store_grid_elementos,
    border: false,
    viewConfig: {
      forceFit: true
    },
    cm: new Ext.grid.ColumnModel([new Ext.grid.RowNumberer, column_package_all, column_elemento_all, column_ruta_all, column_owner_all, column_permisos_all])
  });
  store_current_versionobjid = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/sistemas/get_versionobjid',
    fields: [
      {
        name: 'value'
      }
    ]
  });
  store_paquete_sistemas = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/sistemas/get_package_data',
    fields: [
      {
        name: 'id'
      }, {
        name: 'environmentname'
      }, {
        name: 'sis_cam'
      }, {
        name: 'sis_grp'
      }, {
        name: 'sis_owner'
      }, {
        name: 'sis_path'
      }, {
        name: 'sis_permisos'
      }, {
        name: 'sis_status'
      }, {
        name: 'sis_usr'
      }, {
        name: 'ts'
      }, {
        name: 'usrobjid'
      }, {
        name: 'versionobjid'
      }
    ]
  });
  store_paquete_sistemas.on('load', function() {
    var c_elemento;
    txtfield_permisos.setValue(this.getAt(0).get('sis_permisos'));
    txtfield_ubicacion.setValue(this.getAt(0).get('sis_path'));
    combo_owner.setValue(this.getAt(0).get('sis_owner'));
    return c_elemento = this.getAt(0).get('versionobjid');
  });
  grid_elementos.on('rowclick', function(grid, rowIndex, e) {
    var row;
    row = grid.getStore().getAt(rowIndex);
    current_versionobjid = row.get('versionobjid');
    store_paquete_sistemas.load({
      params: {
        versionobjid: current_versionobjid
      }
    });
    combo_elemento.setValue(row.get('elemento_full'));
    return button_modificar.setText('Modificar');
  });
  button_modificar = new Ext.Button({
    text: 'Modificar',
    handler: function() {
      if (REGEX_PERMISO.test(txtfield_permisos.getValue())) {
        ajax_sist.request({
          url: '/form/sistemas/catalog',
          method: 'POST',
          params: {
            versionobjid: current_versionobjid,
            sis_permisos: txtfield_permisos.getValue(),
            sis_path: txtfield_ubicacion.getValue(),
            sis_owner: combo_owner.getRawValue()
          }
        });
        return store_grid_elementos.load();
      } else {
        return alert('Permiso no valido');
      }
    }
  });
  change_text = function(button_text) {
    var texto;
    if (button_text === 'Ver todos los elementos catalogados') {
      texto = 'Ver elementos catalogados del paquete';
      grid_elementos.hide();
      grid_elementos_all.show();
    } else {
      texto = 'Ver todos los elementos catalogados';
      grid_elementos.show();
      grid_elementos_all.hide();
    }
    return button_ver.setText(texto);
  };
  button_ver = new Ext.Button({
    text: 'Ver todos los elementos catalogados',
    handler: function() {
      return change_text(this.text);
    }
  });
  button_delete = new Ext.Button({
    text: 'Borrar',
    icon: '/static/images/icons/delete.png',
    handler: function() {
      return ajax_sist.request({
        url: '/form/sistemas/delete_row',
        method: 'POST',
        params: {
          versionobjid: current_versionobjid
        }
      });
    }
  });
  store_grid_elementos.load();
  toolbar_elementos = new Ext.Toolbar({
    autoHeight: true,
    style: 'margin-top: 20px',
    autoWidth: true,
    items: [button_modificar, '-', button_ver, '-', button_delete]
  });
  fieldset_elementos = new Ext.form.FieldSet({
    title: 'Elementos',
    autoHeight: true,
    items: [combo_elemento, txtfield_ubicacion, combo_owner, txtfield_permisos, toolbar_elementos, grid_elementos, grid_elementos_all]
  });
  form_sistemas = new Ext.form.FormPanel({
    title: 'Formulario Sistemas',
    items: [fieldset_elementos]
  });
  store_main.load({
    params: {
      cam: "<% $cam %>"
    }
  });
  store_owner.load();
  store_grid_elementos.load();
  grid_elementos_all.hide();
  return form_sistemas;
}).call(this);

<%args>
  $cam => $ARGS{cam}
  $fid => $ARGS{fid}
</%args>
