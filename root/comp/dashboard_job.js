<%perl>
  use Baseliner::Utils;
  my $idjob = $c->stash->{id_job};
  my $namejob = $c->stash->{name_job};

  my $resumen = $c->stash->{summary};
  my $servicios = $c->stash->{services};
</%perl>

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
	            <tr>
	              <td class="section-literal">Entorno</td>
	              <td class="section-literal"><%$resumen->{bl}%></td>
	            </tr>
	            <tr>
	              <td class="section-literal">Estado</td>
	              <td class="section-literal" id="dashboard_status"></td>
	            </tr>
	            <tr>
	              <td class="section-literal">Tipo</td>
	              <td class="section-literal"><%_loc($resumen->{type})%></td>
	            </tr>
	            <tr>
	              <td class="section-literal">Inicio</td>
	              <td class="section-literal"><%$resumen->{starttime}?$resumen->{starttime}->dmy.' '.$resumen->{starttime}->hms:''%></td>
	            </tr>
	            <tr>
	              <td class="section-literal">Fin</td>
	              <td class="section-literal"><%$resumen->{endtime}?$resumen->{endtime}->dmy.' '.$resumen->{endtime}->hms:''%></td>
	            </tr>
	            <tr>
	              <td class="section-literal">Tiempo de Ejecución</td>
	              <td class="section-literal"><%$resumen->{execution_time}?sprintf("%d",$resumen->{execution_time}->min):''%> min.</td>
	            </tr>
	            <tr>
	              <td class="section-literal">Último paso</td>
	              <td class="section-literal"><%$resumen->{last_step}%></td>
	            </tr>
	            <tr class='last-child'>
	              <td class="section-literal">Usuario</td>
	              <td class="section-literal"><%$resumen->{owner}%></td>
	            </tr>
	          </tbody>    
	        </table>
	        <!--######FIN TABLA RESUMEN #######################################################################################-->
	      </div>
	      
	      <div id="body" class="span-12">
	        <!--######INICIO TABLA EJECUCION ##################################################################################-->
	        <table class="summary-table-entornos" cellspacing="0" style="height:50px;">
	          <thead>
	          	<tr>
	              <th class="first-child section-name" colspan="3">Servicios</th>
	            </tr>
	            <tr>
	              <th class="section-description">Servicio</th>
	              <th class="section-description">Estado</th>
	            </tr>
	          </thead>
	          <tbody>
<%perl>
    my @steps = ( 'PRE', 'RUN', 'POST', 'END' );
    my $colors = { Success => '#00BB00', Warning => '#00BBBB', Error => '#BB0000'};
    for my $step ( @steps ) {
        if ( $servicios->{$step} ) {
        	my $first = 1;
        	for my $service ( _array $servicios->{$step} ) {
        		if ( $first ) {
</%perl>
	            <tr>
	              <th class="section-description" colspan="2"><% $step %></th>
	            </tr>
<%perl>
        			$first = 0;
        		}

</%perl>
	            <tr>
	              <td class="section-literal"><% $service->{service} %></td>
	              <td class="section-literal" style="color:<% $colors->{$service->{status}} %>;"><b><% _loc($service->{status}) %></b></td>
	            </tr>
<%perl>

        	}
        }
    }
</%perl>
	          </tbody>    
	        </table>
	        <!--######FIN TABLA EJECUCION ##################################################################################-->
	      </div>
	    </div>
	  </div>
	</div>
	</div>
<script language="javascript">
    function render_level ( ) {
        var icon;
		var bold = false;
		var status = "<% $resumen->{status} %>";
		var type   = '<% $resumen->{type} %>';
		var rollback = '<% $resumen->{rollback} %>';
		var div1   = '<div style="white-space:normal !important;">';
    	var div2   = '</div>';
        if( status=='RUNNING' ) { icon='gears.gif'; bold=true }
        else if( status=='READY' ) icon='log_d.gif';
        else if( status=='APPROVAL' ) icon='verify.gif';
        else if( status=='FINISHED' && rollback!=1 ) { icon='log_i.gif'; bold=true; }
        else if( status=='IN-EDIT' ) icon='log_w.gif';
        else { icon='log_e.gif'; bold=true; }
        var value = (bold?'<b><% _loc($resumen->{status}) %></b>':'<% _loc($resumen->{status}) %>');

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
    	//alert(icon);
		var tdStatus = document.getElementById('dashboard_status');
        if( icon!=undefined ) {
            tdStatus.innerHTML = div1 
                + "<img alt='"+status+"' style='vertical-align:middle' border=0 src='/static/images/"+icon+"' />"
                + value + div2 ;
        } else {
            tdStatus.innerHTML = value;
        }
    };
    render_level();
</script>