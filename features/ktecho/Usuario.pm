package BaselinerX::Ktecho::Usuario;
use Moose;
use 5.010;
use Try::Tiny;

has 'harvest_user'     => ( is => 'rw', isa => 'String' );
has 'harvest_password' => ( is => 'rw', isa => 'String' );
has 'refresh'          => ( is => 'rw', isa => 'Bool',   default => undef );
has 'usuario_admin'    => ( is => 'rw', isa => 'Bool',   builder => '_usuario_admin', lazy => 1 );
has 'usuario_ra'       => ( is => 'rw', isa => 'Bool',   default => undef, lazy => 1 );
has 'usuario_rpt'      => ( is => 'rw', isa => 'Bool',   default => undef, lazy => 1 );
has 'usuario_ju'       => ( is => 'rw', isa => 'Bool',   default => undef, lazy => 1 );
has 'usuario_an'       => ( is => 'rw', isa => 'Bool',   default => undef, lazy => 1 );
has 'usuario_pr'       => ( is => 'rw', isa => 'Bool',   default => undef, lazy => 1 );
has 'usuario_sp'       => ( is => 'rw', isa => 'Bool',   default => undef, lazy => 1 );
has 'grupos_rpt' => ( is => 'rw', isa => 'Array' );
has 'v_groups'   => ( is => 'rw', isa => 'Hash', builder => '_v_groups', required => 1 );
has 'groups'     => ( is => 'rw', isa => 'Hash', lazy_build => 1, builder => '_groups' );

# Nota:  En  lugar de  andar con  tanto get/set,  puedo  declarar el  valor de
#  harvest_user  cogiéndolo directamente  de  la  sesión,  en  lugar  de andar
# pasándoselo desde el controlador

sub _usuario_admin {
    my $self = shift;

    if ($self->harvest_user =~ /harvest/i) {
        return 'true';
    }
    else {
        #TODO this.usuario_admin = (new DBSQL()).esUsuarioADMIN(usuario);
    }
}

sub _v_groups {
    my $self = shift;

    try {
        #TODO vector v_groups = (new DBSQL()).getGruposUsuario(getHarusr());
    }
    catch {
        $self->usuario_admin = undef;
    }

    return;
}

sub _groups {
    my $self = shift;

    try {

        #TODO 
=begin  BlockComment  # BlockCommentNo_1

    for ( Enumeration e = v_groups . elements(); e . hasMoreElements(); ) {
        String usergroupname = (String) e . nextElement();
        if ( usergroupname != null ) {
            groups . put( usergroupname . toUpperCase(), "" );
            if ( usergroupname . indexOf("-RA") > -1 ) this . usuario_ra = true;
            if ( usergroupname . indexOf("-PR") > -1 ) this . usuario_pr = true;
            if ( usergroupname . indexOf("-SP") > -1 ) this . usuario_sp = true;
            if ( usergroupname . indexOf("-JU") > -1 ) this . usuario_ju = true;
            if ( usergroupname . indexOf("-AN") > -1 ) this . usuario_an = true;
            if (   usergroupname . indexOf("RPT-") > -1
                && usergroupname . indexOf("-RA") == -1
                && usergroupname . indexOf("-JU") == -1
                && usergroupname . indexOf("-AN") == -1
                && usergroupname . indexOf("-PR") == -1 )
            {
                grupos_rpt . add(usergroupname);
                this . usuario_rpt = true;
            }
        }
    }

=end    BlockComment  # BlockCommentNo_1

=cut

    }
    catch {
        $self->usuario_admin = undef;
    }

    return;
}

sub is_user_in_group {
    my ( $self, $usergroupname ) = @_;

    if ($usergroupname) {
        #TODO return groups.containsKey(usergroupname.toUpperCase());
    }
    else {
        return undef;
    }
}

