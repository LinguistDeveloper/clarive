c_ciclo_vida = ''
c_cambio = ''
c_tipologia = ''
current_width = 400
width_button_form = 160
grow_max = 80
tiene_ante = ''
es_publica = ''
estado = ''
envobjid = ''
has_net_projects = ''
has_ora_projects = ''
has_vig_projects = ''
has_rs_projects = ''
has_sys_projects = ''
has_biz_projects = ''
paq_tipo = ''
pas_codigo = ''
entorno = ''
titulo = 'Formulario de Paquete'

ajax = new Ext.data.Connection()

store_main = new Ext.data.JsonStore
    root: 'data'
    remoteSort: true
    totalProperty: 'totalCount'
    url: '/form/main/get_main_data'
    fields: [
        { name: 'statename' }
        { name: 'username' }
        { name: 'environmentname' }
        { name: 'envobjid' }
        { name: 'es_publica' }
        { name: 'main_entornos' }
        { name: 'modifiedtime' }
        { name: 'formname' }
        { name: 'pas_codigo' }
        { name: 'paq_ciclo' }
        { name: 'paq_cambio' }
        { name: 'paq_observaciones' }
        { name: 'paq_inc' }
        { name: 'paq_pet' }
        { name: 'paq_pro' }
        { name: 'paq_comentario' }
        { name: 'paq_mant' }
        { name: 'paq_tipo' }
        { name: 'paq_desc' }
        { name: 'paq_usuario' }
        { name: 'tiene_ante' }
    ]

store_main.load()

hide_menu_pase = () ->
    unless pas_codigo?
        menu_log_pase.hide()
        menu_monitor_pase.hide()

store_main.on 'load', () ->
    tiene_ante = @getAt(0).get 'tiene_ante'
    es_publica = @getAt(0).get 'es_publica'
    estado = @getAt(0).get 'statename'
    envobjid = @getAt(0).get 'envobjid'
    paq_tipo = @getAt(0).get 'paq_tipo'
    pas_codigo = @getAt(0).get 'pas_codigo'
    entorno = @getAt(0).get 'environmentname'
    txtfield_modified_by.setValue @getAt(0).get 'paq_usuario'
    txtfield_modificado.setValue @getAt(0).get 'modifiedtime'
    textarea_motivo.setValue @getAt(0).get 'paq_mant'
    textarea_comentarios.setValue @getAt(0).get 'paq_comentario'
    textarea_descripcion.setValue @getAt(0).get 'paq_desc'
    textarea_observaciones.setValue @getAt(0).get 'paq_observaciones'
    txtfield_incidencia.setValue @getAt(0).get 'paq_inc'
    txtfield_peticion.setValue @getAt(0).get 'paq_pet'
    txtfield_proyecto.setValue @getAt(0).get 'paq_pro'
    label_codigo_pase.setText pas_codigo if pas_codigo?
    boton.menu.add menu_log_paquete if pas_codigo?
    boton.menu.add menu_monitor_pase if pas_codigo?
    store_natures.load
        params:
            envobjid: envobjid
    hide_menu_pase()

store_natures = new Ext.data.JsonStore
    root: 'data'
    remoteSort: true
    totalProperty: 'totalCount'
    url: '/form/main/get_natures'
    fields: [
        { name: 'has_net_projects' }
        { name: 'has_ora_projects' }
        { name: 'has_vig_projects' }
        { name: 'has_rs_projects' }
        { name: 'has_sys_projects' }
        { name: 'has_biz_projects' }
    ]

store_natures.on 'load', () ->
    has_net_projects = @getAt(0).get 'has_net_projects'
    button_net.show() if has_net_projects isnt 0
    has_ora_projects = @getAt(0).get 'has_ora_projects'
    button_ora.show() if has_ora_projects isnt 0
    has_vig_projects = @getAt(0).get 'has_vig_projects'
    button_vig.show() if has_vig_projects isnt 0
    has_rs_projects = @getAt(0).get 'has_rs_projects'
    button_rs.show() if has_rs_projects isnt 0
    has_sys_projects = @getAt(0).get 'has_sys_projects'
    button_sistemas.show() if has_sys_projects isnt 0
    has_biz_projects = @getAt(0).get 'has_biz_projects'
    button_biz.show() if has_biz_projects isnt 0
    store_combo_ciclo_vida.load
        params:
            has_sys_projects: has_sys_projects
            estado: estado
            es_publica: es_publica
    store_combo_tipologia.load
        params:
            has_sys_projects: has_sys_projects
            estado: estado
            paq_tipo: paq_tipo

