(function() {
  var ajax, boton, button_biz, button_incidencia, button_net, button_observaciones, button_observaciones_hide,
    button_observaciones_show, button_ora, button_peticion, button_prepost, button_proyecto, button_rs,
    button_save, button_sistemas, button_vig, c_cambio, c_ciclo_vida, c_tipologia, combo_cambio,
    combo_ciclo_vida, combo_tipologia, current_width, entorno, envobjid, es_publica, estado, 
    fieldset_formularios, fieldset_pase, fieldset_peticion, form_main, grow_max, handler_observaciones, 
    has_biz_projects, has_net_projects, has_ora_projects, has_rs_projects, has_sys_projects, has_vig_projects, 
    hide_all, hide_menu_pase, label_codigo, label_codigo_info, label_codigo_pase, label_texto_blablabla, 
    menu_consola_j2ee, menu_infraestructure, menu_log_paquete, menu_log_pase, menu_monitor_pase, paq_tipo, 
    pas_codigo, save_changes, show_inc, show_man, show_pet, show_pro, store_combo_cambio, 
    store_combo_ciclo_vida, store_combo_tipologia, store_main, store_natures, textarea_comentarios, 
    textarea_descripcion, textarea_motivo, textarea_observaciones, tiene_ante, tipologia_action, titulo, 
    toolbar_pase, toolbar_pase_bottom, txtfield_incidencia, txtfield_modificado, txtfield_modified_by, 
    txtfield_peticion, txtfield_proyecto, weeeeee, width_button_form, paq_ciclo;
  paq_ciclo = '';
  c_ciclo_vida = '';
  c_cambio = '';
  c_tipologia = '';
  current_width = 400;
  //width_button_form = 160;
  width_button_form = 400;
  grow_max = 80;
  tiene_ante = '';
  es_publica = '';
  estado = '';
  envobjid = '';
  has_net_projects = '';
  has_ora_projects = '';
  has_vig_projects = '';
  has_rs_projects = '';
  has_sys_projects = '';
  has_biz_projects = '';
  paq_tipo = '';
  pas_codigo = '';
  entorno = "<% $cam %>";  // just in case it's not loading correctly !!
  titulo = 'Formulario de Paquete';
  ajax = new Ext.data.Connection();
  store_main = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/main/get_main_data',
    fields: [
      {
        name: 'statename'
      }, {
        name: 'username'
      }, {
        name: 'environmentname'
      }, {
        name: 'envobjid'
      }, {
        name: 'es_publica'
      }, {
        name: 'main_entornos'
      }, {
        name: 'modifiedtime'
      }, {
        name: 'formname'
      }, {
        name: 'pas_codigo'
      }, {
        name: 'paq_ciclo'
      }, {
        name: 'paq_cambio'
      }, {
        name: 'paq_observaciones'
      }, {
        name: 'paq_inc'
      }, {
        name: 'paq_pet'
      }, {
        name: 'paq_pro'
      }, {
        name: 'paq_comentario'
      }, {
        name: 'paq_mant'
      }, {
        name: 'paq_tipo'
      }, {
        name: 'paq_desc'
      }, {
        name: 'paq_usuario'
      }, {
        name: 'tiene_ante'
      }
    ]
  });
  store_main.load({
    params: {
      fid: "<% $fid %>",
      cam: "<% $cam %>"
    }
  });
  // // menu_log_pase.hide is not a function
  // hide_menu_pase = function() {
  //   if (pas_codigo == null) {
  //     menu_log_pase.hide();
  //     return;
  //   }
  // };
  store_main.on('load', function() {
    tiene_ante = this.getAt(0).get('tiene_ante');
    es_publica = this.getAt(0).get('es_publica');
    estado = this.getAt(0).get('statename');
    envobjid = this.getAt(0).get('envobjid');
    paq_tipo = this.getAt(0).get('paq_tipo');
    pas_codigo = this.getAt(0).get('pas_codigo');
    entorno = this.getAt(0).get('environmentname');
    txtfield_modified_by.setValue(this.getAt(0).get('paq_usuario'));
    txtfield_modificado.setValue(this.getAt(0).get('modifiedtime'));
    textarea_motivo.setValue(this.getAt(0).get('paq_mant'));
    textarea_comentarios.setValue(this.getAt(0).get('paq_comentario'));
    textarea_descripcion.setValue(this.getAt(0).get('paq_desc'));
    textarea_observaciones.setValue(this.getAt(0).get('paq_observaciones'));
    txtfield_incidencia.setValue(this.getAt(0).get('paq_inc'));
    txtfield_peticion.setValue(this.getAt(0).get('paq_pet'));
    txtfield_proyecto.setValue(this.getAt(0).get('paq_pro'));
    if (pas_codigo != null) {
      label_codigo_pase.setText(pas_codigo);
    }
    if (pas_codigo != null) {
      boton.menu.add(menu_log_paquete);
    }
    if (pas_codigo != null) {
      boton.menu.add(menu_monitor_pase);
    }
    store_natures.load({
      params: {
        envobjid: envobjid,
        cam: "<% $cam %>"
      }
    });
    // return hide_menu_pase();  // menu_log_pase.hide is not a function
  });
  store_natures = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/main/get_natures',
    fields: [
      {
        name: 'has_net_projects'
      }, {
        name: 'has_ora_projects'
      }, {
        name: 'has_vig_projects'
      }, {
        name: 'has_rs_projects'
      }, {
        name: 'has_sys_projects'
      }, {
        name: 'has_biz_projects'
      }
    ]
  });
  store_natures.on('load', function() {
    has_net_projects = this.getAt(0).get('has_net_projects');
    if (has_net_projects !== 0) {
      button_net.show();
    }
    has_ora_projects = this.getAt(0).get('has_ora_projects');
    if (has_ora_projects !== 0) {
      button_ora.show();
    }
    has_vig_projects = this.getAt(0).get('has_vig_projects');
    if (has_vig_projects !== 0) {
      button_vig.show();
    }
    has_rs_projects = this.getAt(0).get('has_rs_projects');
    if (has_rs_projects !== 0) {
      button_rs.show();
    }
    has_sys_projects = this.getAt(0).get('has_sys_projects');
    if (has_sys_projects !== 0) {
      button_sistemas.show();
    }
    has_biz_projects = this.getAt(0).get('has_biz_projects');
    if (has_biz_projects !== 0) {
      button_biz.show();
    }
    store_combo_ciclo_vida.load({
      params: {
        has_sys_projects: has_sys_projects,
        estado: estado,
        es_publica: es_publica,
        cam: "<% $cam %>",
        paq_ciclo: paq_ciclo
      }
    });
    return store_combo_tipologia.load({
      params: {
        has_sys_projects: has_sys_projects,
        estado: estado,
        paq_tipo: paq_tipo
      }
    });
  });
  store_combo_ciclo_vida = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/main/get_combo_ciclo_vida_data',
    fields: [
      {
        name: 'value'
      }, {
        name: 'show'
      }
    ]
  });
  store_combo_ciclo_vida.on('load', function() {
    var temp;
    temp = this.getAt(0).get('value');
    if (temp === 'ex') {
      return combo_ciclo_vida.hide;
    } else {
      combo_ciclo_vida.setValue(this.getAt(0).get('show'));
      return c_ciclo_vida = this.getAt(0).get('value');
    }
  });
  combo_ciclo_vida = new Ext.form.ComboBox({
    width: current_width,
    mode: 'local',
    triggerAction: 'all',
    // forceSelection: true,
    store: store_combo_ciclo_vida,
    fieldLabel: 'Tipo de Ciclo de Vida',
    valueField: 'value',
    displayField: 'show',
    selectOnFocus: true,
    editable: false,
    listeners: {
      select: function() {
        return c_ciclo_vida = this.getValue();
      }
    }
  });
  store_combo_cambio = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/main/get_combo_cambio_data',
    fields: [
      {
        name: 'value'
      }, {
        name: 'show'
      }
    ]
  });
  store_combo_cambio.on('load', function() {
    combo_cambio.setValue(this.getAt(0).get('show'));
    return c_cambio = this.getAt(0).get('value');
  });
  combo_cambio = new Ext.form.ComboBox({
    width: current_width,
    mode: 'local',
    triggerAction: 'all',
    // forceSelection: true,
    store: store_combo_cambio,
    fieldLabel: 'Tipo de Cambio',
    valueField: 'value',
    displayField: 'show',
    selectOnFocus: true,
    editable: false,
    listeners: {
      select: function() {
        return c_cambio = this.getValue();
      }
    }
  });
  tipologia_action = function() {
    switch (c_tipologia) {
      case 'Inc':
        return show_inc();
      case 'Pet':
        return show_pet();
      case 'Pro':
        return show_pro();
      case 'Man':
        return show_man();
    }
  };
  hide_all = function() {
    textarea_motivo.hide();
    button_incidencia.hide();
    txtfield_incidencia.hide();
    txtfield_peticion.hide();
    txtfield_proyecto.hide();
    return;
  };
  show_inc = function() {
    txtfield_incidencia.show();
    return button_incidencia.show();
  };
  show_pet = function() {
    return txtfield_peticion.show();
  };
  show_pro = function() {
    return txtfield_proyecto.show();
  };
  show_man = function() {
    return textarea_motivo.show();
  };
  store_combo_tipologia = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/form/main/get_combo_tipologia_data',
    fields: [
      {
        name: 'value'
      }
    ]
  });
  store_combo_tipologia.on('load', function() {
    var temp;
    temp = this.getAt(0).get('value');
    combo_tipologia.setValue(temp);
    c_tipologia = temp.substr(0, 3);
    return tipologia_action();
  });
  combo_tipologia = new Ext.form.ComboBox({
    width: current_width,
    mode: 'local',
    triggerAction: 'all',
    // forceSelection: true,
    store: store_combo_tipologia,
    fieldLabel: 'Tipologia de Entrada',
    valueField: 'value',
    displayField: 'value',
    selectOnFocus: true,
    editable: false,
    listeners: {
      select: function() {
        c_tipologia = this.getValue().substr(0, 3);
        return tipologia_action();
      }
    }
  });
  textarea_motivo = new Ext.form.TextArea({
    fieldLabel: 'Motivo del Mantenimiento',
    disabled: false,
    width: current_width,
    autoHeight: true,
    grow: true,
    growMax: grow_max,
    store: store_main,
    enableKeyEvents: true,
    listeners: {
      keydown: function() {
        return button_save.show();
      }
    }
  });
  button_incidencia = new Ext.Button({
    text: 'Despliegue Incidencias',
    style: 'margin-bottom: 10px; margin-left: 105px',
    icon: 'static/images/scm/icons/list_16.png',
    hidden: true,
    handler: function() {
      return Baseliner.addNewWindowComp("/form/main/load_inc", "Incidencias", {params: {cam: "<% $cam %>"}});
    }
  });
  txtfield_incidencia = new Ext.form.TextField({
    fieldLabel: 'Codigo de Incidencia',
    style: 'margin-top: 5px',
    disabled: false,
    width: current_width,
    enableKeyEvents: true,
    listeners: {
      keydown: function() {
        return button_save.show();
      }
    }
  });
  txtfield_peticion = new Ext.form.TextField({
    fieldLabel: 'Codigo de Peticion',
    style: 'margin-top: 5px',
    disabled: false,
    width: current_width,
    enableKeyEvents: true,
    listeners: {
      keydown: function() {
        return button_save.show();
      }
    }
  });
  button_peticion = new Ext.Button({
    text: 'Despliegue Peticiones',
    style: 'margin-bottom: 10px; margin-left: 105px',
    icon: 'static/images/scm/icons/list_16.png',
    hidden: true,
    handler: function() {
      var comp_url, params, ptitle;
      comp_url = 'form/main/load_hsp';
      ptitle = titulo;
      params = {
        tipo: '3'
      };
      return Baseliner.addNewWindowComp(comp_url, ptitle, params);
    }
  });
  txtfield_proyecto = new Ext.form.TextField({
    fieldLabel: 'Codigo de Proyecto',
    style: 'margin-top: 5px',
    disabled: false,
    width: current_width,
    enableKeyEvents: true,
    listeners: {
      keydown: function() {
        return button_save.show();
      }
    }
  });
  button_proyecto = new Ext.Button({
    text: 'Despliegue Proyectos',
    style: 'margin-bottom: 10px; margin-left: 105px',
    icon: 'static/images/scm/icons/list_16.png',
    hidden: true,
    handler: function() {
      var comp_url, params, ptitle;
      comp_url = 'form/main/load_hsp';
      ptitle = titulo;
      params = {
        tipo: "1,2"
      };
      return Baseliner.addNewWindowComp(comp_url, ptitle, params);
    }
  });
  textarea_descripcion = new Ext.form.TextArea({
    fieldLabel: 'Descripcion Interna',
    disabled: false,
    width: current_width,
    autoHeight: true,
    grow: true,
    growMax: grow_max,
    store: store_main,
    enableKeyEvents: true,
    listeners: {
      keydown: function() {
        return button_save.show();
      }
    }
  });
  textarea_comentarios = new Ext.form.TextArea({
    fieldLabel: 'Comentarios',
    disabled: false,
    width: current_width,
    grow: true,
    growMax: grow_max,
    store: store_main,
    enableKeyEvents: true,
    listeners: {
      keydown: function() {
        return button_save.show();
      }
    }
  });
  txtfield_modificado = new Ext.form.TextField({
    fieldLabel: 'Ultima Modificacion',
    disabled: true,
    width: current_width,
    store: store_main
  });
  txtfield_modified_by = new Ext.form.TextField({
    fieldLabel: 'Modificado por',
    disabled: true,
    width: current_width,
    store: store_main
  });
  save_changes = function() {
    ajax = new Ext.data.Connection().request({
      url: '/form/main/update_textareas',
      method: 'POST',
      params: {
        paq_mant: textarea_motivo.getValue(),
        paq_desc: textarea_descripcion.getValue(),
        paq_comentario: textarea_comentarios.getValue(),
        paq_inc: txtfield_incidencia.getValue(),
        paq_pet: txtfield_peticion.getValue(),
        paq_pro: txtfield_proyecto.getValue()
      }
    });
    return button_save.hide();
  };
  button_save = new Ext.Button({
    text: 'Guardar cambios',
    icon: 'static/images/icons/database_refresh.png',
    handler: save_changes,
    style: 'float: right; padding-right: 5px; padding-top: 10px'
  });
  fieldset_peticion = new Ext.form.FieldSet({
    title: 'Peticion',
    autoHeight: true,
    //style: 'float: left; float: left',
    width: 530,
    style: 'margin-left: 10px; margin-top: 10px',
    items: [combo_ciclo_vida, combo_cambio, combo_tipologia, textarea_motivo, textarea_descripcion, txtfield_incidencia, button_incidencia, txtfield_peticion, button_peticion, txtfield_proyecto, button_proyecto, textarea_comentarios, txtfield_modificado, txtfield_modified_by, button_save]
  });
  label_codigo = new Ext.form.Label({
    text: "Codigo: \xA0 \xA0",
    style: 'font-weight: bold'
  });
  label_codigo_pase = new Ext.form.Label({
    text: 'No se ha realizado pase'
  });
  textarea_observaciones = new Ext.form.TextArea({
    disabled: false,
    hideLabel: true,
    width: 500,
    height: 300,
    border: true,
    enableKeyEvents: true,
    listeners: {
      focus: function() {
        if (this.getValue() === 'Observaciones...') {
          return this.setValue('');
        }
      },
      blur: function() {
        if (this.getValue() === '') {
          this.setValue('Observaciones...');
          return handler_observaciones();
        }
      },
      keyup: function() {
        if (this.getValue() === '') {
          return button_observaciones_hide();
        } else {
          return button_observaciones_show();
        }
      }
    }
  });
  button_observaciones_show = function() {
    button_observaciones.show();
    return weeeeee.show();
  };
  button_observaciones_hide = function() {
    button_observaciones.hide();
    return weeeeee.hide();
  };
  handler_observaciones = function() {
    button_observaciones_hide();
    if (textarea_observaciones !== 'Observaciones...') {
      return ajax = new Ext.data.Connection().request({
        url: '/form/main/update_textareas',
        method: 'POST',
        params: {
          paq_observaciones: textarea_observaciones.getValue()
        }
      });
    } else {
      return alert('Nada que guardar');
    }
  };
  button_observaciones = new Ext.Button({
    text: 'Guardar cambios',
    icon: 'static/images/icons/database_refresh.png',
    handler: handler_observaciones
  });
  weeeeee = new Ext.Toolbar.Separator;
  menu_log_paquete = {
    text: 'Ver log de Paquete',
    icon: 'static/images/package.gif',
    handler: function() {
      return alert('clicked!');
    }
  };
  menu_infraestructure = {
    text: 'Ver Infraestructura de SCT',
    handler: function() {
      return alert('click!');
    }
  };
  menu_consola_j2ee = {
    text: 'Consola de Aplicaciones J2EE',
    icon: 'static/images/icons/application_double.png',
    handler: function() {
      return alert('click!');
    }
  };
  menu_log_pase = {
    text: 'Ver Log de Pase',
    icon: 'static/images/log_i.gif',
    handler: function() {
      return alert('click!');
    }
  };
  menu_monitor_pase = {
    text: 'Ver Monitor de Pase',
    icon: 'static/images/icons/television.png',
    handler: function() {
      return alert('click!');
    }
  };
  boton = new Ext.Toolbar.Button({
    text: 'Acciones',
    menu: [menu_log_paquete, menu_infraestructure, menu_consola_j2ee]
  });
  toolbar_pase = new Ext.Toolbar({
    autoHeight: true,
    width: textarea_observaciones.width,
    items: [
      "\xA0", label_codigo, label_codigo_pase, "\xA0", "\xA0", {
        xtype: 'tbseparator'
      }, "\xA0", "\xA0", boton, "\xA0", "\xA0", weeeeee, "\xA0", "\xA0", button_observaciones
    ]
  });
  label_codigo_info = new Ext.form.Label({
    text: '\xA0 Código del Pase: \xA0',
    style: 'font-weight: bold'
  });
  label_texto_blablabla = new Ext.form.Label({
    text: 'Codigo de referencia del ultimo pase al que pertenece este paquete.'
  });
  toolbar_pase_bottom = new Ext.Toolbar({
    autoHeight: true,
    width: 500,
    items: [label_codigo_info, label_texto_blablabla]
  });
  fieldset_pase = new Ext.form.FieldSet({
    title: 'Pase',
    autoHeight: true,
    width: 530,
    style: 'margin-left: 10px',
    items: [toolbar_pase, textarea_observaciones, toolbar_pase_bottom]
  });
  button_net = new Ext.Button({
    text: 'Formulario .NET',
    hidden: true,
    width: width_button_form,
    handler: function() {
      return Baseliner.addNewTabComp("/form/netprojects", "Proyectos .NET", {params: {fid: "<% $fid %>"}});
    }
  });
  button_ora = new Ext.Button({
    text: 'Formulario Oracle',
    hidden: true,
    width: width_button_form,
    handler: function() {
      return Baseliner.addNewTabComp("/form/oraprojects/cargar_prueba", "Proyectos Oracle", {params: {fid: "<% $fid %>"}});
    }
  });
  button_biz = new Ext.Button({
    text: 'Formulario Biztalk',
    hidden: true,
    width: width_button_form,
    handler: function() {
      return Baseliner.addNewTabComp("/form/bizprojects", "Proyectos Biztalk", {params: {fid: "<% $fid %>"}});
    }
  });
  button_rs = new Ext.Button({
    text: 'Formulario Reporting Services',
    hidden: true,
    width: width_button_form,
    handler: function() {
      return Baseliner.addNewTabComp("/form/reportingservices", "Proyectos RS", {params: {fid: "<% $fid %>"}});
    }
  });
  button_vig = new Ext.Button({
    text: 'Formulario Vignette',
    hidden: true,
    width: width_button_form,
    handler: function() {
      return Baseliner.addNewTabComp("/form/vignette", "Proyectos Vignette", {params: {fid: "<% $fid %>"}});
    }
  });
  button_prepost = new Ext.Button({
    text: 'Formulario Pre / Post',
    hidden: true,
    width: width_button_form,
    handler: function() {
      return Baseliner.addNewTabComp("/form/prepost/load_extjs", "Scripts PRE/POST", {params: {fid: "<% $fid %>"}});
    }
  });
  button_sistemas = new Ext.Button({
    text: 'Formulario Sistemas',
    hidden: true,
    width: width_button_form,
    handler: function() {
      return Baseliner.addNewTabComp("/form/sistemas", "Formulario Sistemas", {params: {fid: "<% $fid %>"}});
    }
  });
  fieldset_formularios = new Ext.form.FieldSet({
    title: 'Otros formularios',
    style: 'margin-left: 10px',
    autoHeight: true,
    //width: 185,
    width: 530,
    items: [button_biz, button_net, button_ora, button_prepost, button_rs, button_sistemas, button_vig]
  });
  form_main = new Ext.form.FormPanel({
    title: 'title',
    items: [fieldset_peticion, fieldset_formularios, fieldset_pase]
  });
  button_save.hide();
  button_observaciones_hide();
  store_combo_cambio.load();
  hide_all();
  return form_main;
}).call(this);

<%args>
    $cam => $ARGS{cam}
    $fid => $ARGS{fid}
</%args>
