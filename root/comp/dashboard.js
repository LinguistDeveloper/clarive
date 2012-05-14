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

<div id="project" style="width: 98%; padding: 2px 2px 2px 2px;">
  <div class="container body">
    <div id="body" class="span-24" width="100%">
        <div class="span-12">
            <div class="alert">
                <button class="close" data-dismiss="alert">×</button>
                <strong>Warning!</strong> Best check yo self, you're not looking too good.
            </div>
        </div>    
      <div id="body" class="span-12 colborder append-bottom">
        <h2>Entornos</h2>
        <!--######INICIO TABLA ENTORNOS ###################################################################################-->      
        <table class="summary-table-entornos" width="100%" cellspacing="0">
          <thead>
            <tr>
              <th class="first-child section-name">Entorno</th>
              <th colspan="4" class="section-description">Finalizado</th>
              <th class="last-child section-name">Total</th>
            </tr>
          </thead>
          <tbody>
%foreach my $entorno (_array @entornos){
            <tr class='last-child'>
              <td class='first-child section-name' rowspan='2'><%$entorno->{bl}%></td>
              <td class="section-graph" colspan='2'>
                  <!--<div class="data-bar" style="width:<%$entorno->{porcentOk}%>%">&nbsp;</div>-->
                        <div class="progress progress-success" >
                            <div class="bar" style="width: <%$entorno->{porcentOk}%>%"></div>
                        </div>
              </td>
              <td class="section-score"><%$entorno->{totOk}%></td>
              <td class="section-score"><a href="javascript:Baseliner.addNewTabComp('/dashboard/viewjobs?ent=<%$entorno->{bl}%>&swOk=1', _('<%$entorno->{bl}%> - <%$entorno->{totOk}%>/<%$entorno->{total}%> OK'));"><img src="/static/images/preview.png" width="16px" height="12px" /></a></td>
              <td class='overall-score' rowspan='2'><%$entorno->{total}%></td>
            </tr>
            <tr class='last-child'>
              <td class="data-graph" colspan='2'>
                  <!--<div class="data-bar-error" style="width:<%$entorno->{porcentError}%>%">&nbsp;</div>-->
                        <div class="progress progress-danger" >
                            <div class="bar" style="width: <%$entorno->{porcentError}%>%"></div>
                        </div>
              </td>
              <td class="section-score"><%$entorno->{totError}%></td>
              <td class="section-score"><a href="javascript:Baseliner.addNewTabComp('/dashboard/viewjobs?ent=<%$entorno->{bl}%>&swOk=0', _('<%$entorno->{bl}%> - <%$entorno->{totError}%>/<%$entorno->{total}%> ERROR'));"><img src="/static/images/preview.png" width="16px" height="12px" /></a></td>
            </tr>
%}
          </tbody>    
        </table>
        <table width="480px">
          <tr>
            <td align="right">
              <b><a href="javascript:Baseliner.addNewTabComp('/dashboard/viewjobs?ent=All', _('Running jobs'));">Ver en ejecución</a></b>
            </td>
          </tr>
        </table>        
        <!--######FIN TABLA ENTORNOS #######################################################################################-->
      </div>
      
      <div id="body" class="span-12">
        <h2>Pases / Mensajes / Topics</h2>
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
        
        <table class="summary-table-mensajes" width="100%" cellspacing="0">
          <thead>
            <tr>
              <th class="first-child ">Pase</th>
              <th class="section-emisor">Estado</th>
              <th class="section-fecha">Inicio</th>
              <th class="last-child section-fecha">Fin</th>
            </tr>
          </thead>
          <tbody>