store_combo_ciclo_vida = new Ext.data.JsonStore
    root: 'data'
    remoteSort: true
    totalProperty: 'totalCount'
    url: '/form/main/get_combo_ciclo_vida_data'
    fields: [
        { name: 'value' }
        { name: 'show' }
    ]

store_combo_ciclo_vida.on 'load', () ->
    temp = @getAt(0).get 'value'
    if temp is 'ex'
        combo_ciclo_vida.hide
    else
        combo_ciclo_vida.setValue @getAt(0).get 'show'
        c_ciclo_vida = @getAt(0).get 'value'

combo_ciclo_vida = new Ext.form.ComboBox
    width: current_width
    mode: 'local'
    triggerAction: 'all'
    forceSelection: true
    store: store_combo_ciclo_vida
    fieldLabel: 'Tipo de Ciclo de Vida'
    valueField: 'value'
    displayField: 'show'
    selectOnFocus: true
    editable: false
    listeners:
        select: () ->
            c_ciclo_vida = @getValue()

store_combo_cambio = new Ext.data.JsonStore
    root: 'data'
    remoteSort: true
    totalProperty: 'totalCount'
    url: '/form/main/get_combo_cambio_data'
    fields: [
        { name: 'value' }
        { name: 'show' }
    ]

store_combo_cambio.on 'load', () ->
    combo_cambio.setValue @getAt(0).get 'show'
    c_cambio = @getAt(0).get 'value'

combo_cambio = new Ext.form.ComboBox
    width: current_width
    mode: 'local'
    triggerAction: 'all'
    forceSelection: true
    store: store_combo_cambio
    fieldLabel: 'Tipo de Cambio'
    valueField: 'value'
    displayField: 'show'
    selectOnFocus: true
    editable: false
    listeners:
        select: () ->
            c_cambio = @getValue()

tipologia_action = () ->
    switch c_tipologia
        when 'Inc' then show_inc()
        when 'Pet' then show_pet()
        when 'Pro' then show_pro()
        when 'Man' then show_man()

hide_all = () ->
    textarea_motivo.hide()
    txtfield_incidencia.hide()
    button_incidencia.hide()
    txtfield_peticion.hide()
    txtfield_proyecto.hide()

show_inc = () ->
    # hide_all()
    txtfield_incidencia.show()
    button_incidencia.show()

show_pet = () ->
    # hide_all()
    txtfield_peticion.show()

show_pro = () ->
    # hide_all()
    txtfield_proyecto.show()

show_man = () ->
    # hide_all()
    textarea_motivo.show()

store_combo_tipologia = new Ext.data.JsonStore
    root: 'data'
    remoteSort: true
    totalProperty: 'totalCount'
    url: '/form/main/get_combo_tipologia_data'
    fields: [
        { name: 'value' }
    ]

store_combo_tipologia.on 'load', () ->
    temp = @getAt(0).get 'value'
    combo_tipologia.setValue temp
    c_tipologia = temp.substr(0,3)
    tipologia_action()

combo_tipologia = new Ext.form.ComboBox
    width: current_width
    mode: 'local'
    triggerAction: 'all'
    forceSelection: true
    store: store_combo_tipologia
    fieldLabel: 'Tipologia de Entrada'
    valueField: 'value'
    displayField: 'value'
    selectOnFocus: true
    editable: false
    listeners:
        select: () ->
            c_tipologia = @getValue().substr(0,3)
            tipologia_action()

textarea_motivo = new Ext.form.TextArea
    fieldLabel: 'Motivo del Mantenimiento'
    disabled: false
    width: current_width
    autoHeight: true
    grow: true
    growMax: grow_max
    store: store_main
    enableKeyEvents: true
    listeners:
        keydown: () ->
            button_save.show()

button_incidencia = new Ext.Button
    text: 'Despliegue Incidencias'
    style: 'margin-bottom: 10px; margin-left: 105px'
    icon: 'static/images/scm/icons/list_16.png'
    handler: () ->
        comp_url = 'form/main/load_inc'
        ptitle = titulo
        params = { cam: entorno }
        Baseliner.addNewWindowComp(comp_url, ptitle, params)

txtfield_incidencia = new Ext.form.TextField
    fieldLabel: 'Codigo de Incidencia'
    style: 'margin-top: 5px'
    disabled: false
    width: current_width
    enableKeyEvents: true
    listeners:
        keydown: () ->
            button_save.show()

