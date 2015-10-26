<%perl>
my $iid = Util->_md5;
</%perl>
(function(params){ 
    var id = params.id_div;
    var project_id = params.project_id;
    var graph;
    var rows = params.data.rows;
    var bls = params.data.bls;
    var states = params.data.states;
    var not_in_states = params.data.not_in_states;
    var limit = params.data.limit;
    var topic_mid = params.topic_mid;

    function render_level ( obj ) {
        var icon;
        var bold = false;
        var status = obj.status;
        var type   = obj.type;
        var rollback = obj.rollback;
        var div1   = '<div style="white-space:normal !important;">';
        var div2   = '</div>';
        if( status=='RUNNING' ) { icon='gears.gif'; bold=true }
        else if( status=='READY' ) icon='log_d.gif';
        else if( status=='APPROVAL' ) icon='verify.gif';
        else if( status=='FINISHED' && rollback!=1 ) { icon='log_i.png'; bold=true; }
        else if( status=='IN-EDIT' ) icon='log_w.png';
        else if( status=='CANCELLED' ) icon='close.png';
        else { icon='log_e.png'; bold=true; };
        
        var value = (bold?'<b>' + _(status) + '</b>': _(status));

        // Rollback?
        if( status == 'FINISHED' && rollback == 1 )  {
            value += ' ('+ _("Rollback OK")+') ';
            icon = 'log_i.png';
        }
        else if( status == 'ERROR' && rollback == 1 )  {
            value +=  ' ('+ _("Rollback Failed")+') ';
            icon = 'log_e.png';
        }

        if( status == 'APPROVAL' ) { // add a link to the approval main
            value = String.format("<a href='javascript:Baseliner.request_approval({0});'><b>{1}</b></a>", obj.mid, _(status) ); 
        }
            
        if( icon!=undefined ) {
            var ret = div1 
                + "<img alt='"+status+"' style='vertical-align:middle' border=0 src='/static/images/icons/"+icon+"' />"
                + value + div2 ;
        } else {
            var ret = value;
        }
        return ret;
    };

    Cla.ajax_json('/dashboard/list_jobs', { topic_mid: topic_mid, project_id: project_id, not_in_states: not_in_states, limit: limit, bls: bls, states: states, _ignore_conn_errors: true  }, function(res){
        var html = '<style>#boot .pagination a {line-height: 22px;} #boot .table td {padding: 3px} #boot .table th {padding: 3px}  #boot select {width: 60px;  height: 20px;line-height: 20px;} #boot input {width: 100px;height: 20px;padding:0px} #boot .pagination a {float: left;padding: 0 5px;}</style>';
        var div = document.getElementById(id);
        html = html + '    <table class="table display stripe order-column compact" style="font-size: 85%;width: 100%" id="<% $iid %>">';
        html = html + '        <thead>';
        html = html + '            <tr>';
        html = html + '               <th style="width:15%;">'+_("Job")+'</th>';
        html = html + '               <th>'+_("Status")+'</th>';
        html = html + '               <th>'+_("Projects")+'</th>';
        html = html + '               <th style="width:15%;">'+_("Start")+'</th>';
        html = html + '               <th style="width:15%;">'+_("End")+'</th>';
        html = html + '            </tr>';
        html = html + '        </thead>';
        html = html + '        <tbody>';

        Ext.each( res.data, function(job) {
            html = html + '        <tr>';
            html = html + '           <td style="width:15%;"><b><a href="javascript:Baseliner.addNewTab(\'/job/log/dashboard?mid='+job.mid+'&name='+job.name+'\', _(\'Log '+job.name+'\') );">'+job.name+'</a></b></td>';
            html = html + '           <td>'+render_level(job)+'</td>';
            var apps = job.apps.split(',');

            if ( apps.length > 1 ) {
                apps = '<li>' + apps.join('</li><li>') + '</li>';
            } else {}
            html = html + '           <td>'+apps+'</td>';
            html = html + '           <td style="width:15%;">'+job.starttime+'</td>';
            html = html + '           <td style="width:15%;">'+job.endtime+'</td>';
            html = html + '        </tr>';
        });
        html = html + '        </tbody>';
        html = html + '      </table>';
        if(div) div.innerHTML = html;
        Baseliner.datatable("#<% $iid %>",{
          "scrollY": (parseInt(rows)*260),
          "dom": '<lf<t>ip>',
          "scrollX": true,
          "order": [[ 3, "desc" ]]
        });
    });
});
