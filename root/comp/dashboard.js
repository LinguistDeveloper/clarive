<%perl>
    my @jobs = $c->stash->{jobs};
    my $idjob = '';
    my @emails = $c->stash->{emails};
    my $style = '';
</%perl>

<link rel="stylesheet" type="text/css" href="/site/project/project.css" />
<style>
#project h1, h2, h3, h4, h5, h6 {font-weight:normal;color:#111;}
#project h1 {font-size:3em;line-height:1;margin-bottom:0.5em;}
#project h2 {font-size:2em;margin-bottom:0.75em;}
#project h3 {font-size:1.5em;line-height:1;margin-bottom:1em;}
#project h4 {font-size:1.2em;line-height:1.25;margin-bottom:1.25em;}
#project h5 {font-size:1em;font-weight:bold;margin-bottom:1.5em;}
#project h6 {font-size:1em;font-weight:bold;}
#project h1 img, h2 img, h3 img, h4 img, h5 img, h6 img {margin:0;}

#project .span-18 {width:710px;}
#project .border {padding-right:4px;margin-right:5px;border-right:1px solid #eee;}
#project .colborder {padding-right:24px;margin-right:25px;border-right:1px solid #eee;}
#project .prepend-top {margin-top:1.5em;}
#project .append-bottom {margin-bottom:1.5em;}
#project .box {padding:1.5em;margin-bottom:1.5em;background:#E5ECF9;}

#project .container {width:100%; margin:0 auto;}   /* bali full width to the right */
#project .showgrid {background:url(src/grid.png);}
#project .column, .span-1, .span-2, .span-3, .span-4, .span-5, .span-6, .span-7, .span-8, .span-9, .span-10, .span-11, .span-12, .span-13, .span-14, .span-15, .span-16, .span-17, .span-18, .span-19, .span-20, .span-21, .span-22, .span-23, .span-24 {float:left;margin-right:10px;}
#project .last {margin-right:0;}

/* A font by Jos Buivenga (exljbris) -> http://www.exljbris.nl */
@font-face {
  font-family: "museo sans 500";
  src: url("/static/fonts/museo_sans_500.otf");
}

#project html {
  height: 100%;
  margin-bottom: 1px;
}

#project tr, td, body {
  font-family: "Lucida Grande", "Lucida Sans Unicode", Verdana, Geneva, sans-serif;
  font-size: 11px;
}

#project h1, h2 {
  font-family: "museo sans 500", "Helvetica Neue", Helvetica, Verdana, Arial, sans-serif;
  text-rendering: optimizeLegibility;
}

#project h3, h4, h5, h6 {
  font-family: "Helvetica Neue", Helvetica, Verdana, Arial, sans-serif;
  text-rendering: optimizeLegibility;
}

#project tfoot {
  font-style: normal;
}


ul.errors {
    color: #000;
    background: #fff url(/images/information.png) center no-repeat;
    background-position: 15px 50%;
    float: right;
    width: 580px;
    text-align: left;
    padding: 5px;
    padding-top: 10px;
    padding-bottom: 10px;
    margin: 0px;
    margin-bottom: 20px;
    list-style: none;
    border: 2px solid #2a6fb5;
}

ul.errors li {
    padding-left: 40px;
}

/*
    Pagination Styles 
*/

#project .pagination {
    font-size: 100%;
    text-align: center;
    padding: 3px;
    margin: 3px;
}
#project .pagination a {
    padding: 2px 5px 2px 5px;
    margin: 2px;
    text-decoration: none;
    color: #44a4f0;
}
#project .pagination a:hover, .pagination a:active {
    background-color: #44a4f0;
    color: #fff;
}
#project .pagination span.current {
    font-size: 100%;
    padding: 2px 5px 2px 5px;
    margin: 2px;
    font-weight: bold;
    padding: 2px 5px 2px 5px;
    background-color: #fff;
    color: #000;
}
#project .pagination span.disabled {
    font-size: 100%;
    padding: 2px 5px 2px 5px;
    margin: 2px;
    color: #ccc;
}

#reset {
    clear: both;
    margin: 0;
    padding: 0;
}



#project .data-desc {
    font-size: 10px;
}

#project .data-desc, .submit-time {
  font-weight: normal;
    color: #777;
}

#project .submit-time {
  text-align: right;
}

#project .user-icon {
  padding: 8px;
  padding-right: 12px;
  background: url('/images/simplebits/black/user.gif') no-repeat 50% 50%;
}

#project .flag-icon {
  padding: 8px;
  background: url('/images/simplebits/red/flag.gif') no-repeat 50% 50%;
}

#project .info-icon {
  padding: 8px;
  background: url('/images/simplebits/blue/info.gif') no-repeat 50% 50%;
}

