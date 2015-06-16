<%args>
    $perm_catalog => ''
</%args>

(function(params){
    var permCatalog =  Ext.util.JSON.decode('<% $perm_catalog %>');

    var panel,
        config_catalog = {
            height: 450,
            tab_icon: '/static/images/icons/catalog.png',
            title: _('Catalog'),
            perm_bdone : permCatalog['action.catalog.request']
        };

    if (Baseliner.Catalog_Class) {
        eval( "var class_name = " + Baseliner.Catalog_Class + ";" );
        panel = new class_name(config_catalog);
    } else {
        panel = new Baseliner.Catalog(config_catalog);
    }

    return panel;    
})
