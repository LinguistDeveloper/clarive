<%perl>
    use Baseliner::Utils;
    my $idjob = $c->stash->{id_job};
    my $namejob = $c->stash->{name_job};

    my $resumen = $c->stash->{summary};
    my $servicios = $c->stash->{services};
    my $contenido = $c->stash->{contents};
    my $status_id = "status". _nowstamp;
</%perl>


	<div id="project" style="padding: 10px 10px 10px 10px;">   
	<div id="project" style="width: 98%; padding: 2px 2px 2px 2px;">
        <div class="container body">
            <div id="bodyjob" class="span-24" width="100%">
                <span>Job: <%$namejob%> (<a href="javascript:Baseliner.addNewTabComp('/job/log/list?id_job=<%$idjob%>', _('Log details <%$namejob%>'), { tab_icon: '/static/images/icons/moredata.gif' } );"> log completo </a>)</span>
            </div>
            <br><br><br>
            <div id="bodyjob" class="span-24" width="100%">
                <div id="body" class="span-12 colborder append-bottom">
                    <!--######INICIO TABLA RESUMEN ###################################################################################-->
                    <h3>Resumen</h3>
                    <table class="summary-table-resumen" cellspacing="0">
                        <tbody>
                            <tr>
                                <td class="encabezado">Entorno</td>
                                <td class="datos"><%$resumen->{bl}%></td>
                            </tr>
                            <tr>
                                <td class="encabezado">Estado</td>
                                <td class="datos" id="<% $status_id %>"></td>
                            </tr>
                            <tr>
                                <td class="encabezado">Tipo</td>
                                <td class="datos"><%_loc($resumen->{type})%></td>
                            </tr>
                            <tr>
                                <td class="encabezado">Inicio</td>
                                <td class="datos"><%$resumen->{starttime}?$resumen->{starttime}->dmy.' '.$resumen->{starttime}->hms:''%></td>
                            </tr>
                            <tr>
                                <td class="encabezado">Fin</td>
                                <td class="datos"><%$resumen->{endtime}?$resumen->{endtime}->dmy.' '.$resumen->{endtime}->hms:''%></td>
                            </tr>
                            <tr>
                                <td class="encabezado">Tiempo de Ejecución</td>
                                <td class="datos"><%$resumen->{execution_time}?sprintf("%d",$resumen->{execution_time}->min):''%> min.</td>
                            </tr>
                            <tr>
                                <td class="encabezado">Último paso</td>
                                <td class="datos"><%$resumen->{last_step}%></td>
                            </tr>
                            <tr>
                                <td class='encabezado last-child'>Usuario</td>
                                <td class="datos last-child"><%$resumen->{owner}%></td>
                            </tr>
                        </tbody>    
                    </table>
                <!--######FIN TABLA RESUMEN #######################################################################################-->
                </div>
        
                <div id="body" class="span-12">
                    <!--######INICIO TABLA EJECUCION ##################################################################################-->
                    <h3>Ejecución</h3>
                    <table class="summary-table-ejecucion" cellspacing="0">
                        <thead>
                            <tr>
                                <th class="section-ejecucion first-child">Paso</th>
                                <th class="section-ejecucion">Servicio</th>
                                <th class="section-ejecucion last-child">Estado</th>
                            </tr>
                        </thead>
                        <tbody>
