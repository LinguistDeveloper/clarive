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

Baseliner.Topic.StoreStatus = Ext.extend(Ext.data.JsonStore, {
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
    
Baseliner.Topic.StoreCategory = Ext.extend( Ext.data.JsonStore, {
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
                {  name: 'fields' }
            ]
        },config);
        Baseliner.Topic.StoreCategory.superclass.constructor.call(this, config);
    }
});

Baseliner.Topic.StoreCategoryStatus = Ext.extend( Ext.data.JsonStore, {
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

Baseliner.Topic.StoreList = Ext.extend( Ext.data.JsonStore, {
    constructor: function(config) {
        config = Ext.apply({
            root: 'data' , 
            remoteSort: true,
            totalProperty:"totalCount", 
            url: '/topic/list',
            fields: [ 
                {  name: 'topic_mid' },
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
                {  name: 'category_status_name' },
                {  name: 'priority_id' },
                {  name: 'response_time_min' },
                {  name: 'expr_response_time' },
                {  name: 'deadline_min' },
                {  name: 'expr_deadline' }
                
            ]
        },config);
        Baseliner.Topic.StoreList.superclass.constructor.call(this, config);
    }
});

Baseliner.Topic.StoreLabel = Ext.extend( Ext.data.JsonStore, {
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

Baseliner.Topic.StorePriority = Ext.extend( Ext.data.JsonStore, {
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

Baseliner.Topic.StoreUsers = Ext.extend( Ext.data.JsonStore, {
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

