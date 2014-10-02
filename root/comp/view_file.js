(function(params){
    var path = params.repo_dir;
    var file = params.file;
    var repo_mid = params.repo_mid;
    var revisions = params.revisions;
    var cons = new Baseliner.AceEditor();

    cons.on("aftereditor", function(){ 
        //alert(1);

                Baseliner.ajax_json('/svntree/view_file', { filepath: path, filename: file, repo_mid: repo_mid }, function(res){
                    cons.setValue(res.file_content);
                    cons.setReadOnly();
                }, function(res){
                     Baseliner.error( _('Error'), _(res.msg) );
                });



    });
    
//console.log (cons);
    var revisionsStore = new Baseliner.JsonStore({
        autoLoad: true,
        remoteSort: true,
        totalProperty:"totalCount", 
        id: 'id',
        url: '/svntree/get_file_revisions',
        baseParams:{ filepath: path, filename: file },
        fields: [ 'name' ]
    });

    var rev_combo = new Ext.form.ComboBox({ triggerAction: 'all', mode: 'local', name:'name', displayField: 'name', valueField: 'name', fieldLabel: 'revision', store: revisionsStore });
    rev_combo.on( 'select', function(param){ func_file_history(param.value);});
    rev_combo.setEditable(false);
    rev_combo.setValue(_('Selec revision...'));


    var pnl = new Ext.Panel({ 
        layout:'fit',
        items: cons,
        tbar: [ '<b>'+path+file+'</b>', '| ',
           rev_combo
        ],
        listeners:{ 
            // "afterrender": function(){
            // }
            "aftereditor": function(){
                alert(1);
            }            
        }
    });

    //cons.setValue('dsfsadfsdfsdf');




    var func_file_history = function(revision){
        revision = revision.substring(1);
        Baseliner.ajax_json('/svntree/view_file_revision', { filepath: path, filename: file, repo_mid: repo_mid, revision: revision }, function(res){
            cons.setValue(res.file_content);
            cons.setReadOnly();
        }, function(res){
             Baseliner.error( _('Error'), _(res.msg) );
        });
    }



    return pnl; 
})