sub get_refresh {
    my ( $self ) = @_;

=begin  BlockComment  # BlockCommentNo_2

	/**
	 * Obtiene el valor del refresh actual del usuario. 
	 * @param request
	 * @return
	 *    valor del refresh en segundos, o null si no lo tiene. 
	 */
	public String getRefresh(HttpServletRequest request) {
		//Recupera el cookie del refresh
		try {
			if (refresh == null) {
				Cookie c[] = request.getCookies();
				if (c != null) {
					for (int i = 0; i < c.length; i++) {
						if (c[i].getName().equalsIgnoreCase("hardist_refresh")) {
							refresh = c[i].getValue();
							break;
						}
					}
				}
			}
		} catch (Exception e) {
			refresh = null;
		}
		return refresh;
	}

=end    BlockComment  # BlockCommentNo_2

=cut

    return;
}

=begin  BlockComment  # BlockCommentNo_3

#===  FUNCTION  ================================================================
#         NAME:  is_usuario_admin
#      PURPOSE:  Comprueba si el usuario pertenece al grupo ADMIN
#      RETURNS:  true si el usuario pertenece al grupo ADMIN
#  DESCRIPTION:  ????
#       THROWS:  SQLException si se produce un error en la seleccion del grupo
#                de usuario
#===============================================================================
sub is_usuario_admin {
    my $self = shift;

    return $self->usuario_admin;
}

    ==================
    *** IMPORTANTE ***
    ==================

    Lo dejo ahí como referencia, pero a partir de ahora en lugar de coger el
    valor con las funciones se accede directamente al valor (gracias a Moose). 

=end    BlockComment  # BlockCommentNo_3

=cut


		

