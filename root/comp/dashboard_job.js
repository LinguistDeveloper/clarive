<%perl>
  use Baseliner::Utils;
  my $idjob = $c->stash->{id_job};
  my $namejob = $c->stash->{name_job};

  my $resumen = $c->stash->{summary};
  my $servicios = $c->stash->{services};
</%perl>
<script language="javascript">
    function render_level ( status, type, rollback ) {
        var icon;
		var bold = false;
		var type   = rec.data.type_raw;
		var rollback = rec.data.rollback;
        if( status=='RUNNING' ) { icon='gears.gif'; bold=true }
        else if( status=='READY' ) icon='log_d.gif';
        else if( status=='APPROVAL' ) icon='verify.gif';
        else if( status=='FINISHED' && rollback!=1 ) { icon='log_i.gif'; bold=true; }
        else if( status=='IN-EDIT' ) icon='log_w.gif';
        else { icon='log_e.gif'; bold=true; }
        value = (bold?'<b>':'') + value + (bold?'</b>':'');

        // Rollback?
        if( status == 'FINISHED' && rollback == 1 )  {
            value += ' (' + _('Rollback OK') + ')';
            icon = 'log_e.gif';
        }
        else if( status == 'ERROR' && rollback == 1 )  {
            value += ' (' + _('Rollback Failed') + ')';
        }
        //else if( type == 'demote' || type == 'rollback' ) value += ' ' + _('(Rollback)');
		if( status == 'APPROVAL' ) { // add a link to the approval main
			value = String.format("<a href='javascript:Baseliner.addNewTabComp(\"{0}\", \"{1}\");'>{2}</a>", "/request/main", _('Approvals'), value ); 
		}
        if( icon!=undefined ) {
            return div1 
                + "<img alt='"+status+"' style='vertical-align:middle' border=0 src='/static/images/"+icon+"' />"
                + value + div2 ;
        } else {
            return value;
        }
    };
</script>

<div id="project" style="padding: 10px 10px 10px 10px;">   
<div id="project" style="width: 98%; padding: 2px 2px 2px 2px;">
  <div class="container body">
    <div id="bodyjob" class="span-24" width="100%">
      <span>Job: <%$namejob%> (<a href="javascript:Baseliner.addNewTabComp('/job/log/list?id_job=<%$idjob%>', _('Log details <%$namejob%>'), { tab_icon: '/static/images/icons/moredata.gif' } );"> log completo </a>)</span>
    </div>
    <br><br><br><br>
    <div id="bodyjob" class="span-24" width="100%">
      <div id="body" class="span-12 colborder append-bottom">
        <!--######INICIO TABLA RESUMEN ###################################################################################-->      
        <table class="summary-table-entornos" cellspacing="0">
          <thead>
            <tr>
              <th class="first-child section-name" colspan="2">Resumen</th>
            </tr>
          </thead>
          <tbody>
            <tr class='last-child'>
              <td class="section-description">Entorno</td>
              <td class="section-literal"><%$resumen->{bl}%></td>
            </tr>
            <tr class='last-child'>
              <td class="section-description">Estado</td>
              <td class="section-literal"><%_loc($resumen->{status})%></td>
            </tr>
            <tr class='last-child'>
              <td class="section-description">Inicio</td>
              <td class="section-literal"><%$resumen->{starttime}?$resumen->{starttime}->dmy.' '.$resumen->{starttime}->hms:''%></td>
            </tr>
            <tr class='last-child'>
              <td class="section-description">Fin</td>
              <td class="section-literal"><%$resumen->{endtime}?$resumen->{endtime}->dmy.' '.$resumen->{endtime}->hms:''%></td>
            </tr>
            <tr class='last-child'>
              <td class="section-description">Tiempo de Ejecución</td>
              <td class="section-literal"><%$resumen->{execution_time}?sprintf("%d",$resumen->{execution_time}->min):''%> min.</td>
            </tr>
          </tbody>    
        </table>
        <!--######FIN TABLA RESUMEN #######################################################################################-->
      </div>
      
      <div id="body" class="span-12">
        <!--######INICIO TABLA EJECUCION ##################################################################################-->

        <!--######FIN TABLA EJECUCION ##################################################################################-->
      </div>
    </div>
  </div>
</div>
</div>
</body>
