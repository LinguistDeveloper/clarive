(function(params){
    var path = params.repo_dir;
    if(path.indexOf('/') != -1) path = path.substring(0,path.indexOf('/'));
    var file = params.file;
    var revid = params.revid;
    var branch = params.branch;
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
        baseParams:{ filepath: path, filename: file, rev_num: rev_num },
        fields: [ 'name' ]
    });
    var gen_editor = function(revision) {
        if(revision){
            rev_num = revision;
        }
        Baseliner.ajax_json('/'+controller+'/view_file', { filepath: path, filename: file, repo_mid: repo_mid, rev_num: rev_num, revid: params.revid, branch: branch }, function(res){
            revid = res.revid;
            cons.setValue(res.file_content);
            cons.setReadOnly();
            cons.goTop();
            rev_combo.setValue('r'+res.rev_num);
            pnl.add(cons);
        }, function(res){
             Baseliner.error( _('Error'), _(res.msg) );
        });

    };
    var rev_combo = new Ext.form.ComboBox({ triggerAction: 'all', mode: 'local', name:'name', displayField: 'name', valueField: 'name', fieldLabel: 'revision', store: revisionsStore , width: 100});
    cons.on("aftereditor", function(){
        gen_editor();
    });
    
    rev_combo.on( 'select', function(param){ func_file_history(param.value);});
    rev_combo.setEditable(false);

    var toggleHandler = function(comp, activate){
        if(activate){
            if(comp.pane == 'history'){
                cons.destroy();
                Baseliner.ajax_json('/'+controller+'/get_file_history', { filepath: path, filename: file, repo_mid: repo_mid, rev_num: rev_num, revid: revid }, function(res){
                    var store = new Ext.data.ArrayStore({
                        fields: [
                           {name: 'author'  },
                           {name: 'date'    },
                           {name: 'commit'  },
                           {name: 'comment' }
                        ]
                    });
                    store.loadData(res.history);

                    cons = new Ext.grid.GridPanel({
                        store: store,

                        columns: [
                            {
                                id       : 'author',
                                header   : _('Author'),  
                                dataIndex: 'author'
                            },
                            {
                                id       : 'date',
                                header   : _('Date'),  
                                dataIndex: 'date',
                                width    : 200
                            },
                            {
                                id       : 'commit',
                                header   : _('Commit'),  
                                dataIndex: 'commit'
                            },
                            {
                                id       : 'comment',
                                header   : _('Comment'),  
                                dataIndex: 'comment'
                            }
                        ],
                        stripeRows: true,
                        autoExpandColumn: 'comment',
                        title: _('File history'),
                    });
                    pnl.add( cons );
                    pnl.doLayout();
                }, function(res){
                     Baseliner.error( _('Error'), _(res.msg) );
                });     
            }else if(comp.pane == 'diff'){
                cons.destroy();
                Baseliner.ajaxEval('/comp/view_diff.js', { repo_dir: path, file: file, rev_num: rev_num, revid: revid, controller: controller, file_diff: '_file', branch: branch }, function(comp){
                    cons = comp;
                    pnl.add( cons );
                    pnl.doLayout();
                });
            }else if(comp.pane == 'blame'){
                cons.destroy();
                cons = new Ext.Panel({ layout:'form', items:[ new Ext.form.TextField({ fieldLabel:'blame' }) ] });
                Baseliner.ajax_json('/'+controller+'/get_file_blame', { filepath: path, filename: file, repo_mid: repo_mid, rev_num: params.rev_num, revid: params.revid }, function(res){

                }, function(res){
                     Baseliner.error( _('Error'), _(res.msg) );
                });
                pnl.add( cons );
                pnl.doLayout();
            }else if(comp.pane == 'source'){
                cons.destroy();
                cons = new Baseliner.AceEditor();
                cons.on("aftereditor", function(){
                    gen_editor();
                });
                pnl.add( cons );
                pnl.doLayout();
            }
        }
    };
    var button_style = 'normal 11px tahoma,verdana,helvetica';
    var source_button = new Ext.Button({ pane: 'source', text: _('source'), style: button_style, enableToggle: true, toggleGroup: 'properties_tg', toggleHandler: toggleHandler, pressed: true });
    var pnl = new Ext.Panel({ 
        layout:'fit',
        items: cons,
        tbar: [ source_button,
                new Ext.Button({ pane: 'history', text: _('history'), style: button_style, enableToggle: true, toggleGroup: 'properties_tg', toggleHandler: toggleHandler, pressed: false }),
                new Ext.Button({ pane: 'diff', text: _('diff'), style: button_style, enableToggle: true, toggleGroup: 'properties_tg', toggleHandler: toggleHandler, pressed: false }),
                new Ext.Button({ pane: 'blame', text: _('blame'), style: button_style, enableToggle: true, toggleGroup: 'properties_tg', toggleHandler: toggleHandler, pressed: false }),
                '<b>'+path+file+'</b>', '| ',
                rev_combo
        ]
    });

    var func_file_history = function(revision){
        revision = revision.substring(1);
        rev_num = revision;
        if(typeof cons.setValue === 'undefined'){
            cons.destroy();
            cons = new Baseliner.AceEditor();
            cons.on("aftereditor", function(){
                gen_editor(revision);
            });
            source_button.toggle(true);
            pnl.add( cons );
            pnl.doLayout();
        }else{
            gen_editor(revision);
        }
    }
    return pnl; 
})
