(function(params){
    var data = params.data || {};

    var tpl = new Ext.XTemplate( '<tpl for="."><div class="x-combo-list-item"><span id="boot" style="background: transparent"><strong>{name}</strong> - ({description})</span></div></tpl>' );

    var cb_date = new Baseliner.CBox({
        name: 'cb_date',
        checked: data && data[ 'cb_date' ]=='1'  ? true : false,
        default_value: false,
        anchor: '100%',
        width: '100%',
        hideLabel: true,
        style: 'margin-bottom3'
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

    var checkbox_categories = new Baseliner.CBox({
        name: 'chk_categories',
        checked: data && data[ 'chk_categories' ]=='1'  ? true : false,
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
    var ccategory = new Baseliner.CategoryBox({ name: 'categories', fieldLabel: _('Categories') });

    return [
        { xtype:'panel', layout:'column', items:[
            {layout:'form', columnWidth: .02, items: cb_date},
            {layout:'form', columnWidth: .49, items:
                { xtype:'datefield', fieldLabel: _('From date'), anchor:'100%', format:'Y-m-d', name: 'from_date', value: data.from_date }},
            {layout:'form', columnWidth: .49, items:
                { xtype:'datefield', fieldLabel: _('To date'), anchor:'100%', format:'Y-m-d', name: 'to_date', value: data.to_date }}
            ]
        },
        { xtype:'panel', layout:'column', items:[
            {layout:'form', columnWidth: .02, items: checkbox_users},
            {layout:'form', columnWidth: .49, items: users}
          ]
        },
        { xtype:'panel', layout:'column', items:[
            {layout:'form', columnWidth: .02, items: checkbox_categories},
            {layout:'form', columnWidth: .98, items:ccategory}
          ]
        }
    ]
})
