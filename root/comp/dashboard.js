<%args>
    $dashboardlets
</%args>
<%perl>
    use Baseliner::Utils;
    my @entornos = $c->stash->{entornos};
    my $idjob = '';
    my @lastjobs = $c->stash->{lastjobs};
    my @emails = $c->stash->{emails};
    my $style = '';
    my @topics = $c->stash->{topics};
    my @jobs = $c->stash->{jobs};    
    my $status_id = "status". _nowstamp;
</%perl>

<div id="boot">
    <div class="container_24">
        <div class="grid_10 style="margin-bottom: 5px;">
            <h2>Entornos</h2>
%foreach my $entorno (_array @entornos){
            <h4><%$entorno->{bl}%></h4>
            <div class="progress progress-success" style="margin-bottom: 5px;">
                <div class="bar" style="width: <%$entorno->{porcentOk}%>%"><%$entorno->{totOk}%></div>
            </div>
            <div class="progress progress-danger" style="margin-bottom: 5px;">
                <div class="bar" style="width: <%$entorno->{porcentError}%>%"><%$entorno->{totError}%></div>
            </div>
            <div class="clear"></div>
%}
        </div>
    
        <div class="grid_1">&nbsp;</div>
        <div class="grid_13">
            <h2>Pases / Mensajes / Topicos</h2>
            <!--######INICIO TABLA PASES #################################################################################-->
            <script language="javascript">
                function render_level ( obj, td_id ) {
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
                    else if( status=='FINISHED' && rollback!=1 ) { icon='log_i.gif'; bold=true; }
                    else if( status=='IN-EDIT' ) icon='log_w.gif';
                    else { icon='log_e.gif'; bold=true; }
                    var value = (bold?'<b>' + _(status) + '</b>': _(status));
            
                    // Rollback?
                    if( status == 'FINISHED' && rollback == 1 )  {
                        value += ' (<% _loc("Rollback OK") %>)';
                        icon = 'log_e.gif';
                    }
                    else if( status == 'ERROR' && rollback == 1 )  {
                        value += ' (<% _loc("Rollback Failed") %>)';
                    }
                    //else if( type == 'demote' || type == 'rollback' ) value += ' ' + _('(Rollback)');
                    if( status == 'APPROVAL' ) { // add a link to the approval main
                        //value = '<a href="javascript:Baseliner.addNewTabComp(' + '"/request/main", '<% _loc("Approvals") %>, value ); 
                        value = String.format("<a href='javascript:Baseliner.addNewTabComp(\"{0}\", \"{1}\");'>{2}</a>", "/request/main", <% _loc('Approvals') %>, status ); 
                    }
                    
                    
                    ////alert(icon);
                    var tdStatus = document.getElementById( td_id );
                    if( icon!=undefined ) {
                        tdStatus.innerHTML = div1 
                            + "<img alt='"+status+"' style='vertical-align:middle' border=0 src='/static/images/"+icon+"' />"
                            + value + div2 ;
                    } else {
                        tdStatus.innerHTML = value;
                    }
                };
            </script>
            <table class="table table-bordered table-condensed">
                <thead>
                    <tr>
                        <th>Pase</th>
                        <th>Estado</th>
                        <th>Inicio</th>
                        <th>Fin</th>
                    </tr>
                </thead>
                    <tbody>
%my $row = 0;
%foreach my $lastjob (_array @lastjobs){
%$row = $row + 1;
                    <tr>
                        <td><b><a href="javascript:Baseliner.addNewTab('/job/log/dashboard?id_job=<%$lastjob->{id}%>&name=<%$lastjob->{name}%>', _('Log <%$lastjob->{name}%>') );"><%$lastjob->{name}%></a></b></td>
                        <td id='row<%$row%>_<%$status_id%>'><%$lastjob->{status}%></td>
                        <td><% length($lastjob->{starttime}) ? $lastjob->{starttime}->ymd() : '' %> <% length($lastjob->{starttime}) ? $lastjob->{starttime}->hms : '' %> </td>
                        <td><% length($lastjob->{endtime}) ? $lastjob->{endtime}->ymd() : '' %> <% length($lastjob->{endtime}) ? $lastjob->{endtime}->hms : '' %></td>
                    </tr>
                <script>
                    var details_job = new Object();
                    details_job.status = '<%$lastjob->{status}%>';
                    details_job.type = '<%$lastjob->{type}%>';
                    details_job.rollback = <%$lastjob->{rollback}%>;
                    render_level(details_job, 'row<%$row%>_<%$status_id%>');
                </script>
%}            
                </tbody>
            </table>
            <!--######FIN TABLA PASES ####################################################################################-->
              
            <!--######INICIO TABLA MENSAJES #################################################################################-->
            <table class="table table-bordered table-condensed">
                <thead>
                    <tr>
                        <th colspan="3">Asunto</th>
                        <th>De</th>
                        <th>Enviado</th>
                    </tr>
                </thead>
                <tbody>
