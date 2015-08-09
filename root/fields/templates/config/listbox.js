(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);




    var html = new Ext.form.Hidden({ name:'html', value: data.html });
    var js = new Ext.form.Hidden({ name:'js', value: data.js });
    var type = new Ext.form.Hidden({ name:'type', value: 'listbox' });
    var set_method = new Ext.form.Hidden({ name:'set_method', value: data.set_method });
    var get_method = new Ext.form.Hidden({ name:'get_method', value: data.get_method });
    var list_type = new Ext.form.Hidden({ name:'list_type', value: data.list_type });
    var relation = new Ext.form.Hidden({ name:'relation', value: data.relation });
    var collection = new Ext.form.Hidden({ name:'collection', value: data.collection });
    var meta_type = new Ext.form.Hidden({ name:'meta_type', value: data.meta_type });

    var single_mode = new Ext.form.Hidden({ name:'color' });
    var include_root = new Ext.form.Hidden({ name:'color' });
    var roles = new Ext.form.Hidden({ name:'color' });
    var tree_level = new Ext.form.Hidden({ name:'color' });
    var branch = new Ext.form.Hidden({ name:'color' });
    var height = new Ext.form.Hidden({ name:'color' });
    var page_size = new Ext.form.Hidden({ name:'color' });
    var parent_field = new Ext.form.Hidden({ name:'color' });
    var rel_type = new Ext.form.Hidden({ name:'color' });
    var relation = new Ext.form.Hidden({ name:'color' });
    var show_class = new Ext.form.Hidden({ name:'color' });


    var selected_type = new Ext.form.Field({
        name: 'selected_type',
        xtype: "textfield",
        value: data.filter
    });
    selected_type.hide();

    var filter_field = new Ext.form.Field({
        xtype: "textfield",
        fieldLabel: _('Apply role filter'), 
        name: 'filter', 
        value: data.filter
    });
    filter_field.hide();

    var store_types = new Ext.data.SimpleStore({
        fields: ['type', 'name'],
        data:[ 
            [ 'release', _('Release') ],
            [ 'projects', _('Projects') ],
            [ 'users', _('Users') ],
            [ 'revisions', _('Revisions') ],
            [ 'topics', _('Topics') ],
            [ 'cis', _('Cis') ],
            [ 'tasks', _('Tasks') ]
        ]
    });


    var store_values = new Ext.data.SimpleStore({
        fields: ['value_type', 'name'],
        data:[ 
            [ 'single', _('Single') ],
            [ 'multiple', _('Multiple') ],
            [ 'grid', _('Grid') ]
        ]
    });


    var value_combo = new Ext.form.ComboBox({
        store: store_values,
        displayField: 'name',
        value: data.selected_type,
        valueField: 'value_type',
        hiddenName: 'value_type',
        name: 'value_type',
        editable: false,
        mode: 'local',
        forceSelection: true,
        triggerAction: 'all', 
        fieldLabel: _('Value type'),
        emptyText: _('select value type...'),
        autoLoad: true
    });

    value_combo.on('select', function(combo,rec,ix) {
    	list_type.setValue(rec.data.value_type);
    });



    var type_combo = new Ext.form.ComboBox({
        store: store_types,
        displayField: 'name',
        value: data.selected_type,
        valueField: 'type',
        hiddenName: 'type',
        name: 'type',
        editable: false,
        mode: 'local',
        forceSelection: true,
        triggerAction: 'all', 
        fieldLabel: _('Data type'),
        emptyText: _('select data type...'),
        autoLoad: true
    });
    value_combo.hide();
    

    type_combo.on('select', function(combo,rec,ix) {
        if(rec.data.type != 'revisions'){
        	value_combo.show();
        }
        if(rec.data.type == 'release'){
        	get_method.setValue('get_release');
        	set_method.setValue('set_release');
        	html.setValue('/fields/system/html/field_release.html');
        	js.setValue('/fields/system/list_release.js');
        	meta_type.setValue('release');
        }
        if(rec.data.type == 'projects'){
        	get_method.setValue('get_projects');
        	set_method.setValue('set_projects');
        	html.setValue('/fields/system/html/field_projects.html');
        	js.setValue('/fields/system/list_projects.js');
        }
        if(rec.data.type == 'users'){
        	filter_field.show();
        	get_method.setValue('get_users');
        	set_method.setValue('set_users');
        	html.setValue('/fields/system/html/field_users.html');
        	js.setValue('/fields/system/list_users.js');
        	meta_type.setValue('user');
        }
        if(rec.data.type == 'revisions'){
        	get_method.setValue('get_revisions');
        	set_method.setValue('set_revisions');
        	html.setValue('/fields/system/html/field_revisions.html');
        	js.setValue('/fields/system/list_revisions.js');
        }
        if(rec.data.type == 'topics'){
        	get_method.setValue('get_topics');
        	set_method.setValue('set_topics');
        	html.setValue('/fields/system/html/field_topics.html');
        	js.setValue('/fields/system/list_topics.js');
        }
        if(rec.data.type == 'cis'){
        	get_method.setValue('get_cis');
        	set_method.setValue('set_cis');
        	html.setValue('/fields/system/html/field_cis.html');
        	js.setValue('/fields/system/list_cis.js');
        	meta_type.setValue('ci');
        }
        if(rec.data.type == 'tasks'){
        	
        }else{
        	relation.setValue('system');
        }
    });

    ret.push([ 
    	type_combo,
    	value_combo,
    	filter_field
    ]);
    return ret;
})
