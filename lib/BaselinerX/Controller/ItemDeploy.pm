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
    _log _dump $p;
    $p = {
        map {
            my $k = $_;
            my $v = $p->{$_};
            $v = $k eq 'active' ? $v : try { JSON::XS::decode_json( $v ) } catch { $v }; 
            $k => $v
        } keys %$p
    };
    $p->{active} = $p->{active} =~ /on|true/ ? 1 : 0;
    $p->{no_paths} = $p->{no_paths} =~ /on|true/ ? 1 : 0;
    $p->{path_deploy} = $p->{path_deploy} =~ /on|true/ ? 1 : 0;
    $c->stash->{json} = try {
        my $ns = delete $p->{id} || $p->{ns}; 
        # check if regex compiles ok
        try {
            qr/$p->{workspace}/;
            qr/$_/ for @{ $p->{include} || [] };
            qr/$_/ for @{ $p->{exclude} || [] };
        } catch {
            my $err = shift;
            $err=~s{ at /.*$}{}g;
            _fail _loc( "Error in regex: %1", $err );
        };
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
use constant catalog_url_save => '/itemdeploy/submit';

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
        # checkboxes
        $d->{active} = defined $d->{active} && !$d->{active} ? \0 : \1; # defaults to false
        $d->{no_paths} = defined $d->{no_paths} && $d->{no_paths} ? \1 : \0; # defaults to true
        $d->{path_deploy} = defined $d->{path_deploy} && !$d->{path_deploy} ? \0 : \1; # defaults to false
        next if $p{query} && join('',%$d) !~ $query;
        push @list, {
            row         => { $r->get_columns, %$d }, # this gets sent to form
            name        => $d->{name}, 
            active      => $d->{active}, 
            description => $d->{description}, 
            id          => $r->ns,
            ns          => $r->ns,
            project     => $d->{project},
            bl          => $d->{bl} || '*',
            for => {
                workspace => _html_escape( $d->{workspace} ),
                include   => _html_escape( join( ',', _array $d->{include} ) ),
                exclude   => _html_escape( join( ',', _array $d->{exclude} ) ),
            },
            mapping => {
                destination    => _html_escape( join( ', ', _array $d->{deployments} ) ),
                scripts_multi  => $d->{scripts_multi},
                scripts_single => $d->{scripts_single}
            },
        };
    }
    return wantarray ? @list : \@list;
}


1;

