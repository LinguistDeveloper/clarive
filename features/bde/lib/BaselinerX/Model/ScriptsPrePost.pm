package BaselinerX::Model::ScriptsPrePost;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use BaselinerX::Comm::Balix;
use 5.010;
BEGIN { extends 'Catalyst::Model' }

#sub scripts_pre {
#    my ( $self, $args_ref ) = @_;
#    my $env_name = $args_ref->{env_name};
#    my $env      = $args_ref->{env};
#    my $sufijo   = $args_ref->{sufijo};
#
#    $self->scripts_prepost(
#        {   prepost  => 'PRE',
#            env_name => $env_name,
#            env      => $env,
#            sufijo   => $sufijo
#        }
#    );
#
#    return;
#}
#
#sub scripts_post {
#    my ( $self, $args_ref ) = @_;
#    my $env_name = $args_ref->{env_name};
#    my $env      = $args_ref->{env};
#    my $sufijo   = $args_ref->{sufijo};
#
#    $self->scripts_prepost(
#        {   prepost  => 'POST',
#            env_name => $env_name,
#            env      => $env,
#            sufijo   => $sufijo
#        }
#    );
#
#    return;
#}

sub get_script_list {
    my ( $self, $args_ref ) = @_;
    my $cam_uc  = $args_ref->{cam};
    my $env     = $args_ref->{env};
    my $nat     = $args_ref->{sufijo};
    my $prepost = $args_ref->{prepost};

    my $sql = qq{
        SELECT Trim(pp_orden), 
            Trim(pp_exec), 
            Trim(pp_maq), 
            Trim(pp_usu), 
            Trim(pp_block), 
            Trim(pp_os), 
            Trim(pp_errcode) 
        FROM   bde_paquete_prepost 
        WHERE  Trim(pp_cam) = Trim('$cam_uc') 
            AND Upper(Trim(pp_env)) = Upper(Trim('$env')) 
            AND Upper(Trim(pp_prepost)) = '$prepost' 
            AND Upper(Trim(pp_naturaleza)) = '$nat' 
            AND Upper(pp_activo) = 'S' 
        ORDER  BY pp_orden  
    };

    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
    return $har_db->db->hash($sql);
}

sub get_map {
    my ($raw) = @_;
    my %MAP = ();
    my @MAP = split /\|/, $raw;
    my %CNT = ();
    foreach my $map (@MAP) {
        my ( $orden, $nat, $exec, $maq, $usu, $block ) = split /; */, $map;
        if ($exec) {
            $maq =~ s/^(.*?)\(.*/$1/g;
            my $key = $orden;
            if ( $CNT{$orden} ) {
                $key = sprintf( "%d-%02d", $orden, $CNT{$orden} );
            }
            $CNT{$orden} += 1;
            push @{ $MAP{$key} }, ( $orden, $nat, $exec, $maq, $usu, $block );
        }
    }
    return %MAP;
}

1;