txtfield_peticion = new Ext.form.TextField
    fieldLabel: 'Codigo de Peticion'
    style: 'margin-top: 5px'
    disabled: false
    width: current_width
    enableKeyEvents: true
    listeners:
        keydown: () ->
            button_save.show()

button_peticion = new Ext.Button
    text: 'Despliegue Peticiones'
    style: 'margin-bottom: 10px; margin-left: 105px'
    icon: 'static/images/scm/icons/list_16.png'
    handler: () ->
        comp_url = 'form/main/load_hsp'
        ptitle = titulo
        params = { tipo: '3' }
        Baseliner.addNewWindowComp(comp_url, ptitle, params)

txtfield_proyecto = new Ext.form.TextField
    fieldLabel: 'Codigo de Proyecto'
    style: 'margin-top: 5px'
    disabled: false
    width: current_width
    enableKeyEvents: true
    listeners:
        keydown: () ->
            button_save.show()

button_proyecto = new Ext.Button
    text: 'Despliegue Proyectos'
    style: 'margin-bottom: 10px; margin-left: 105px'
    icon: 'static/images/scm/icons/list_16.png'
    handler: () ->
        comp_url = 'form/main/load_hsp'
        ptitle = titulo
        params = { tipo: "1,2" }
        Baseliner.addNewWindowComp(comp_url, ptitle, params)

textarea_descripcion = new Ext.form.TextArea
    fieldLabel: 'Descripcion Interna'
    disabled: false
    width: current_width
    autoHeight: true
    grow: true
    growMax: grow_max
    store: store_main
    enableKeyEvents: true
    listeners:
        keydown: () ->
            button_save.show()

textarea_comentarios = new Ext.form.TextArea
    fieldLabel: 'Comentarios'
    disabled: false
    width: current_width
    grow: true
    growMax: grow_max
    store: store_main
    enableKeyEvents: true
    listeners:
        keydown: () ->
            button_save.show()

txtfield_modificado = new Ext.form.TextField
    fieldLabel: 'Ultima Modificacion'
    disabled: true
    width: current_width
    store: store_main

txtfield_modified_by = new Ext.form.TextField
    fieldLabel: 'Modificado por'
    disabled: true
    width: current_width
    store: store_main

save_changes = () ->
    ajax = new Ext.data.Connection().request
        url: '/form/main/update_textareas'
        method: 'POST'
        params:
            paq_mant: textarea_motivo.getValue()
            paq_desc: textarea_descripcion.getValue()
            paq_comentario: textarea_comentarios.getValue()
            paq_inc: txtfield_incidencia.getValue()
            paq_pet: txtfield_peticion.getValue()
            paq_pro: txtfield_proyecto.getValue()
    button_save.hide()

button_save = new Ext.Button
    text: 'Guardar cambios'
    icon: 'static/images/icons/database_refresh.png'
    handler: save_changes
    style: 'float: right; padding-right: 5px; padding-top: 10px'

fieldset_peticion = new Ext.form.FieldSet
    title: 'Peticion'
    autoHeight: true
    style: 'float: left; float: left'
    width: 530
    style: 'margin-left: 10px; margin-top: 10px'
    items: [
        combo_ciclo_vida
        combo_cambio
        combo_tipologia
        textarea_motivo
        textarea_descripcion
        txtfield_incidencia
        button_incidencia
        txtfield_peticion
        button_peticion
        txtfield_proyecto
        button_proyecto
        textarea_comentarios
        txtfield_modificado
        txtfield_modified_by
        button_save
    ]

label_codigo = new Ext.form.Label
    text: "Codigo: \xA0 \xA0"
    style: 'font-weight: bold'

label_codigo_pase = new Ext.form.Label
    text: 'No se ha realizado pase'

textarea_observaciones = new Ext.form.TextArea
    disabled: false
    hideLabel: true
    width: 500
    height: 300
    border: true
    enableKeyEvents: true
    listeners:
        focus: () ->
            @setValue '' if @getValue() is 'Observaciones...'
        blur: () ->
            if @getValue() is ''
                @setValue 'Observaciones...'
                handler_observaciones()
        keyup: () ->
            if @getValue() is ''
                button_observaciones_hide()
            else
                button_observaciones_show()

button_observaciones_show = () ->
    button_observaciones.show()
    weeeeee.show()

button_observaciones_hide = () ->
    button_observaciones.hide()
    weeeeee.hide()

