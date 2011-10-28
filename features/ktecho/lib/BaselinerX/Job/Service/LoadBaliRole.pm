package BaselinerX::Job::Service::LoadBaliRole;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use BaselinerX::Comm::Balix;
use Try::Tiny;
use 5.010;
with 'Baseliner::Role::Service';

register 'service.load.bali.job' => {
    name    => 'Carga de roles y relaciones rol-usuario de Baseliner',
    handler => \&index
};

sub index {
    my ( $self, $c ) = @_;
    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

    # Cargo los datos iniciales de bali role para optimizar un poco el proceso
    # y no abusar de regex...
    my $bali_role_rs =
        Baseliner->model('Baseliner::BaliRole')->search( undef, { select => 'role' } );
    rs_hashref($bali_role_rs);
    my @data_role = $bali_role_rs->all;

    # Inicializo...
    my %role;

    # Doy forma al hash...
    for my $ref (@data_role) {
        $role{ $ref->{role} } = q{};
    }

    # Cargo datos de Harvest para rellenar bali_role
    my $sql = qq{
        SELECT hu.username      usuario, 
            hg.usergroupname grupo 
        FROM   harusergroup hg, 
            harusersingroup hug, 
            haruser hu 
        WHERE  hug.usrgrpobjid = hg.usrgrpobjid 
            AND hug.usrobjid = hu.usrobjid 
        ORDER  BY 1  
    };

    # Formato array of hashes...
    my @data = $har_db->db->array_hash($sql);

    # Inicializo...
    my %role_user;

    # Hora de dar forma y otras cosas...
    for my $ref (@data) {

        # Esto variará según lo que me encuentre:
        my $value;

        # Si es RPT...
        if ( substr( $ref->{grupo}, 0, 3 ) eq 'RPT' ) {

            # ... se inserta tal cual en la BD
            Baseliner->model('Baseliner::BaliRole')
                ->update_or_create( { role => $ref->{grupo} }, { key => 'role' } )
                unless exists $role{ $ref->{grupo} };

            $value = $ref->{grupo};
        }
        else {

            # Si tenemos cam y rol explícitos...
            if ( $ref->{grupo} =~ m/-(.+)/xi ) {

                # ... insertamos el rol que nos dan en la BD, si no existe
                Baseliner->model('Baseliner::BaliRole')
                    ->update_or_create( { role => $1 }, { key => 'role' } )
                    unless exists $role{$1};
                $value = $ref->{grupo};
            }
            else {

                # De  lo contrario  puede ser únicamente  un CAM,  por  lo que
                # creamos un nuevo permiso 'readonly'...
                if ( length( $ref->{grupo} ) == 3 ) {

                    # ...  y  lo insertamos en  la BD.  Seguramente  ya exista
                    # pero da igual.
                    Baseliner->model('Baseliner::BaliRole')
                        ->update_or_create( { role => 'RO' }, { key => 'role' } )
                        unless exists $role{'RO'};
                    $value .= "$ref->{grupo}-RO";
                }
                else {

                    # En cambio,  si no es  un cam,  puede ser un permiso tipo
                    # 'Public' o alguna cosa rara de esas.
                    Baseliner->model('Baseliner::BaliRole')
                        ->update_or_create( { role => $ref->{grupo} }, { key => 'role' } )
                        unless exists $role{ $ref->{grupo} };
                    $value = "-$ref->{grupo}";
                }
            }
        }

        # Ahora hacemos del CAM|ROL por cada usuario...
        push @{ $role_user{ $ref->{usuario} } }, $value;
    }

    # Cargo el hash  bali project con formato name => id  de forma que sea más
    # fácil insertar  en la tabla,  ya que lo que  realmente necesitamos es el
    # ID!
    my $bali_project_rs =
        Baseliner->model('Baseliner::BaliProject')->search( undef, { select => [qw/ id name /] } );
    rs_hashref($bali_project_rs);
    my @bali_projects_data = $bali_project_rs->all;
    my %bali_project;
    for my $ref (@bali_projects_data) {
        $bali_project{ $ref->{name} } = $ref->{id};
    }

    # Hacemos lo  mismo con bali_role...  en este caso  tenemos que volverla a
    # llamar ya que los datos del anterior rs no están actualizados.
    $bali_role_rs =
        Baseliner->model('Baseliner::BaliRole')->search( undef, { select => [qw/ role id /] } );
    rs_hashref($bali_role_rs);
    @data_role = $bali_role_rs->all;
    undef %role;
    for my $ref (@data_role) {
        $role{ $ref->{role} } = $ref->{id};
    }

    foreach my $value ( keys %role_user ) {
        foreach ( @{ $role_user{$value} } ) {
            my $username = $value;    # Eso siempre es así
            my $ns       = '/';       # De haber proyecto valdrá 'project/ID'
            my $id_role;
            my $update = 0;           # Si vale 0 no hago update porque petará

            # Si es RPT...
            if ( substr( $_, 0, 3 ) eq 'RPT' ) {
                $id_role = $role{$_};
                $update  = 1;
            }
            else {

                # Si tenemos CAM y ROL...
                if ( $_ =~ m/(.+)-(.+)/xi ) {
                    if ( exists $bali_project{$1} ) {
                        $update  = 1;
                        $id_role = $role{$2};
                        $ns      = "project/$bali_project{$1}";
                    }
                }

                # Si no tenemos CAM... (es general)
                else {
                    $_ =~ m/-(.+)/xi;
                    $id_role = $role{$1};
                    $update  = 1;
                }
            }

            # Inserto en BD...
            Baseliner->model('Baseliner::BaliRoleuser')->create(
                {   username => $username,
                    id_role  => $id_role,
                    ns       => $ns
                }
            ) if $update == 1;
        }
    }

    return;
}

1;
