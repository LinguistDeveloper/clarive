(function(params){
    var data = params.data || {};

    var tpl = new Ext.XTemplate( '<tpl for="."><div class="x-combo-list-item"><span id="boot" style="background: transparent"><strong>{name}</strong> - ({description})</span></div></tpl>' );

    // var states_store = new Baseliner.JsonStore({ 
    //     id: 'id', 
    //     baseParams: {},
    //     root: 'data',
    //     autoLoad: true,
    //     url: '/job/states',
    //     fields: ['id','name'] 
    // });

    var tpl2 = new Ext.XTemplate( '<tpl for=".">{name}</tpl>' );

    var states = new Ext.ux.form.SuperBoxSelect({
        msgTarget: 'under',
        addNewDataOnBlur: true, 
        triggerAction: 'all',
        //store: states_store,
        mode: 'remote',
        fieldLabel: 'Estados',
        typeAhead: true,
        name: 'states',
        displayField: 'name',
        hiddenName: 'states',
        valueField: 'id',
        displayFieldTpl: tpl2,
        value: data.states,
        extraItemCls: 'x-tag'
     });

    // var states = new Ext.ux.form.SuperBoxSelect({
    //     fieldLabel: 'Estado',
    //     tpl: tpl,
    //     name: 'states',
    //     hiddenName: 'states',
    //     store: states_store,
    //     value: data['states'],
    //     singleMode: false
    // });

    var project_box_store = new Baseliner.store.UserProjects({ id: 'id', baseParams: {
        include_root: true, 
        collection: 'project',
        autoLoad: false
    } });

    var projects = new Baseliner.PagingProjects({
        fieldLabel: _('Sistemas'),
        tpl: tpl,
        name: 'projects',
        hiddenName: 'projects',
        //store: project_box_store,
        value: data['projects'],
        singleMode: false
    });

    var checkbox_inicio = new Baseliner.CBox({
        name: 'chk_inicio',
        checked: data && data[ 'chk_inicio' ]=='1'  ? true : false,
        default_value: false,
        anchor: '100%',
        width: '100%',
        hideLabel: true,
        style: 'margin-bottom3'
    });

    var checkbox_natures = new Baseliner.CBox({
        name: 'chk_natures',
        checked: data && data[ 'chk_natures' ]=='1'  ? true : false,
        default_value: false,
        anchor: '100%',
        width: '100%',
        hideLabel: true,
        style: 'margin-bottom3'
    });

    var natures = Baseliner.ci_box({ 
        name:'natures', 
        anchor:'100%', 
        fieldLabel:'Naturaleza', role:'Nature', 
        force_set_value: true, 
        value: data.natures,
        singleMode: false
    });

    var checkbox_natures_and = new Baseliner.CBox({
        fieldLabel: _('AND?'),
        name: 'chk_natures_and',
        checked: data && data[ 'chk_natures_and' ]=='1'  ? true : false,
        default_value: false,
        anchor: '100%',
        width: '100%',
        hideLabel: false,
        style: 'margin-bottom: 3px'
    });

    var bl = Baseliner.ci_box({ 
        name:'bl', 
        anchor:'100%', 
        fieldLabel:'Entornos', 
        "class":'BaselinerX::CI::bl',
        force_set_value: true, 
        value: data.bl,
        valueField: 'moniker',
        singleMode: false
    });

    var checkbox_bl = new Baseliner.CBox({
        name: 'chk_bl',
        checked: data && data[ 'chk_bl' ]=='1'  ? true : false,
        default_value: false,
        anchor: '100%',
        width: '100%',
        hideLabel: true,
        style: 'margin-bottom: 3px'
    });

    var checkbox_fin = new Baseliner.CBox({
        name: 'chk_fin',
        checked: data && data[ 'chk_fin' ]=='1'  ? true : false,
        default_value: false,
        anchor: '100%',
        width: '100%',
        hideLabel: true,
        style: 'margin-bottom: 3px'
    });

    var checkbox_projects = new Baseliner.CBox({
        name: 'chk_projects',
        checked: data && data[ 'chk_projects' ]=='1'  ? true : false,
        default_value: false,
        anchor: '100%',
        width: '100%',
        hideLabel: true,
        style: 'margin-bottom: 3px'
    });

    var checkbox_projects_and = new Baseliner.CBox({
        fieldLabel: _('AND?'),
        name: 'chk_projects_and',
        checked: data && data[ 'chk_projects_and' ]=='1'  ? true : false,
        default_value: false,
        anchor: '100%',
        width: '100%',
        hideLabel: false,
        style: 'margin-bottom: 3px'
    });

    var checkbox_projects = new Baseliner.CBox({
        name: 'chk_projects',
        checked: data && data[ 'chk_projects' ]=='1'  ? true : false,
        default_value: false,
        anchor: '100%',
        width: '100%',
        hideLabel: true,
        style: 'margin-bottom: 3px'
    });

    var checkbox_users = new Baseliner.CBox({
        name: 'chk_users',
        checked: data && data[ 'chk_users' ]=='1'  ? true : false,
        default_value: false,
        anchor: '100%',
        width: '100%',
        hideLabel: true,
        style: 'margin-bottom: 3px'
    });

    var checkbox_states = new Baseliner.CBox({
        name: 'chk_states',
        checked: data && data[ 'chk_states' ]=='1'  ? true : false,
        default_value: false,
        anchor: '100%',
        width: '100%',
        hideLabel: true,
        style: 'margin-bottom: 3px'
    });

    var users_store = new Baseliner.Topic.StoreUsers({
        autoLoad: true
    });
    
    var users = new Baseliner.model.Users({
        fieldLabel: 'Usuario',
        name: 'users',
        hiddenName: 'users',
        store: users_store,
        singleMode: false
    });

    return [
        { xtype:'panel', layout:'column', items:[
            {layout:'form', columnWidth: .02, items: checkbox_inicio},
            {layout:'form', columnWidth: .49, items:
                { xtype:'datefield', fieldLabel: _('Fecha inicio Desde'), anchor:'100%', format:'Y-m-d', name: 'fecha_inicio_desde', value: data.fecha_inicio_desde }},
            {layout:'form', columnWidth: .49, items:
                { xtype:'datefield', fieldLabel: _('Fecha inicio Hasta'), anchor:'100%', format:'Y-m-d', name: 'fecha_inicio_hasta', value: data.fecha_inicio_hasta }}
            ]
        },
        { xtype:'panel', layout:'column', items:[
            {layout:'form', columnWidth: .02, items: checkbox_fin},
            {layout:'form', columnWidth: .49, items:
                { xtype:'datefield', fieldLabel: _('Fecha fin Desde'), anchor:'100%', format:'Y-m-d', name: 'fecha_fin_desde', value: data.fecha_fin_desde }},
            {layout:'form', columnWidth: .49, items:
                { xtype:'datefield', fieldLabel: _('Fecha fin Hasta'), anchor:'100%', format:'Y-m-d', name: 'fecha_fin_hasta', value: data.fecha_fin_hasta }}
          ]
        },
        { xtype:'panel', layout:'column', items:[
            {layout:'form', columnWidth: .02, items: checkbox_bl},
            {layout:'form', columnWidth: .49, items: bl}
          ]
        },
        { xtype:'panel', layout:'column', items:[
            {layout:'form', columnWidth: .02, items: checkbox_projects},
            {layout:'form', columnWidth: .49, items: projects},
            {layout:'form', columnWidth: .15, items: checkbox_projects_and}
          ]
        },
        { xtype:'panel', layout:'column', items:[
            {layout:'form', columnWidth: .02, items: checkbox_natures},
            {layout:'form', columnWidth: .49, items: natures},
            {layout:'form', columnWidth: .15, items: checkbox_projects_and}
          ]
        },
        { xtype:'panel', layout:'column', items:[
            {layout:'form', columnWidth: .02, items: checkbox_users},
            {layout:'form', columnWidth: .49, items: users}
          ]
        },
        { xtype:'panel', layout:'column', items:[
            {layout:'form', columnWidth: .02, items: checkbox_states},
            {layout:'form', columnWidth: .49, items: states}
          ]
        }
        // { xtype:'panel', layout:'column', items:[
        //     {layout:'form', columnWidth: .02, items: checkbox_areas},
        //     {layout:'form', columnWidth: .49, items: areas}
        //   ]
        // }
        // ,
        // { xtype:'panel', layout:'column', items:[
        //     {layout:'form', columnWidth: .02, items: checkbox_status},
        //     {layout:'form', columnWidth: .49, items: [ { xtype: 'hidden', name: 'status', value: data.status : -1 },status]}
        //   ]
        // }
    ]
})