handler_observaciones = () ->
    button_observaciones_hide()
    if textarea_observaciones isnt 'Observaciones...'
        ajax = new Ext.data.Connection().request
            url: '/form/main/update_textareas'
            method: 'POST'
            params:
                paq_observaciones: textarea_observaciones.getValue()
    else
        alert 'Nada que guardar'

button_observaciones = new Ext.Button
    text: 'Guardar cambios'
    icon: 'static/images/icons/database_refresh.png'
    handler: handler_observaciones

weeeeee = new Ext.Toolbar.Separator

menu_log_paquete =  {
                        text: 'Ver log de Paquete'
                        icon: 'static/images/package.gif'
                        handler: () ->
                            alert 'clicked!'
                    }

menu_infraestructure =  {
                             text: 'Ver Infraestructura de SCT'
                             handler: () ->
                                 alert 'boo!'
                        }

menu_consola_j2ee = {
                        text: 'Consola de Aplicaciones J2EE'
                        icon: 'static/images/icons/application_double.png'
                        handler: () ->
                            alert 'boo!'
                    }

menu_log_pase = {
                    text: 'Ver Log de Pase'
                    icon: 'static/images/log_i.gif'
                    handler: () ->
                        alert 'boo!'
                }

menu_monitor_pase = {
                        text: 'Ver Monitor de Pase'
                        icon: 'static/images/icons/television.png'
                        handler: () ->
                            alert 'boo!'
                    }

boton = new Ext.Toolbar.Button
    text: 'Acciones'
    menu: [
        menu_log_paquete
        menu_infraestructure
        menu_consola_j2ee
    ]

toolbar_pase = new Ext.Toolbar
    autoHeight: true
    width: textarea_observaciones.width
    items: [
        "\xA0"
        label_codigo
        label_codigo_pase
        "\xA0"
        "\xA0"
        {xtype: 'tbseparator'}
        "\xA0"
        "\xA0"
        boton
        "\xA0"
        "\xA0"
        weeeeee
        "\xA0"
        "\xA0"
        button_observaciones
    ]

label_codigo_info = new Ext.form.Label
    text: '\xA0 Codigo del Pase: \xA0'
    style: 'font-weight: bold'

label_texto_blablabla = new Ext.form.Label
    text: 'Codigo de referencia del ultimo pase al que pertenece este paquete.'

toolbar_pase_bottom = new Ext.Toolbar
    autoHeight: true
    width: 500
    items: [
        label_codigo_info
        label_texto_blablabla
    ]

fieldset_pase = new Ext.form.FieldSet
    title: 'Pase'
    autoHeight: true
    width: 530
    style: 'margin-left: 10px'
    items: [
        toolbar_pase
        textarea_observaciones
        toolbar_pase_bottom
    ]

button_net = new Ext.Button
    text: 'Formulario .NET'
    hidden: true
    width: width_button_form
    handler: () ->
        alert 'click!'

button_ora = new Ext.Button
    text: 'Formulario Oracle'
    hidden: true
    width: width_button_form
    handler: () ->
        alert 'click!'

button_biz = new Ext.Button
    text: 'Formulario Biztalk'
    hidden: true
    width: width_button_form
    handler: () ->
        alert 'click!'

button_rs = new Ext.Button
    text: 'Formulario Reporting Services'
    hidden: true
    width: width_button_form
    handler: () ->
        alert 'click!'

button_vig = new Ext.Button
    text: 'Formulario Vignette'
    hidden: true
    width: width_button_form
    handler: () ->
        alert 'click!'

button_prepost = new Ext.Button
    text: 'Formulario Pre / Post'
    hidden: true
    width: width_button_form
    handler: () ->
        alert 'click!'

button_sistemas = new Ext.Button
    text: 'Formulario Sistemas'
    hidden: true
    width: width_button_form
    handler: () ->
        alert 'click!'

fieldset_formularios = new Ext.form.FieldSet
    title: 'Otros formularios'
    autoHeight: true
    # style: 'float: left'
    width: 185
    items: [
        button_biz
        button_net
        button_ora
        button_prepost
        button_rs
        button_sistemas
        button_vig
    ]

form_main = new Ext.form.FormPanel
    title: 'title'
    items: [
        fieldset_peticion
        fieldset_formularios
        fieldset_pase
    ]

button_save.hide()
button_observaciones_hide()
store_combo_cambio.load()
# hide_all()

return form_main
