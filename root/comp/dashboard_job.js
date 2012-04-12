<%perl>
  use Baseliner::Utils;
  my $idjob = $c->stash->{id_job};
  my $namejob = $c->stash->{name_job};

  my $resumen = $c->stash->{resumen};
</%perl>

<div id="project" style="padding: 10px 10px 10px 10px;">   
<div id="project" style="width: 98%; padding: 2px 2px 2px 2px;">
  <div class="container body">
    <div id="bodyjob" class="span-24" width="100%">
      <span>Job: <%$namejob%> (<a href="javascript:Baseliner.addNewTabComp('/job/log/list?id_job=<%$idjob%>', _('Log details <%$namejob%>'), { tab_icon: '/static/images/icons/moredata.gif' } );"> log completo </a>)</span>
    </div>
    <div id="bodyjob" class="span-24" width="100%">
      <div id="body" class="span-12 colborder append-bottom">
        <h2>Resumen</h2>
        <!--######INICIO TABLA RESUMEN ###################################################################################-->      
        <table class="summary-table-entornos" width="100%" cellspacing="0">
          <tbody>
            <tr class='last-child'>
              <td class='first-child section-name'>Entorno</td>
              <td class="section-literal"><%$resumen->{bl}%></td>
            </tr>
            <tr class='last-child'>
              <td class='first-child section-name'>Estado</td>
              <td class="section-literal"><%$resumen->{status}%></td>
            </tr>
            <tr class='last-child'>
              <td class='first-child section-name'>Inicio</td>
              <td class="section-literal"><%$resumen->{starttime}?$resumen->{starttime}->dmy:''%></td>
            </tr>
            <tr class='last-child'>
              <td class='first-child section-name'>Fin</td>
              <td class="section-literal"><%$resumen->{endtime}?$resumen->{endtime}->dmy:''%></td>
            </tr>
            <tr class='last-child'>
              <td class='first-child section-name'>Tiempo de Ejecución</td>
              <td class="section-literal"><%$resumen->{execution_time}?$resumen->{execution_time}->min:''%></td>
            </tr>
          </tbody>    
        </table>
        <!--######FIN TABLA RESUMEN #######################################################################################-->
      </div>
      
      <div id="body" class="span-12">
        <h2>Ejecución</h2>
        <!--######INICIO TABLA EJECUCION ##################################################################################-->
        <table class="summary-table-entornos" width="100%" cellspacing="0">
          <thead>
            <tr>
              <th colspan="2" class="section-description">Pasos</th>
            </tr>
          </thead>
          <tbody>
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
        <!--######FIN TABLA EJECUCION ##################################################################################-->
      </div>
    </div>
  </div>
</div>
</div>
</body>
