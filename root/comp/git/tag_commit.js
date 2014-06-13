(function(node) {
    if( node == undefined ) node = {};
    var repo_dir = node.attributes.data.repo_dir;
    var sha = node.attributes.data.sha;
	var store_tasks =new Baseliner.JsonStore({
		root: 'data', 
		remoteSort: true,
		totalProperty:"totalCount", 
		id: 'id', 
		url: '/tasks/json',
		fields: [ 'id', 'name', 'category', 'assigned', 'description' ]
	});
    
    var tpl2 = new Ext.XTemplate( '<tpl for=".">{name}</tpl>' );
    var combo_tasks = new Ext.ux.form.SuperBoxSelect({
        allowBlank: true,
        msgTarget: 'under',
        allowAddNewData: false,
        addNewDataOnBlur: false, 
        //emptyText: _('Enter or select the category tags'),
        triggerAction: 'all',
        resizable: true,
        store: store_tasks,
        mode: 'remote',
        fieldLabel: _('Tasks'),
        typeAhead: true,
        name: 'tasks',
        displayField: 'name',
        hiddenName: 'tasks',
        valueField: 'id',
        displayFieldTpl: tpl2,
        extraItemCls: 'x-tag',
        listeners: {
            newitem: function(bs,v, f){
                v = v.slice(0,1).toUpperCase() + v.slice(1).toLowerCase();
                var newObj = {
                    id: v,
                    name: v
                };
                bs.addItem(newObj);
            }
        }
     });

    var form = new Ext.FormPanel({
        frame: true, 
        width: 700,
        defaults: { width: 550 },
        items: [
            { xtype: 'hidden', name: 'repo_dir', value: repo_dir },
            { xtype: 'textfield', name: 'tagname', fieldLabel: _('Name'), required: true },
            combo_tasks,
            { xtype: 'textfield', name: 'commit', fieldLabel: _('Commit'), required: true, value: sha },
            { xtype: 'textarea', name: 'message', fieldLabel: _('Description'), height: '60px', required: true }
        ],
        buttons: [
            { text: _('Create'),
                handler: function(){
                    //alert(combo_tasks);
                    form.getForm().submit({
                        url: '/gittree/tag_new',
                        //params: { selected: sels.ns, names: sels.name },
                        waitMsg: _('Creating Tag...'),
                        success: function(fp, o){
                            var res = Ext.util.JSON.decode(o.response.responseText);
                            Baseliner.message( _('Create Tag'), res.msg );
                            win.close();
                        },
                        failure:  function(fp, o){
                            var res = Ext.util.JSON.decode(o.response.responseText);
                            Ext.MessageBox.show({
                                title: _('Error during tag create'),
                                msg: res.msg,
                                buttons: Ext.MessageBox.OK,
                                icon: Ext.MessageBox.ERROR
                            });
                        }
                    });
                }
            }
        ]
    });
    var win = new Ext.Window({ 
        title: _('Create Tag'),
        closeAction: 'destroy',
        items: [ form ]
    });
    win.show();
})