#project .delete-icon {
  padding: 8px;
  background: url('/images/simplebits/black/trash.gif') no-repeat 50% 50%;  
}

#project .export-icon {
  padding: 8px;
  background: url('/images/simplebits/black/disk.gif') no-repeat 50% 50%;  
}

#project .black-flag-icon {
  padding: 8px;
  background: url('/images/simplebits/black/flag.gif') no-repeat 50% 50%;  
}

#project .chart-icon {
  padding: 8px;
  background: url('/images/simplebits/black/bargraph.gif') no-repeat 50% 50%;  
}

#project .camera-icon {
  padding: 8px;
  background: url('/images/simplebits/black/camera.gif') no-repeat 50% 50%;  
}

#project .lock-icon {
  padding: 8px;
  background: url('/images/simplebits/black/locked.gif') no-repeat 50% 50%;  
}

#project .lock-red-icon {
  padding: 8px;
  padding-right: 12px;
  background: url('/images/simplebits/red/locked.gif') no-repeat 50% 50%;
}

#project .unlock-icon {
  padding: 8px;
  background: url('/images/simplebits/black/unlocked.gif') no-repeat 50% 50%;  
}

#project .facebook-icon {
  padding: 8px;
  background: url('/images/social/facebook.png') no-repeat 50% 50%;  
}

#project .twitter-icon {
  padding: 8px;
  background: url('/images/social/twitter.png') no-repeat 50% 50%;  
}

#project .data-bar {
    background-color: #44a4f0;
    background-image: url(/static/images/project/graph-background.png);
    height: 30px;
}

#project .alt .data-bar {
    background-color: #c0fd6b;
    background-image: url(/static/images/project/graph-background2.png);
}

#project .error .data-bar {
    background-color: #44a4f0;
    background-image: url(/static/images/project/graph-background-red.png);
    height: 30px;
}

#project .warn .data-bar {
    background-color: #c0fd6b;
    background-image: url(/static/images/project/graph-background-yellow.png);
}

#project .summary-table * .data-bar {
  height:20px;
}

/*
    Table Styles
*/

.browse_table, .summary-table, .system-table, .data-table {
    width: 480px;  /* bali table */
}

.browse_table {
  margin-bottom: 9px;
}

.system-table, .data-table {
    margin-bottom: 9px;
}

.summary-table {
  margin-bottom: 9px;
}

.summary-explanation {
  font-size: 120px;
  text-align: right;
  margin-bottom: 10px;
}

.browse_table * th, .summary-table * th, .system-table * th, .data-table * th {
    padding: 8px;
    line-height: 1.5em;
    text-align: left;
    font-weight: bold;
}

.browse_table * td, .summary-table * td, .system-table * td, .data-table * td {
    padding: 6px;
    line-height: 1.2em;
}

.browse_table * td {
  line-height: 1.1em;
}

/*
    Summary Table
*/

.summary-table * th {
  background-color: #f0f0f0;
}

.summary-table * .section-name {
    width: 20%;
}

.summary-table * .section-graph {
    width: 60%;
}

.summary-table * .section-score {
  width: 15%;
}

.summary-table * th {
    border-top: #ccc 1px solid;
    
    border-bottom: #ccc 1px solid;
}

.summary-table * th.first-child {
    border-left: #ccc 1px solid;
}

.summary-table * th.last-child {
    border-right: #ccc 1px solid;
}

.summary-table * td.first-child, .summary-table * td.last-child {
    border-left: #ccc 1px solid;
    border-right: #ccc 1px solid;
}

.summary-table * tr.last-child td {
    border-bottom: #ccc 1px solid;
}

.summary-table * tr.first-child td {
    border-top: #ccc 1px solid;
}

.summary-table * td.section-name {
    background-color: #f0f0f0;
}

.summary-table * td.section-description {
  width: 15%;
}

.summary-table * td.section-score {
  width: 15%;
    text-align: center;
}

.browse_table * td.overall-score, .summary-table * td.overall-score {
  width: 25%;
  font-family: "museo sans 500", Helvetica Neue, Helvetica, Arial, sans-serif;
    font-size: 48px;
    text-align: center;
    vertical-align: middle;
    border-right: #ccc 1px solid;
    border-bottom: #ccc 1px solid;
}

.browse_table * td.overall-score {
  font-size: 42px;
}

.summary-table tfoot * td {
    border-left: #ccc 1px solid;
    border-right: #ccc 1px solid;
    border-bottom: #ccc 1px solid;
}

/*
    Browse Table and System Table
*/

.browse_table, .system-table {
    border-collapse: collapse;
    border: #ccc 1px solid;
}

