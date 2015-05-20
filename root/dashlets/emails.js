<%perl>
my $iid = Util->_md5;
</%perl>
(function(params){ 
    var id = params.id_div;
    var rows = params.data.rows;
    Cla.ajax_json('/dashboard/list_emails', {}, function(res){

        var html = '<style>#boot .pagination a {line-height: 22px;} #boot .table td {padding: 3px} #boot .table th {padding: 3px}  #boot select {width: 60px;  height: 20px;line-height: 20px;} #boot input {width: 100px;height: 20px;padding:0px} #boot .pagination a {float: left;padding: 0 5px;}</style>';
        var div = document.getElementById(id);
        html = html + '<table class="table display stripe order-column compact" style="font-size: 85%;width: 100%" id="<% $iid %>">';
        html = html + '       <thead>';
        html = html + '            <tr>';
        html = html + '                <th>'+ _("Subject") +'</th>';
        html = html + '                <th>'+ _("Sent") +'</th>';
        html = html + '            </tr>';
        html = html + '       </thead>';
        html = html + '       <tbody>';

        Ext.each(res.data, function(msg) {
            html = html + '            <tr>';
            html = html + '                <td class="title-html" title="'+ msg.subject +'"><b><a href="javascript:Baseliner.addNewTabComp(\'/message/inbox\' );">'+ msg.subject +'</a></b></td>';
            html = html + '                <td class="sent-html">'+ msg.sent +'</td>';
            html = html + '            </tr>';
        });
        html = html + '    </tbody>';
        html = html + '</table>';
        if(div) div.innerHTML = html;

        Baseliner.datatable("#<% $iid %>",{
          "scrollY": (parseInt(rows)*260),
          "dom": '<lf<t>ip>',
          "scrollX": true
        });
    });
});