<%perl>
    my @steps = ( 'PRE', 'RUN', 'POST', 'END' );
    my $colors = { Success => '#00BB00', Warning => '#00BBBB', Error => '#BB0000'};
    for my $step ( @steps ) {
        if ( $servicios->{$step} ) {
            my @services = _array $servicios->{$step};
            my $tot_services = scalar @services;
        	my $first = 1;
        	for my $service ( @services ) {
        		if ( $first ) {
</%perl>
                            <tr>
                                <td class="section-paso" rowspan="<%$tot_services%>"><% $step %></td>
<%perl>
                    $first = 0;
        		}
</%perl>
                    <td class="datos"><a href="javascript:Baseliner.addNewTabComp('/job/log/list?id_job=<%$idjob%>&service_name=<%$service->{service}%>', _('Log <%$service->{service}%>'), { tab_icon: '/static/images/icons/moredata.gif' } );"><b><% $service->{description} || $service->{service} %></b></a></td>
                    <td class="datos" style="color:<% $colors->{$service->{status}} %>;"><b><% _loc($service->{status}) %></b></td>
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
        
        <div id="bodyjob" class="span-24" width="100%">
            <div id="body" class="span-12 colborder append-bottom">
            <br>
                <!--######INICIO TABLA SALIDA ###################################################################################-->
                <h3>Salida</h3>
                <table class="summary-table-resumen" cellspacing="0">
                    <tbody>
                        <tr>     
                            <td class="encabezado" >Aplicaciones</td>
                            <td class="datos"></td>
                        </tr>
                        <tr>
                            <td class="encabezado" >Paquetes</td>
                            <td class="datos"></td>
                        </tr>
                        <tr>
                            <td class="encabezado">Elementos del pase</td>
                            <td class="datos"></td>
                        </tr>
                        <tr>
                            <td class="encabezado" >Técnologias</td>
                        </tr>
                        <tr>
                            <td class="encabezado last-child" >Tópicos</td>
                            <td class="datos"></td>
                        </tr>
                    </tbody>    
                </table>
            <!--######FIN TABLA SALIDA #######################################################################################-->
            </div>        
            <div id="body" class="span-12  append-bottom">
            <br>
                <!--######INICIO TABLA CONTENIDO ###################################################################################-->
                <h3>Contenido</h3>
                <table class="summary-table-resumen" cellspacing="0">
                    <tbody>
<%perl>
        my @aplicaciones;
        my $tot_aplicaciones;
        if ( $contenido->{packages} ) {
            @aplicaciones = keys %{$contenido->{packages} || {}} ;
            $tot_aplicaciones = scalar @aplicaciones;
        }
</%perl>
                        <tr>     
                            <td class="encabezado" rowspan="<%$tot_aplicaciones%>">Aplicaciones</td>
%       for my $aplicacion (@aplicaciones){
                            <td class="datos"><%$aplicacion%></td>
%       }
                        </tr>
<%perl>
        for my $aplicacion ( @aplicaciones ) {
            if ( $contenido->{packages}->{$aplicacion} ) {
                my @paquetes = _array $contenido->{packages}->{$aplicacion};
                my $tot_paquetes = scalar @paquetes;
                my $first = 1;
                for my $paquete ( @paquetes ) {
                    if ( $first ) {
</%perl>                        
                        <tr>
                            <td class="encabezado" rowspan="<%$tot_paquetes%>">Paquetes</td>
<%perl>
                        $first = 0;
                    }
</%perl>                            
                            <td class="datos"><%$paquete->{name}%>/<%$paquete->{type}%></td>
                        </tr>
<%perl>
                }
            }
        }
</%perl>                        
                        <tr>
                            <td class="encabezado">Elementos del pase</td>
                            <td class="datos"><a href="javascript:Baseliner.addNewTab('/job/log/elements?id_job=<%$idjob%>', _('Elementos de pase'), { tab_icon: '/static/images/icons/moredata.gif' } );"><b>Ver elementos</b>&nbsp;<img border=0 src='/static/images/moredata.gif'/></a></td>
                        </tr>
<%perl>
    my $tot_tecnologias;
    my @tecnologias = _array $contenido->{technologies};
</%perl> 
                        <tr>
                            <td class="encabezado" rowspan="<%$tot_tecnologias%>">Técnologias</td>
%   for my $tecnologia ( @tecnologias ){
                            <td class="datos"><%$tecnologia%></td>
%}
                        </tr>
<%perl>
    my $tot_topicos;
    my @topicos = _array $contenido->{topicos};
</%perl>                        
                        <tr>
                            <td class="encabezado last-child" rowspan="<%$tot_topicos%>">Tópicos</td>
%   if (@topicos){
%       for my $topico ( @topicos){
                            <td class="datos"></td>
%       }
%   }
%   else{
                            <td class="datos last-child">&nbsp;</td>
%   }
                        </tr>
                    </tbody>    
                </table>
            <!--######FIN TABLA CONTENIDO #######################################################################################-->
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
		var tdStatus = document.getElementById('<% $status_id %>');
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
