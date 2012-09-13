Baseliner.Topic = {};
    
Baseliner.Topic.rt = Ext.data.Record.create([
    {name: 'id_project'},
    {name: 'project'}
]);

Baseliner.Topic.StoreProject = Ext.extend(Ext.data.Store, {
    constructor: function(config) {
        config = Ext.apply({
            // explicitly create reader
            reader: new Ext.data.ArrayReader(
                {
                    idIndex: 0  // id for each record will be the first element
                },
                Baseliner.Topic.rt // recordType
            )
        }, config);
        Baseliner.Topic.StoreProject.superclass.constructor.call(this, config);
    }
}); 

Baseliner.Topic.StoreStatus = Ext.extend(Baseliner.JsonStore, {
    constructor: function(config) {
        config = Ext.apply({
            root: 'data' , 
            remoteSort: true,
            totalProperty:"totalCount", 
            url: '/topicadmin/list_status',
            fields: [ 
                {  name: 'id' },
                {  name: 'name' },
                {  name: 'description' },
                {  name: 'bl' },
                {  name: 'seq' },
                {  name: 'type' }                
            ]
        }, config);
        Baseliner.Topic.StoreStatus.superclass.constructor.call(this, config);
    }
}); 
    
Baseliner.Topic.StoreCategory = Ext.extend( Baseliner.JsonStore, {
    constructor: function(config) {
        config = Ext.apply({
            root: 'data' , 
            remoteSort: true,
            baseParams:{cmb:'category'},
            totalProperty:"totalCount", 
            url: '/topic/list_category',
            fields: [ 
                {  name: 'id' },
                {  name: 'name' },
                {  name: 'color' },
                {  name: 'description' },
                {  name: 'type' },
                {  name: 'statuses' },
                {  name: 'forms' },
                {  name: 'is_release' },
                {  name: 'is_changeset' },
                {  name: 'fields' },
                {  name: 'priorities' }
            ]
        },config);
        Baseliner.Topic.StoreCategory.superclass.constructor.call(this, config);
    }
});

Baseliner.Topic.StoreCategoryStatus = Ext.extend( Baseliner.JsonStore, {
    constructor: function(config) {
        config = Ext.apply({
            root: 'data' , 
            remoteSort: true,
            totalProperty:"totalCount", 
            url: '/topic/list_category',
            fields: [ 
                {  name: 'id' },
                {  name: 'name' },
                {  name: 'type' },
                {  name: 'bl' },
                {  name: 'description' }
            ]
        },config);
        Baseliner.Topic.StoreCategoryStatus.superclass.constructor.call(this, config);
    }
});

Baseliner.Topic.StoreList = Ext.extend( Baseliner.JsonStore, {
    constructor: function(config) {
        config = Ext.apply({
            root: 'data' , 
            remoteSort: true,
            totalProperty:"totalCount", 
            url: '/topic/list',
            fields: [ 
                {  name: 'topic_mid' },
                {  name: 'topic_name' },
                {  name: 'title' },
                //{  name: 'description' },
                {  name: 'created_on', type: 'date', dateFormat: 'c' },        
                {  name: 'created_by' },
                {  name: 'numcomment' },
                {  name: 'category_id' },
                {  name: 'category_color' },
                {  name: 'is_release' },
                {  name: 'is_changeset' },
                {  name: 'category_name' },
                {  name: 'calevent' },
                {  name: 'projects' },          
                {  name: 'labels' },
                {  name: 'status' },
                {  name: 'progress' },
                {  name: 'revisions' },
                {  name: 'report_data' },
                {  name: 'category_status_name' },
                {  name: 'category_status_seq' },
                {  name: 'category_status_id' },
                {  name: 'category_status_type' },
                {  name: 'priority_id' },
                {  name: 'response_time_min' },
                {  name: 'expr_response_time' },
                {  name: 'deadline_min' },
                {  name: 'expr_deadline' },
                {  name: 'num_file' },
                {  name: 'assignee' }
            ]
        },config);
        Baseliner.Topic.StoreList.superclass.constructor.call(this, config);
    }
});