=begin  BlockComment  # BlockCommentNo_4

		public boolean esUsuarioSistemasUnix() {
			String grupos[] = getGrupos();			// Grupos del usuario
			ArrayList sisUnixCam;

			try {
				sisUnixCam = getAllCAMSSistemasUnix();
			} catch (Exception e) {
				e.printStackTrace();
				return false;		// Si hubiese problemas, no hay Unix que valga
			}

			for(int i=0;i<grupos.length;i++) {
				if (grupos[i].length() >=3) {
					grupos[i] = grupos[i].substring(0, 3);
				} else {
					continue;
				}

				if ( sisUnixCam.contains(grupos[i])) {
				 	return true;
				}
			}

			return false;
		}
		public boolean esUsuarioSistemasUnixRA() {
			String grupos[] = getGrupos();			// Grupos del usuario
			ArrayList sisUnixCam;

			try {
				sisUnixCam = getAllCAMSSistemasUnix();
			} catch (Exception e) {
				e.printStackTrace();
				return false;		// Si hubiese problemas, no hay Unix que valga
			}

			for(int i=0;i<grupos.length;i++) {
				if ( grupos[i].endsWith("-RA") ) {
					grupos[i] = grupos[i].substring(0, grupos[i].length()-3);
				} else {
					continue;
				}

				// Si encontramos algún
				if ( sisUnixCam.contains(grupos[i])) {
				 	return true;
				}
			}
			return false;
		}
		public boolean esUsuarioSistemasUnixAN() {
			String grupos[] = getGrupos();			// Grupos del usuario
			ArrayList sisUnixCam;

			try {
				sisUnixCam = getAllCAMSSistemasUnix();
			} catch (Exception e) {
				e.printStackTrace();
				return false;		// Si hubiese problemas, no hay Unix que valga
			}

			for(int i=0;i<grupos.length;i++) {
				if ( grupos[i].endsWith("-AN") ) {
					grupos[i] = grupos[i].substring(0, grupos[i].length()-3);
				} else {
					continue;
				}

				// Si encontramos algún
				if ( sisUnixCam.contains(grupos[i])) {
				 	return true;
				}
			}

			return false;
		}
		public boolean esUsuarioSistemasUnixPR() {
			String grupos[] = getGrupos();			// Grupos del usuario
			ArrayList sisUnixCam;

			try {
				sisUnixCam = getAllCAMSSistemasUnix();
			} catch (Exception e) {
				e.printStackTrace();
				return false;		// Si hubiese problemas, no hay Unix que valga
			}

			for(int i=0;i<grupos.length;i++) {
				if ( grupos[i].endsWith("-PR") ) {
					grupos[i] = grupos[i].substring(0, grupos[i].length()-3);
				} else {
					continue;
				}

				// Si encontramos algún
				if ( sisUnixCam.contains(grupos[i])) {
				 	return true;
				}
			}

			return false;
		}
		public String[] getGruposRPT() {
		    String[] ret = new String[grupos_rpt.size()];
		    int i=0;
		    for(Enumeration e=grupos_rpt.elements(); e.hasMoreElements(); ) {
		        ret[i++]=e.nextElement().toString();
		    } 
		    return ret;
		}
		public String[] getGrupos() {
		    String[] ret = new String[groups.size()];
		    int i=0;
		    for(Enumeration e=groups.keys(); e.hasMoreElements(); ) {
		        ret[i++]=e.nextElement().toString();
		    } 
		    java.util.Arrays.sort(ret, String.CASE_INSENSITIVE_ORDER);
		    return ret;
		}		
	/**
	 * Asigna el valor del refresh al usuario si es distinto del que actualmente tiene por defecto. 
	 * @param response
	 * 	El response de la página
	 * @param val
	 *  El nuevo valor. Si el valor el -1 o igual al actual, será ignorado.
	 */
	public void setRefresh(HttpServletResponse response, String val) {
		if (val != null && !val.equals(refresh)) {
			//Guarda la cookie del refresco 
			Cookie c_refresh = new Cookie("hardist_refresh", String.valueOf(val));
			c_refresh.setPath("/");
			c_refresh.setMaxAge(60 * 60 * 24 * 365);
			response.addCookie(c_refresh);
		}
	}
	public Hashtable getAllGruposRPTHash(Connection conn) throws Exception {
        Statement stmt=null;
		ResultSet rs =null;
		Hashtable ret = new Hashtable();
        try {
            stmt = conn.createStatement();
            rs = stmt.executeQuery("select plataforma,usergroupname,descr from inf_rpt where not descr is null and not usergroupname like '$%'");
            if( rs.next() ) {
            	do {
            		String gname = rs.getString("usergroupname");
            		String descr  = rs.getString("descr");
            		ret.put(gname, descr);
            	} while(rs.next());
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally  {
            if( rs!=null) rs.close();
            if( stmt!=null) stmt.close();            
        }
        return ret;
	}
	public ArrayList getAllCAMSSistemasUnix() throws Exception {
		// Devuelve un ArrayList con todos los CAM que tienen activada la
		// casilla de Distribución Unix en SCM (SCM_APL_SISTEMAS).
        Statement stmt=null;
		ResultSet rs =null;
		ArrayList ret = new ArrayList();
		Connection conn = null;

        try {
        	conn = DBUtil.createConnection();
            stmt = conn.createStatement();
            rs = stmt.executeQuery("SELECT DISTINCT(CAM) FROM INF_DATA WHERE "
            						+ "ID IN ( SELECT ID FROM INF_DATA id2 WHERE ID IN "
            						+ "		(SELECT MAX(ID) FROM INF_DATA WHERE cam= id2.cam) "
            						+ ") "
            						+ "AND SCM_APL_SISTEMAS='Si'");
            if( rs.next() ) {
            	do {
            		String camName = rs.getString("CAM");
            		ret.add(camName);
            	} while(rs.next());
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally  {
            if( rs!=null) rs.close();
            if( stmt!=null) stmt.close();
            if( conn!=null) {
            	conn.close();
            	conn = null;
            }
        }
        return ret;
	}
	public String[] getAllGruposRPT(Connection conn)  throws Exception {
	    Hashtable hRPT = getAllGruposRPTHash(conn);
	    String[] ret = new String[hRPT.size()];
	    int i=0;
	    for(Enumeration e=hRPT.keys();e.hasMoreElements();) {
	        ret[i++] = e.nextElement().toString();
	    }
	    return ret;
	}
	
	public String toString() {
		StringBuffer aux = new StringBuffer("identificador[");
		aux.append(harvest_user);
		aux.append("] refresco[");
		aux.append(refresh);
		aux.append("]");
		return aux.toString();
	}

}

=end    BlockComment  # BlockCommentNo_4

=cut

1;
