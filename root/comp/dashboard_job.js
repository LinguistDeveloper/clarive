<%perl>
    use Baseliner::Utils;
    my $idjob = $c->stash->{id_job};
    my $namejob = $c->stash->{name_job};
    my $status_id = "status". _nowstamp;
    my $details_file_id = "details_file". _nowstamp;
    
    my $resumen = $c->stash->{summary};
    my $servicios = $c->stash->{services};
    my $contenido = $c->stash->{contents};
    my $salida = $c->stash->{outputs};

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
                                <td class="datos"><%$resumen->{execution_time}?sprintf("%s",$resumen->{execution_time} < 60? ($resumen->{execution_time}->sec . ' seg.') : ($resumen->{execution_time}->min) . ' min.'):''%></td>
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
                                <th class="section-ejecucion first-child">&nbsp;</th>
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
                <script language="javascript">
                    var onemeg = 1024 * 1024;
                    function file(obj, td_id) {
                            var ret="";
                            var xdatalen = obj.datalen;
                            var datalen='';
                            if( xdatalen > 4096 ) {
                                if( xdatalen >= onemeg ) {
                                   datalen = Math.round( (xdatalen/onemeg) * 10) / 10;
                                   datalen += 'MB';
                                } else {
                                   datalen = Math.round( (xdatalen/1024) * 10) / 10;
                                   datalen += 'KB';
                                }
                            }
                        
                            if( obj.more=='jes' ) {
                                ret += "<a href='#' onclick='javascript:Baseliner.addNewTabComp(\"/job/log/jesSpool?id=" + obj.id + "&job=" + rec.data.job +"\");'><img border=0 src='/static/images/mainframe.png' /></a> ";
                            } else if( obj.more=='link'  ) {
                                //Ojo con obj.data en este caso, verificar.++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                                ret += String.format("<a href='{0}' target='_blank'><img src='/static/images/icons/link.gif'</a>", obj.link );
                            } else if( obj.more!='' && obj.more!=undefined && obj.data ) {
                                var img;
                                if( obj.more=='zip' ) {
                                   img = '/static/images/icons/mime/file_extension_zip.png';
                                } else {
                                   img = '/static/images/download.gif';
                            } 
                                ret += "<a href='/job/log/download_data?id=" + obj.id + "' target='FrameDownload'><img border=0 src="+img+" /></a> " + datalen ;
                            } else {
                                if( obj.more!='file' && obj.data && xdatalen < 250000 ) {  // 250Ks max
                                    var data_name = obj.data_name;
                                    if( data_name==undefined || data_name.length<1 ) {
                                       data_name = "Log Data " + obj.id;
                                    }
                                    ret += "<a href='#' onclick='javascript:Baseliner.addNewTabSearch(\"/job/log/data?id=" + obj.id + "\",\""+data_name+"\"); return false;'><img border=0 src='/static/images/moredata.gif'/></a> " + datalen ;
                                }
                                else if( obj.file!=undefined && obj.file!='' && obj.data ) { // alternative file
                                    ret += "<a href='/job/log/highlight/" + obj.id + "' target='_blank'><img border=0 src='/static/images/silk/page_new.gif'></a> "
                                    ret += "&nbsp;<a href='/job/log/download_data?id=" + obj.id + "&file_name=" + obj.file + "' target='FrameDownload'><img border=0 src='/static/images/download.gif'/></a> " + datalen ;
                                }
                            }
                            var td_details_file = document.getElementById(td_id);
                            td_details_file.innerHTML = ret || '&nbsp';;
                    };
                </script>
                
                <table class="summary-table-salida" cellspacing="0">
                    <thead>
                        <tr>
                            <th class="section-ejecucion first-child last-child" colspan="2">Ficheros generados</th>
                        </tr>
                    </thead>                
                    <tbody>
<%perl>
    my @ficheros = _array $salida->{outputs};
    my $data;
    my $row = 0;
	for my $fichero (@ficheros){
        $row = $row + 1;
        if ($fichero->{more}->{data}){
            $data = 1;
</%perl>
                        <tr>     
                            <td class="datos"><%$fichero->{more}->{data_name} || $fichero->{more}->{file} %></td>
                            <td class="link" id="row<%$row%>_<%$details_file_id%>" width=25%>&nbsp;</td>
                        </tr>
                        <script language="javascript">
                            var details_file = new Object();
                            details_file.id = <%$fichero->{id}%>;
                            details_file.data_name = '<%$fichero->{data_name}%>';
                            details_file.datalen = <%$fichero->{datalen}%>;
                            details_file.more = '<%$fichero->{more}->{more}%>';
                            details_file.data = <%$data%>;
                            details_file.file = '<%$fichero->{more}->{file}%>';
                            details_file.link = '<%$fichero->{more}->{link}%>';
                            file(details_file, 'row<%$row%>_<%$details_file_id%>');
                        </script>                        
<%perl>                        
        }
	}                
</%perl>                        
                    </tbody>    
                </table>
            <!--######FIN TABLA SALIDA #######################################################################################-->
            </div>        
            <div id="body" class="span-12  append-bottom">
            <br>
                <!--######INICIO TABLA CONTENIDO ###################################################################################-->
                <h3>Contenido</h3>
                <table class="summary-table-contenido" cellspacing="0">
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
%       my $first = 1;                            
%       for my $aplicacion (@aplicaciones){
%                   if ( $first ) {    
                            <td class="datos first-child"><%$aplicacion%></td>
%                       $first = 0;
%                   }
%                   else {
                            <td class="datos"><%$aplicacion%></td>
%                   }                            
                        </tr>
%       }
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
                            <td class="encabezado" rowspan="<%$tot_paquetes%>">Paquetes (<% $aplicacion %>)</td>
<%perl>
                        $first = 0;
                    }
</%perl>                            
                            <td class="datos"><%$paquete->{type}%>/<%$paquete->{name}%></td>
                        </tr>
<%perl>
                }
            }
        }
</%perl>                        
                        <tr>
                            <td class="encabezado">Elementos del pase</td>
                            <td class="datos"><a href="javascript:Baseliner.addNewTab('/job/log/elements?id_job=<%$idjob%>', _('Elementos <%$namejob%>'), { tab_icon: '/static/images/icons/moredata.gif' } );"><b>Ver elementos</b>&nbsp;<img border=0 src='/static/images/moredata.gif'/></a></td>
                        </tr>
<%perl>
    my $tot_tecnologias;
    my @tecnologias = _array $contenido->{technologies};
    $tot_tecnologias = scalar @tecnologias;
</%perl> 
                        <tr>
                            <td class="encabezado" rowspan="<%$tot_tecnologias%>">Técnologias</td>
%   for my $tecnologia ( @tecnologias ){
                            <td class="datos">
                                <%$tecnologia%><br>
                            </td>

                        </tr>
%}
<%perl>
    my $tot_topicos;
    my @topicos = _array $contenido->{topics};
    $tot_topicos = scalar @topicos;
</%perl>                        
                        <tr>
                            <td class="encabezado last-child" rowspan="<%$tot_topicos%>">Tópicos</td>
%   if (@topicos){
%       for my $topico ( @topicos){
                            <td class="datos"><b><a href="javascript:Baseliner.addNewTabComp('/issue/grid?query=<%$topico->{id}%>', _('Issues'));"><% $topico->{title} %></a></b></td>
                        </tr>
%       }
%   }
%   else{
                            <td class="datos">&nbsp;</td>
                        </tr>
%   }
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