%my $row = 0;
%foreach my $lastjob (_array @lastjobs){
%$row = $row + 1;
            <tr class='last-child'>
              <td class='section-name'><b><a href="javascript:Baseliner.addNewTab('/job/log/dashboard?id_job=<%$lastjob->{id}%>&name=<%$lastjob->{name}%>', _('Log <%$lastjob->{name}%>') );"><%$lastjob->{name}%></a></b></td>
              <td class='section-description' id='row<%$row%>_<%$status_id%>'><%$lastjob->{status}%></td>
              <td class='section-fecha'><% length($lastjob->{starttime}) ? $lastjob->{starttime}->ymd() : '' %> <% length($lastjob->{starttime}) ? $lastjob->{starttime}->hms : '' %> </td>
              <td class='section-fecha'><% length($lastjob->{endtime}) ? $lastjob->{endtime}->ymd() : '' %> <% length($lastjob->{endtime}) ? $lastjob->{endtime}->hms : '' %></td>
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
        <table class="summary-table-mensajes" width="100%" cellspacing="0">
          <thead>
            <tr>
              <th colspan="3" class="first-child section-titulo">Asunto</th>
              <th class="section-emisor">De</th>
              <th class="last-child section-fecha">Enviado</th>
            </tr>
          </thead>
          <tbody>
%foreach my $email (_array @emails){
            <tr class='last-child'>
              <td class='section-name' colspan='3'><b><a href="javascript:Baseliner.addNewTabComp('/message/inbox?username=<%$c->username%>&query=<%$email->{id}%>', _('Inbox') );"><%$email->{subject}%></a></b></td>
              <td class='section-description'><%$email->{sender}%></td>
              <td class='section-fecha'><%$email->{sent}%></td>
            </tr>
%}
          </tbody>
        </table>
        <!--######FIN TABLA MENSAJES ####################################################################################-->
  
        <!--######INICIO TABLA TOPICS ###################################################################################-->
        <table class="summary-table-mensajes" width="100%" cellspacing="0">
          <thead>
            <tr>
              <th colspan="3" class="first-child section-titulo">Título</th>
              <th class="section-comentario">Comentarios</th>            
              <th class="last-child section-fecha">Creada</th>
            </tr>
          </thead>
          <tbody>
%foreach my $topic (_array @topics){
% my $numcomment = $topic->{numcomment} ? $topic->{numcomment}:'&nbsp';
            <tr class='last-child'>
              <td class='section-titulo' colspan='3'><b><a href="javascript:Baseliner.addNewTabComp('/topic/grid?query=<%$topic->{id}%>', _('Topics'));"><%$topic->{title}%></a></b></td>
              <td class='section-comentario'><%$numcomment%></td>
              <td class='section-fecha'><%$topic->{created_on}%></td>
            </tr>
%}
          </tbody>
        </table>
        <!--######FIN TABLA TOPICS ######################################################################################-->
      </div>
    </div>
    
    <div id="body" class="span-24" width="100%">
      <div id="body" class="span-12 colborder append-bottom">
        <h2>Pases</h2>
        <!--######INICIO TABLA PASES ###################################################################################-->
        <table class="summary-table-pases" width="100%" cellspacing="0">
          <thead>
            <tr>
              <th class="first-child section-proyecto">Proyecto</th>
              <th class="section-entorno">Entorno</th>
              <th class="section-ultimo-exito">Ult. Exito</th>
              <th class="section-ultimo-fallo">Ult. Fallo</th>
              <th class="last-child section-duracion">Ult. Duración</th>
            </tr>
          </thead>
          <tbody>
%foreach my $job (_array @jobs){          
            <tr class='last-child'>
              <td class="section-proyecto"><%$job->{project}%></td>
              <td class='section-entorno'><%$job->{bl}%></td>
%if($job->{idOk}){
              <!--<td class="section-exito"><%$job->{lastOk}%> dias (<b><a href="javascript:Baseliner.addNewTabComp('/job/log/list?id_job=<%$job->{idOk}%>', _('Log <%$job->{nameOk}%>'), { tab_icon: '/static/images/icons/moredata.gif' } );" style="font-family: Tahoma;">#<%$job->{idOk}%></a></b>)</td>-->
              <td class="section-exito"><%$job->{lastOk}%> dias (<b><a href="javascript:Baseliner.addNewTab('/job/log/dashboard?id_job=<%$job->{idOk}%>&name=<%$job->{nameOk}%>', _('Log <%$job->{nameOk}%>') );" style="font-family: Tahoma;">#<%$job->{idOk}%></a></b>)</td>
%}else{
              <td class="section-exito"> ------------- </td>  
%}
%if($job->{idError}){
              <!--<td class="section-fallo"><%$job->{lastError}%> dias (<b><a href="javascript:Baseliner.addNewTabComp('/job/log/list?id_job=<%$job->{idError}%>', _('Log <%$job->{nameError}%>'), { tab_icon: '/static/images/icons/moredata.gif' } );" style="font-family: Tahoma; color:red;">#<%$job->{idError}%></a></b>)</td>-->
              <td class="section-fallo"><%$job->{lastError}%> dias (<b><a href="javascript:Baseliner.addNewTab('/job/log/dashboard?id_job=<%$job->{idError}%>&name=<%$job->{nameError}%>', _('Log <%$job->{nameError}%>') );" style="font-family: Tahoma; color:red;">#<%$job->{idError}%></a></b>)</td>
%}else{
              <td class="section-fallo"> ------------- </td>  
%}
              <td class="section-duracion"><%$job->{lastDuration}%> min</td>
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
</div>