.system-table * td {
}

.browse_table * .system-name, .browse_table * .header, .system-table * .system-name {
    background-color: #f0f0f0;
}


.browse_table * th {
  font-weight: bold;
  background-color: #f0f0f0;
  border-bottom: #ccc 1px solid;
}

.browse_table * .overall-score {
  border-left: #ccc 1px solid;
}

.browse_table * .header {
  font-weight: bold;
  border: #ccc 1px solid;
}

.browse_table * .system-name, .browse_table * .overall-score {
  width: 25%;
} 

.browse_table * .system-information-header {
  border-right-width: 0px;
  width: 75%;
} 

.browse_table * .overall-score-header {
  border-left-width: 0px;
}

.system-table * .system-name {
  width: 20%;
}

.system-table * .system-value {
  border: #ccc 1px solid;
}

.browse_table * .last-child  {
  border-bottom: #ccc 1px solid;
}

.browse_table * .system-link {
  font-weight: bold;
}

/* 
    data Table
*/

.data-table {
    border-collapse: collapse;
    border: #ccc 1px solid;                 
}

.data-table * th {
    background-color: #fff !important;
    border-width: 0px 0px 1px 0px !important; 
    border-bottom: #ccc 1px solid !important;
    font-size: 125%;
}

.data-table * .data-name {
    width: 35%;
    background-color: #f0f0f0;
}

.data-table * .data-score {
    border-top: #ccc 1px solid;
    border-left: #ccc 1px solid;                                        
    border-bottom: #ccc 1px solid;                  
    width: 15%;
}

.data-table * .data-graph {
    border-top: #ccc 1px solid;
    border-right: #ccc 1px solid;                                       
    border-bottom: #ccc 1px solid;                                      
    width: 60%;
}
</style>

<div id="project" style="width: 90%; padding: 2px 2px 2px 2px;">
  <div class="container body">
    <div id="body">
    <h2>�ltimos Pases</h2>

<table class="summary-table" width="500px" cellspacing="0">
    <thead>
        <tr>
            <th colspan="2" class="first-child section-name">C�digo de pase</th>
            <th class="section-description">Aplicaci�n</th>
            <th class="section-description">Estado</th>
            <th class="last-child section-name">Entorno</th>
        </tr>
    </thead>

<!--    <tfoot>
        <tr>
            <td colspan="4">
                Baseliner 5.0.2 for AIX 5.3 64-bit gcc
            </td>
        </tr>
    </tfoot>-->

    <tbody>

%foreach my $job (_array @jobs){
% if ($idjob != $job->{id_job}){
        <tr class='<%$style%>'>
        <td class='data_table' colspan='2'><b><a href='javascript:Baseliner.openLogTab(<%$job->{id_job}%>, "<%$job->{name}%>")' style="font-family: Tahoma;"><%$job->{name}%></a></b></td>
        <td class='section-description'><%$job->{project}%></td>
        <td class='section-description'><%$job->{status}%></td>
        <td class='section-description'><%$job->{bl}%></td>
        </tr>
% }else{
        <tr>
        <td class='data_table' colspan='2'></td>
        <td class='section-description'><%$job->{project}%></td>
        <td class='section-description'></td>
        <td class='section-description'></td>
        </tr>
%}
% $idjob = $job->{id_job};
% $style = 'first-child'
%}
        <tr class='first-child'>
            <td class='data_table' colspan='5'>&nbsp;</td>
        </tr>
        
    </tbody>    
        

</table>
</div>


    <!--<div class="span-6 colborder prepend-top append-bottom" id="body">-->
    <div id="body">
    <h2>�ltimos mensajes no le�dos</h2>

<table class="summary-table" width="500px" cellspacing="0">
    <thead>
        <tr>
            <th colspan="3" class="first-child section-name">Asunto</th>
            <th class="section-description">De</th>
            <th class="last-child section-name">Enviado</th>
        </tr>
    </thead>

<!--    <tfoot>
        <tr>
            <td colspan="4">
                Baseliner 5.0.2 for AIX 5.3 64-bit gcc
            </td>
        </tr>
    </tfoot>-->

    <tbody>

%foreach my $email (_array @emails){
        <tr class='last-child'>
        <td class='data_table' colspan='3'><b><a href="javascript:Baseliner.addNewTabComp('/message/inbox?username=<%$c->username%>&query=<%$email->{id}%>', _('Inbox') );" style="font-family: Tahoma;"><%$email->{subject}%></a></b></td>
        <td class='section-description'><%$email->{sender}%></td>
        <td class='section-description'><%$email->{sent}%></td>
        </tr>
%}


   </tbody>
        

</table>
</div>

</div>
</div>
