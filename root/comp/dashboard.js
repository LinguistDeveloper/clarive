<%perl>
    use Baseliner::Utils;
    my @entornos = $c->stash->{entornos};
    my $idjob = '';
    my @emails = $c->stash->{emails};
    my $style = '';
    my @issues = $c->stash->{issues};
    my @jobs = $c->stash->{jobs};    
    my @sqas = $c->stash->{sqas};
</%perl>

<link rel="stylesheet" type="text/css" href="/site/portal/dashboard.css" />

<div id="project" style="width: 98%; padding: 2px 2px 2px 2px;">
  <div class="container body">
    <div id="body" class="span-24" width="100%">
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
                  <div class="data-bar" style="width:<%$entorno->{porcentOk}%>%">&nbsp;</div>
              </td>
              <td class="section-score"><%$entorno->{totOk}%></td>
              <td class="section-score"><a href="javascript:Baseliner.addNewTabComp('/dashboard/viewjobs?ent=<%$entorno->{bl}%>&swOk=1', _('<%$entorno->{bl}%> - <%$entorno->{totOk}%>/<%$entorno->{total}%> OK'));"><img src="/static/images/preview.png" width="16px" height="12px" /></a></td>
              <td class='overall-score' rowspan='2'><%$entorno->{total}%></td>
            </tr>
            <tr class='last-child'>
              <td class="data-graph" colspan='2'>
                  <div class="data-bar-error" style="width:<%$entorno->{porcentError}%>%">&nbsp;</div>
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
        <h2>Mensajes / Issues</h2>
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
  
        <!--######INICIO TABLA ISSUES ###################################################################################-->
        <table class="summary-table-mensajes" width="100%" cellspacing="0">
          <thead>
            <tr>
              <th colspan="3" class="first-child section-titulo">Título</th>
              <th class="section-comentario">Comentarios</th>            
              <th class="last-child section-fecha">Creada</th>
            </tr>
          </thead>
          <tbody>
%foreach my $issue (_array @issues){
% my $numcomment = $issue->{numcomment} ? $issue->{numcomment}:'&nbsp';
            <tr class='last-child'>
              <td class='section-titulo' colspan='3'><b><a href="javascript:Baseliner.addNewTabComp('/issue/grid?query=<%$issue->{id}%>', _('Issues'));"><%$issue->{title}%></a></b></td>
              <td class='section-comentario'><%$numcomment%></td>
              <td class='section-fecha'><%$issue->{created_on}%></td>
            </tr>
%}
          </tbody>
        </table>
        <!--######FIN TABLA ISSUES ######################################################################################-->
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
              <td class="section-exito"><%$job->{lastOk}%> dias (<b><a href="javascript:Baseliner.addNewTabComp('/job/log/list?id_job=<%$job->{idOk}%>', _('Log <%$job->{nameOk}%>'), { tab_icon: '/static/images/icons/moredata.gif' } );" style="font-family: Tahoma;">#<%$job->{idOk}%></a></b>)</td>
%}else{
              <td class="section-exito"> ------------- </td>  
%}
%if($job->{idError}){
              <td class="section-fallo"><%$job->{lastError}%> dias (<b><a href="javascript:Baseliner.addNewTabComp('/job/log/list?id_job=<%$job->{idError}%>', _('Log <%$job->{nameError}%>'), { tab_icon: '/static/images/icons/moredata.gif' } );" style="font-family: Tahoma; color:red;">#<%$job->{idError}%></a></b>)</td>
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
  
      <div id="body" class="span-12">
        <h2>Calidad</h2>
        <!--######INICIO TABLA SQA ######################################################################################-->
        <table class="summary-table-sqa"  cellspacing="0">
          <thead>
            <tr>
              <th class="first-child section-proyecto">Proyecto</th>            
              <th class="section-entorno">Entorno</th>
              <th class="section-subproyecto">Subproyecto</th>            
              <th class="section-naturaleza">Naturaleza</th>
              <th class="section-auditoria">Auditoría</th>
              <th class="last-child section-calificacion">Calificación</th>
            </tr>          
          </thead>
          <tbody>
%foreach my $sqa (_array @sqas){
% my $subapp = $sqa->{subapp} ? $sqa->{subapp}:'&nbsp';
% my $nature = $sqa->{nature} ? $sqa->{nature}:'&nbsp';
% my ($image, $color);
% if($sqa->{result} eq 'OK'){
% $image = 'flag_green.png';
% $color = '#000';
% }else{
% $image = 'flag_red.png';
% $color = 'red';
%}
            <tr class='last-child'>
              <td class="section-proyecto"><b><a target="_blank" href="/sqa/view_html/<%$sqa->{id}%>"><%$sqa->{project}%></a></b></td>            
              <td class='section-entorno'><%$sqa->{bl}%></td>
              <td class="section-subproyecto"><%$subapp%></td>
              <td class="section-naturaleza"><%$nature%></td>
              <td class="section-auditoria" align="center"><img src="/static/images/silk/<%$image%>"/></td>
              <td class="section-calificacion" style="font-size:12px;color:<%$color%>"><b><%$sqa->{qualification}%></b></td>
            </tr>
%}
          </tbody>
        </table>
        <!--######FIN TABLA SQA #########################################################################################-->                      
      </div>
    </div>
      
    </div>
  </div>
</div>
