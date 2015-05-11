<%perl>
my $iid = Util->_md5;
</%perl>

(function(params){ 
    var id = params.id_div;
    var rows = params.data.rows;
    var bls = params.data.bls;

    Cla.ajax_json('/dashboard/last_jobs', { bls: bls }, function(res){
        var html = '<style>#boot .pagination a {line-height: 22px;} #boot .table td {padding: 3px} #boot .table th {padding: 3px}  #boot select {width: 60px;  height: 20px;line-height: 20px;} #boot input {width: 100px;height: 20px;padding:0px} #boot .pagination a {float: left;padding: 0 5px;}</style>';
        var div = document.getElementById(id);
        html = html + '    <table class="table display nowrap stripe order-column compact" style="font-size: 85%;width: 100%" id="<% $iid %>">';
        html = html + '        <thead>';
        html = html + '            <tr>';
        html = html + '                <th>'+_("Project")+'</th>';
        html = html + '                <th>'+_("Baseline")+'</th>';
        html = html + '                <th>'+_("Last success")+'</th>';
        html = html + '                <th>'+_("Last failure")+'</th>';
        html = html + '                <th>'+_("Last elapsed")+'</th>';
        html = html + '            </tr>';
        html = html + '        </thead>';
        html = html + '        <tbody>';
        Ext.each( res.data, function(job) {
          html = html + '<tr>';
          html = html + '<td>'+job.project+'</td>';
          html = html + '<td>'+job.bl+'</td>';
          if ( job.id_ok ) {
            html = html + '<td>'+job.last_ok+' '+_('days')+' (<b><a href="javascript:Baseliner.addNewTab(\'/job/log/dashboard?mid='+job.mid_ok+'&name='+job.name_ok+'\', _(\'Log '+job.name_ok+'\') );" style="font-family: Tahoma;">#'+job.id_ok+'</a></b>)</td>';
          } else {
            html = html + '<td> ------------- </td>';
          }
          if ( job.id_err ) {
            html = html + '<td>'+job.last_err+' '+_('days')+' (<b><a href="javascript:Baseliner.addNewTab(\'/job/log/dashboard?mid='+job.mid_err+'&name='+job.name_err+'\', _(\'Log '+job.name_err+'\') );" style="font-family: Tahoma;color:red;">#'+job.id_err+'</a></b>)</td>';
          } else {
            html = html + '<td> ------------- </td>';
          }
          html = html + '<td>'+job.last_duration+'</td>';
          html = html + '</tr>';
        });
        html = html + '  </tbody>';
        html = html + '</table>';
        div.innerHTML = html;
        Baseliner.datatable("#<% $iid %>",{
          "scrollY": (parseInt(rows)*260),
          "dom": '<lf<t>ip>',
          "scrollX": true
        });
    });

});