Baseliner.Topic.StoreLabel = Ext.extend( Baseliner.JsonStore, {
    constructor: function(config) {
        config = Ext.apply({
            root: 'data' , 
            remoteSort: true,
            totalProperty:"totalCount", 
            url: '/topic/list_label',
            fields: [ 
                {  name: 'id' },
                {  name: 'name' },
                {  name: 'color' }
            ]
        },config);
        Baseliner.Topic.StoreLabel.superclass.constructor.call(this, config);
    }
});

Baseliner.Topic.StorePriority = Ext.extend( Baseliner.JsonStore, {
    constructor: function(config) {
        config = Ext.apply({
            root: 'data' , 
            remoteSort: true,
            totalProperty:"totalCount", 
            url: '/topic/list_priority',
            fields: [ 
                {  name: 'id' },
                {  name: 'name' },
                {  name: 'response_time_min' },
                {  name: 'expr_response_time' },
                {  name: 'deadline_min' },
                {  name: 'expr_deadline' }          
            ]
        },config);
        Baseliner.Topic.StorePriority.superclass.constructor.call(this, config);
    }
});

Baseliner.Topic.comment_delete = function(id_com, id_div ) {
    Baseliner.ajaxEval( '/topic/comment/delete', { id_com: id_com }, function(res) {
        if( res.failure ) {
            Ext.Msg.alert( _('Error'), res.msg );
        } else {
            // no need to report anything
            // delete div if any
            try {
                var el = Ext.fly( id_div );
                if( el !== undefined ) {
                    el.fadeOut({ duration: .5, callback: function(e){ e.remove() } });
                }
            } catch(eee) { }
        }
    });
};

Baseliner.Topic.StoreUsers = Ext.extend( Baseliner.JsonStore, {
    constructor: function(config) {
        config = Ext.apply({
            root: 'data' , 
            remoteSort: true,
            totalProperty:"totalCount", 
            url: '/topic/list_users',
            fields: [ 
                {  name: 'id' },
                {  name: 'username' },
                {  name: 'realname' }
            ]
        },config);
        Baseliner.Topic.StoreUsers.superclass.constructor.call(this, config);
    }
});

//Baseliner.store.Topics = function(c) {
//     Baseliner.store.Topics.superclass.constructor.call(this, Ext.apply({
//        root: 'data' , 
//        remoteSort: true,
//        autoLoad: true,
//        totalProperty:"totalCount", 
//        baseParams: {},
//        id: 'mid', 
//        url: '/topic/related',
//        fields: ['mid','name', 'title','description','color'] 
//     }, c));
//};
//Ext.extend( Baseliner.store.Topics, Baseliner.JsonStore );

//Baseliner.model.Topics = function(c) {
//    //var tpl = new Ext.XTemplate( '<tpl for="."><div class="search-item {recordCls}">{name} - {title}</div></tpl>' );
//    var tpl_list = new Ext.XTemplate( '<tpl for="."><div class="x-combo-list-item">',
//        '<span id="boot" style="width:200px"><span class="badge" style="float:left;padding:2px 8px 2px 8px;background: {color}">{name}</span></span>',
//        '&nbsp;&nbsp;<b>{title}</b></div></tpl>' );
//    var tpl_field = new Ext.XTemplate( '<tpl for=".">',
//        '<span id="boot"><span class="badge" style="float:left;padding:2px 8px 2px 8px;background: {color}">{name}</span></span>',
//        '</tpl>' );
//    Baseliner.model.Topics.superclass.constructor.call(this, Ext.apply({
//        allowBlank: true,
//        msgTarget: 'under',
//        allowAddNewData: true,
//        addNewDataOnBlur: true, 
//        //emptyText: _('Enter or select topics'),
//        triggerAction: 'all',
//        resizable: true,
//        mode: 'local',
//        fieldLabel: _('Topics'),
//        typeAhead: true,
//            name: 'topics',
//            displayField: 'title',
//            hiddenName: 'topics',
//            valueField: 'mid',
//        tpl: tpl_list,
//        displayFieldTpl: tpl_field,
//        value: '/',
//        extraItemCls: 'x-tag'
//        /*
//        ,listeners: {
//            newitem: function(bs,v, f){
//                v = v.slice(0,1).toUpperCase() + v.slice(1).toLowerCase();
//                var newObj = {
//                    mid: v,
//                    title: v
//                };
//                bs.addItem(newObj);
//            }
//        }
//        */
//    }, c));
//};
//Ext.extend( Baseliner.model.Topics, Ext.ux.form.SuperBoxSelect );

