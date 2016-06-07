(function(params){
    var repo_dir = params.repo_dir;
    var rev_num = params.rev_num;
    var revid = params.revid;
    var controller = params.controller;
    var branch = params.branch;
    var repo_mid = params.repo_mid;
    var file_diff = params.file_diff;
    if(!file_diff){
        file_diff = '';
    }
    var temp_id;
    var code_section = {};
    var panel = new Ext.Panel({ 
        frame: false,
        layout:'fit',
        html:'',
        region: 'center',
        bodyStyle:{ 'background-color':'#fff', padding:' 5px 5px 5px 5px', overflow:'auto'},
        border: false
    });

    var panel2 = new Ext.Panel({ 
        frame: false,
        layout:'fit',
        region: 'south',
        height: 300,
        hidden: true,
        border: false
    });

    var parent_panel = new Ext.Panel({ 
        frame: false,
        layout: 'border',
        tbar: [ ],
        items: [ panel, panel2 ],
        border: false
    });

    var bodyDiff = function(i, changes) {
        var res = '';
        var regexp_add = new RegExp("^\\+[\s\S]*");
        var regexp_del = new RegExp("^\\-[\s\S]*");
        changes[i].code_chunks.forEach(function(element, index, array) {
            if (element.stats) {
                var stats = element.stats;
                var beginig_orig = stats.split(' ')[0].split(',');
                var beginig_last = stats.split(' ')[1].split(',');
                var origin_start = Math.abs(beginig_orig[0]);
                var last_start = Math.abs(beginig_last[0]);
            }
            res = res + "<tr><td colspan=3>" + stats + "</td></tr>";
            if (!element.code) {
                element.code = '';
            }
            var lines = element.code.split("\n");
            var regexp_final = new RegExp("");
            if (element.code.search(regexp_del) >= 0)
                lines.pop();
            lines.forEach(function(element, index, array) {
                if (element.search(regexp_add) >= 0) {
                    res = res + "<tr><td width=\"1\" class=\"line-number\">" +
                        "</td><td width=\"1\" class=\"line-number\">" +
                        last_start + "</td><td class=\"added-code\">" +
                        Baseliner.escapeHtmlEntities(element.substr(1)) +
                        "</td></tr>";
                    last_start++;
                } else if (element.search(regexp_del) >= 0) {
                    res = res + "<tr><td width=\"1\" class=\"line-number\">" +
                        origin_start + "</td><td width=\"1\" class=\"line-number\">" +
                        "</td><td class=\"deleted-code\">" + Baseliner.escapeHtmlEntities(element.substr(1)) +
                        "</td></tr>";
                    origin_start++;
                } else if (element.search("\\ No newline at end of file") >= 0) {} else {
                    res = res + "<tr><td width=\"1\" class=\"line-number\">" +
                        origin_start + "</td><td width=\"1\" class=\"line-number\">" +
                        last_start + "</td><td class=\"permanent-code\">" +
                        Baseliner.escapeHtmlEntities(element.substr(1)) +
                        "</td></tr>";
                    origin_start++;
                    last_start++;
                }
            });
        });
        return res;
    };

    var get_combo_tags = function(){
        var tags_combo = new Ext.form.ComboBox({ triggerAction: 'all', mode: 'local', name:'name', displayField: 'name', valueField: 'name', fieldLabel: 'tags', store: tagsStore , width: 150});
        tags_combo.setValue(_('Parallel?'));
        tags_combo.setEditable( false );
        tags_combo.on( 'select', function(param){
            params_view_diff.tag = param.value;
            params_view_diff.commit = params_view_diff.sha;
            params_view_diff.controller = controller;
            Baseliner.ajaxEval('/comp/view_commits_history.js', params_view_diff, function(comp){
                panel2.add(comp); 
                panel2.show();
            });
             Baseliner.ajax_json('/'+controller+'/view_diff', params_view_diff, function(res_diff_tag){
                 generate_diff(res_diff_tag);
             });
        });
        return tags_combo;
    };

    if(controller == 'gittree' && file_diff == ''){
        var params_get_tags = { repo_mid: params.repo_mid, repo_dir: params.repo_dir };
        var tagsStore = new Baseliner.JsonStore({
            autoLoad: true,
            remoteSort: true,
            totalProperty:"totalCount", 
            baseParams: params_get_tags,
            id: 'id',
            url: '/'+controller+'/get_tags',
            fields: [ 'name' ]
        });
        parent_panel.getTopToolbar().add(get_combo_tags());
    }

    var params_view_diff;
    if(controller == 'gittree'){
        params_view_diff = { repo_dir: params.repo_dir, file: params.file, sha: rev_num, bl: params.bl, branch: branch, repo_mid: repo_mid };
    }else{
        params_view_diff = { first_level: params.first_level, repo_dir: repo_dir, rev_num: rev_num, branch: branch, revid: revid, file: params.file, repo_mid: repo_mid };
    }

    var generate_diff = function(res){
        var get_section_ids = function(){
            for(var i=0; i < res.changes.length; i++) {
                temp_id = Ext.id(); 
                code_section[res.changes[i].path] = temp_id;
            }
        };

        get_section_ids();
        var children = [];
        var goto_link = function(n){
            var elem = document.getElementById(n.val); 
            elem.scrollIntoView(true);
            Baseliner.scroll_top_into_view();
        }
        for(var key in code_section){
             var val = code_section[key];
             children.push({text: key, leaf: true, val: val, handler: goto_link});
        }
        parent_panel.getTopToolbar().removeAll();
        parent_panel.getTopToolbar().add({ text:_('Files'), menu:children });
        if(controller == 'gittree' && file_diff == ''){
            parent_panel.getTopToolbar().add(get_combo_tags());
        }
        
        parent_panel.doLayout();
        panel.doLayout();

        var html = function(){/*
               <div id="boot" >
                       <div>
                          <center>
                       [% if(tag){ tag = "compared to tag "+tag } %]
                       <h3>[%= _('Revision') %] [%= rev_num %] [%= tag %]</h3>
                       <table class="table table-bordered table-condensed" style="width: 60%">
                       <thead>
                       <tr><th width="33%">[%= _('Commit Owner') %]</th><th width="33%" style="white-space: nowrap">[%= _('Last Updated') %]</th><th width="33%">[%= _('Comment') %]</th></tr>
                       </thead>
                       <tbody>
                       <tr>
                               <td style="white-space: nowrap">
                                   &nbsp;[%= author %]
                               </td>
                               <td style="white-space: nowrap">
                                   [%= date %]
                               </td>
                               <td>
                                   [%= comment %]
                               </td>
                           </tr>
                       </tbody>
                       </table>

                       [% for(var i=0; i < changes.length; i++) { %]
                               <table class="table table-bordered table-condensed" style="width: 90%">
                              <thead>
                                   <tr>
                                       <th id='[%= code_section[changes[i].path] %]' data-file="[%= changes[i].path %]" style="font-family: Courier New, Courier, monospace;" colspan=3>
                                           [%= changes[i].path %] [%= changes[i].revision1 %] =&gt; [%= changes[i].revision2 %]
                                           [% 
                                              if(branch == undefined || controller == 'gittree'){
                                               branch = '';
                                              }
                                              var repo = repo_dir;
                                              if(controller != 'svntree'){
                                                repo = repo +'/'+branch;
                                              }
                                           %]
                                           <a class="btn btn-mini" onclick="Baseliner.add_tabcomp( 
                                                                               '/comp/view_file.js', 
                                                                               '[%= branch %]:[[%= rev_num %]] [%= changes[i].path %]',
                                                                               {   repo_dir:'[%= repo %]', 
                                                                                   file:'[%= changes[i].path %]',
                                                                                   repo_mid:'[%= repo_mid %]', 
                                                                                   branch:'[%= branch %]', 
                                                                                   rev_num:'[%= rev_num %]',
                                                                                   revid: '[%= changes[i].revid %]',
                                                                                   controller:'[%= controller %]'
                                                                               }
                                                                           )">[%= _('Raw') %]
                                           </a>
                                       </th>
                                   </tr>
                           </thead>
                           <tbody>
                       [%
                        var res = bodyDiff(i,changes);
                        %]
                       [%= res.replace(/\&#9;/gm, '&nbsp;&nbsp;&nbsp;&nbsp;') %]
                       </tbody>
                       </table>
                       [% } %]
                       </div>
                   </div>
        */}.tmpl({ bodyDiff: bodyDiff, controller: controller, temp_id: temp_id, code_section: code_section, repo_mid: repo_mid, repo_dir: repo_dir, branch: branch, rev_num: res.commit_info.revision, author: res.commit_info.author, date: res.commit_info.date, comment: res.commit_info.comment, changes: res.changes, tag: params_view_diff.tag });

        if (panel.rendered) {
            panel.update(html);
        }

        function renderReview(review) {
            var created_by = '<b>' + (review.created_by || 'n/a') + '</b>';
            var date = review.created_on;
            return '<tr><td colspan="3">' + created_by + ' (' + date + ')' + '<br />' + review.text + '</td></tr>';
        }

        $('td.line-number').each(function() {
            var $td = $(this);
            $td.css('cursor', 'pointer').click(function() {
                Ext.Msg.prompt('Add comment', '', function(button, text) {
                    if (button === 'ok') {
                        var comment_params = {
                            repo_mid: params.repo_mid,
                            rev_num: params.rev_num,
                            branch: params.branch,
                            file: $td.closest('table').find('th').attr('data-file'),
                            line: parseInt($td.html()),
                            action: $td.attr('data-action'),
                            text: text
                        };
                        Baseliner.ajax_json('/review/add', comment_params, function(res) {
                            $(renderReview(res.data)).insertAfter($td.closest('tr'));
                        }, function(res) {
                            Baseliner.error(_('Error'), _(res.msg));
                        });

                    }
                }, undefined, true); // true is for multiline
            });
        });

        Baseliner.ajax_json('/review/list', {repo_mid: params.repo_mid, rev_num: params.rev_num}, function(res) {
            if (res && res.data) {
                for (file in res.data) {
                    $('[data-file="' + file + '"]').each(function() {
                        $th = $(this);

                        for (var i = 0; i < res.data[file].length; i++) {
                            var review = res.data[file][i];

                            var $line = $th.closest('table').find('td.line-number:contains("' + review.line + '")');

                            if ($line.length) {
                                $(renderReview(review)).insertAfter($line[0].closest('tr'));
                            }
                        }
                    });
                }
            }
        });
    }

    var html = Baseliner.ajax_json('/'+controller+'/view_diff'+file_diff, params_view_diff, generate_diff, function(res){
         Baseliner.error( _('Error'), _(res.msg) );
    });
    return parent_panel;
})