%foreach my $email (_array @emails){
                    <tr>
                        <td colspan='3'><b><a href="javascript:Baseliner.addNewTabComp('/message/inbox?username=<%$c->username%>&query=<%$email->{id}%>', _('Inbox') );"><%$email->{subject}%></a></b></td>
                        <td><%$email->{sender}%></td>
                        <td><%$email->{sent}%></td>
                    </tr>
%}
                </tbody>
            </table>
            <!--######FIN TABLA MENSAJES ####################################################################################-->
        
            <!--######INICIO TABLA TOPICS ###################################################################################-->
            <table class="table table-bordered table-condensed">
                <thead>
                    <tr>
                        <th colspan="3">Título</th>
                        <th>Comentarios</th>            
                        <th>Creada</th>
                    </tr>
                </thead>
                <tbody>
%foreach my $topic (_array @topics){
% my $numcomment = $topic->{numcomment} ? $topic->{numcomment}:'&nbsp';
                    <tr>
                        <td colspan='3'><b><a href="javascript:Baseliner.addNewTabComp('/topic/grid?query=<%$topic->{id}%>', _('Topics'));"><%$topic->{title}%></a></b></td>
                        <td><%$numcomment%></td>
                        <td><%$topic->{created_on}%></td>
                    </tr>
%}
                </tbody>
            </table>
            <!--######FIN TABLA TOPICS ######################################################################################-->
        </div>
            
        <div class="grid_10">
            <h2>Pases</h2>
            <!--######INICIO TABLA PASES ###################################################################################-->
            <table class="table table-bordered table-condensed">
                <thead>
                    <tr>
                        <th>Proyecto</th>
                        <th>Entorno</th>
                        <th>Ult. Exito</th>
                        <th>Ult. Fallo</th>
                        <th>Ult. Duración</th>
                    </tr>
                </thead>
                <tbody>
%foreach my $job (_array @jobs){          
                    <tr>
                        <td><%$job->{project}%></td>
                        <td><%$job->{bl}%></td>
%if($job->{idOk}){
                        <!--<td class="section-exito"><%$job->{lastOk}%> dias (<b><a href="javascript:Baseliner.addNewTabComp('/job/log/list?id_job=<%$job->{idOk}%>', _('Log <%$job->{nameOk}%>'), { tab_icon: '/static/images/icons/moredata.gif' } );" style="font-family: Tahoma;">#<%$job->{idOk}%></a></b>)</td>-->
                        <td><%$job->{lastOk}%> dias (<b><a href="javascript:Baseliner.addNewTab('/job/log/dashboard?id_job=<%$job->{idOk}%>&name=<%$job->{nameOk}%>', _('Log <%$job->{nameOk}%>') );" style="font-family: Tahoma;">#<%$job->{idOk}%></a></b>)</td>
%}else{
                        <td> ------------- </td>  
%}
%if($job->{idError}){
                        <!--<td class="section-fallo"><%$job->{lastError}%> dias (<b><a href="javascript:Baseliner.addNewTabComp('/job/log/list?id_job=<%$job->{idError}%>', _('Log <%$job->{nameError}%>'), { tab_icon: '/static/images/icons/moredata.gif' } );" style="font-family: Tahoma; color:red;">#<%$job->{idError}%></a></b>)</td>-->
                        <td><%$job->{lastError}%> dias (<b><a href="javascript:Baseliner.addNewTab('/job/log/dashboard?id_job=<%$job->{idError}%>&name=<%$job->{nameError}%>', _('Log <%$job->{nameError}%>') );" style="font-family: Tahoma; color:red;">#<%$job->{idError}%></a></b>)</td>
%}else{
                        <td> ------------- </td>  
%}
                        <td><%$job->{lastDuration}%> min</td>
                    </tr>
%}
                </tbody>    
            </table>
            <!--######FIN TABLA PASES #######################################################################################-->
        </div>
  
% for my $dash ( sort { $a->order <=> $b->order } _array $dashboardlets ) {
    <& $dash->html &>
% } 
    </div>
</div>

   
