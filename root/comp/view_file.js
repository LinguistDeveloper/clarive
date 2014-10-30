(function(params){
    var path = params.repo_dir;
    var file = params.file;
    var revid = params.revid;
    var rev_num = params.rev_num;
    var controller = params.controller;
    var repo_mid = params.repo_mid;
    var revisions = params.revisions;
    var cons = new Baseliner.AceEditor();
    var revisionsStore = new Baseliner.JsonStore({
        autoLoad: true,
        remoteSort: true,
        totalProperty:"totalCount", 
        id: 'id',
        url: '/'+controller+'/get_file_revisions',
        baseParams:{ filepath: path, filename: file, rev_num: rev_num, revid: revid },
        fields: [ 'name' ]
    });
    var rev_combo = new Ext.form.ComboBox({ triggerAction: 'all', mode: 'local', name:'name', displayField: 'name', valueField: 'name', fieldLabel: 'revision', store: revisionsStore });
    cons.on("aftereditor", function(){
                Baseliner.ajax_json('/'+controller+'/view_file', { filepath: path, filename: file, repo_mid: repo_mid, rev_num: params.rev_num, revid: params.revid }, function(res){
                    cons.setValue(res.file_content);
                    cons.setReadOnly();
                    cons.goTop();
                    rev_combo.setValue('r'+res.rev_num);
                }, function(res){
                     Baseliner.error( _('Error'), _(res.msg) );
                });

    });

    rev_combo.on( 'select', function(param){ func_file_history(param.value);});
    rev_combo.setEditable(false);

    var pnl = new Ext.Panel({ 
        layout:'fit',
        items: cons,
        tbar: [ '<b>'+path+file+'</b>', '| ',
           rev_combo
        ]
    });

    var func_file_history = function(revision){
        revision = revision.substring(1);
        Baseliner.ajax_json('/'+controller+'/view_file', { filepath: path, filename: file, repo_mid: repo_mid, rev_num: revision }, function(res){
            cons.setValue(res.file_content);
            cons.setReadOnly();
            cons.goTop();
        }, function(res){
             Baseliner.error( _('Error'), _(res.msg) );
        });
    }

    return pnl; 
})
