<%@ page import =  "java.sql.*,
          java.net.*,
          java.util.*,
          java.io.*,
          java.text.*,
          com.ca.hardist.db.*,
          java.util.regex.Pattern,
          java.lang.*"%>
<%@ page import =  "com.ca.hardist.util.*" %>
<%
  Usuario usuario = (Usuario) session.getAttribute("usuario");
  String username = "-"; //nombre de usuario por defecto si no está el objeto (no debería pasar nunca...)
  if( usuario!=null) {
    username=usuario.getHarusr();
  }
  
  String grupos[] = usuario.getGrupos();
  String gruposStr="";
  for(int i=0;i<grupos.length;i++) {
    gruposStr+=grupos[i]+"; "+((i+1) % 10==0?"\\n":"");
  }

  Connection conn = null;
  conn = DBUtil.createConnection();
  Statement bas_stmt = conn.createStatement();
  String bas_sql = "select valor from inf_comun where variable like 'BASELINER_SERVER' or variable like 'BASELINER_PORT' order by variable";
  ResultSet bas_rs = bas_stmt.executeQuery( bas_sql );       
  bas_rs.next();
  String bas_port = bas_rs.getString("VALOR");
  bas_rs.next();
  String bas_server = bas_rs.getString("VALOR");
  bas_rs.close();
  bas_stmt.close();
  conn.close();
  int isDist;
  if (request.getRequestURL().indexOf("scmdist") != -1){
	  isDist = 1;
	  %><link rel="stylesheet" type="text/css" href="header/head_style.css" /><%
  }
  else {
	  isDist = 0;
	  %><link rel="stylesheet" type="text/css" href="../../scmdist/header/head_style.css" /><%
  }
%>

<table class="header" cellpadding="0" cellspacing="0">
	<tr class="banner">
		<td class="head_left"></td><td class="head_right"><img id="form:imagen0" src="header/img/pastillas.gif" /></td>
	</tr>
</table>
<div id="smoothmenu1" class="ddsmoothmenu">
<ul>
<li>
<%if (isDist == 1) {
	   	%><a href="./index2.jsp" id="home"><%
	} else {
		%><a href="../../scmdist/index2.jsp" ><%
	} %>
SCM</a></li>
<li><a href="#">Distribuidor</a>
  <ul>
  <li>
	<%if (isDist == 1) {
	  	%><a href="./monitor.jsp" ><%
	} else {
		%><a href="../../scmdist/monitor.jsp" ><%
	} %>
  Ver Monitor</a></li>
  <li>
	<%if (isDist == 1) {
		%><a href="./pase.jsp"><%
	} else {
		%><a href="../../scmdist/pase.jsp" ><%
	} %>
  Nuevo Pase</a></li>
  </ul>
</li>
<li><a href="#">Changeman</a>
  <ul>
  <li><a href="http://<%=bas_server%>:<%=bas_port%>/tab/job/monitor">Ver Monitor</a></li>
  <li><a href="http://<%=bas_server%>:<%=bas_port%>/tab/job/create">Nuevo Pase</a></li>
  </ul>
</li>
<li><a href="#">Formulario Infraestructura</a>
  <ul>
  <li>
  	<%if (isDist == 1) {
		%><a href="../scm_inf/inf/infTareasRPT.jsp"><%
	} else {
		%><a href="./infTareasRPT.jsp"><%
	} %>
	Peticiones de Infraestructura</a></li>
  <li>
  	<%if (isDist == 1) {
		%><a href="../scm_inf/inf/infMant.jsp"><%
	} else {
		%><a href="./infMant.jsp"><%
	} %>  
  Mantenimiento</a></li>
  </ul>
</li>
<%
  conn = null;
  conn = DBUtil.createConnection();
  Statement user_stmt = conn.createStatement();
  String user_sql = "select valor from inf_comun where variable like 'SQA_URL'";
  ResultSet user_rs = user_stmt.executeQuery( user_sql );       
  user_rs.next();
  String url_list = user_rs.getString("VALOR");
  user_rs.close();
  user_stmt.close();
  conn.close();
 %>
<li><a href="<%=url_list%>">SCM-SQA</a></li>
<%if (isDist == 1) {
		%><li><a href="../scm_inf/inf/infReport.jsp"><%
	} else {
		%><li><a href="./infReport.jsp"><%
	} %>  
Informes</a></li>
<%
	String onClickstr = " onclick='alert(\"Grupos del usuario "+username+":\\n"+gruposStr+"\");'";
%>
<li class="time_user"><a href="#" <%=onClickstr%>>
<%
     Locale local = new Locale("es", "ES");
     SimpleDateFormat fmt = new SimpleDateFormat("EEE, d MMMM yyyy", local);
     java.util.Date dtnow = new java.util.Date();
     Calendar now = new GregorianCalendar();
     fmt.setCalendar(now);
     out.print(fmt.format(now.getTime()));
%>
(<%=username%>)</a>
</li>
</ul>
<br style="clear: left" />
</div>