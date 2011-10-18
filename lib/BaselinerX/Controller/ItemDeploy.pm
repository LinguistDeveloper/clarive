package BaselinerX::Controller::ItemDeploy;
use Moose;
use Try::Tiny;
use Baseliner::Utils;
use Baseliner::Sugar;

BEGIN { extends 'Catalyst::Controller' }
__PACKAGE__->config->{namespace} = 'itemdeploy';

use constant DOMAIN => 'deploy.item';

sub submit : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->params;
    # detect and decode json in certain fields
    $p = {
        map {
            my $k = $_;
            my $v = $p->{$_};
            $v = try { JSON::XS::decode_json( $v ) } catch { $v }; 
            $k => $v
        } keys %$p
    };
    $p->{output_retrieve} = $p->{output_retrieve} eq 'on' ? \1 : \0;
    _log _dump $p;
    $c->stash->{json} = try {
        my $ns = delete $p->{id}; 
        kv->set(
            $ns ?  (ns=>$ns) : ( provider=> DOMAIN ),
            data => $p
        );
        { msg=>'ok', success=>\1 };
    } catch {
        my $err = shift;
        _log "ERROR saving data: $err";
        { msg=>$err, success=>\0 };
    };
    $c->forward('View::JSON');
}

# catalog role methods 

with 'Baseliner::Role::Catalog';

use constant catalog_name => 'Deploy Job Items';
use constant catalog_icon => '/static/images/icons/page_copy.gif';
use constant catalog_description => 'Deploy Job Items';
use constant catalog_url => '/comp/catalog/item_deploy.js';

sub catalog_add { }
sub catalog_del { 
    my ($class, %p)=@_;
    $p{id} or _throw 'Missing id';
    kv->delete( ns=>$p{id} );
}
sub catalog_list { 
    my ($class, %p)=@_;
    my @list;
    my $query = qr/$p{query}/i;
    my $rs = kv->find( provider => DOMAIN );
    while( my $r = $rs->next ) {
        my $d = $r->kv;
        !$d->{output_retrieve} and $d->{output_retrieve} = \0;
        next if $p{query} && join('',%$d) !~ $query;
        push @list, {
            row         => { $r->get_columns, %$d },
            name        => $d->{name}, 
            description => $d->{description}, 
            id          => $r->ns,
            ns          => $r->ns,
            project     => $d->{project},
            bl          => $d->{bl} || '*',
            for         => { workspace=>$d->{workspace},
                include=>join(',', _array $d->{include}),
                exclude=>join(',', _array $d->{exclude}),
            },
            mapping     => { destination=>join(', ', _array $d->{deployments}),
                scripts_multi=>$d->{scripts_multi}, scripts_single=>$d->{scripts_single} },
        };
    }
    return wantarray ? @list : \@list;
}


1;

