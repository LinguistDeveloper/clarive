package BaselinerX::Controller::ManualDeploy;
use Baseliner::Plug;
BEGIN {  extends 'Catalyst::Controller' }
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;

sub save : Local {
	my ($self,$c)=@_;
    my $p = $c->request->params;
    try {
        $p->{name} or _throw(_loc("Missing parameter %1", 'name' ));
        $p->{action} or _throw(_loc("Missing parameter %1", 'action' ));
        $p->{paths} or _throw(_loc("Missing parameter %1", 'paths' ));
        my $ns = delete $p->{ns} || delete $p->{id}; 
        #_log "MD NS=$ns";
        # cleanup action
        $p->{action}=~ s/^action\.manualdeploy\.role\.//g;
        $p->{action} =~ s{\W}{_}g;
        $p->{action} =~ s{_+}{_}g;
        $p->{action} =~ s{^_}{}g;
        $p->{action} =~ s{_$}{}g;
        $p->{action} = "action.manualdeploy.role." . $p->{action} ;
        # remove old action
        my $last_action = delete $p->{action_last};
        for( _array( $p->{role_last} ) ) {
            my $role = Baseliner->model('Baseliner::BaliRole')->find( $_ );
            next unless ref $role ;
            $c->model('Permissions')->remove_action( $last_action, $role->role ) if $last_action; 
            $c->model('Permissions')->remove_action( $p->{action}, $role->role ) if $p->{action};
        }
        # assign roles
        if( my $roles = $p->{role} ) {
            for( _array( $p->{role} ) ) {
                next unless defined $_;
                my $role = Baseliner->model('Baseliner::BaliRole')->find( $_ );
                next unless ref $role ;
                $c->model('Permissions')->add_action( $p->{action}, $role->role ); 
            }
        }
        # save data
        kv->set(
            $ns ?  (ns=>$ns) : (provider=>'manual_deploy'),
            data=>$p
        );
        $c->stash->{json} = { success => \1 };
    } catch {
        $c->stash->{json} = { success => \0, msg=>"". shift };
    };
    $c->forward('View::JSON');
}

# catalog role methods 

with 'Baseliner::Role::Catalog';

sub catalog_add { }
sub catalog_icon { '/static/images/icons/manual_deploy.gif' }
sub catalog_del { 
    my ($class, %p)=@_;
    $p{id} or _throw 'Missing id';
    kv->delete( ns=>$p{id} );
}
sub catalog_url { '/comp/catalog/manual_deploy.js' }
sub catalog_list { 
    my ($class, %p)=@_;
    my @list;
    my $rs = kv->find( provider=>'manual_deploy' );
    while( my $r = $rs->next ) {
        my $d = $r->kv;
        my (@roles, @role_hash);
        for( _array( $d->{role} ) ) {
            my $role = Baseliner->model('Baseliner::BaliRole')->find( $_ );
            next unless ref $role;
            push @roles, $role->role;
            push @role_hash, { $role->get_columns };
        }
        push @list, {
            row         =>  { $r->get_columns, %$d, role_hash=>\@role_hash },
            name        => $d->{name}, 
            description => $d->{description}, 
            id          => $r->ns,
            for         =>{ paths=>$d->{paths}, roles=>\@roles },
            mapping     => { action=>$d->{action}  },
        };
    }
    return wantarray ? @list : \@list;
}
sub catalog_name { 'Manual Deployment' }
sub catalog_description { 'Deploy Files Manually by manual intervention' }

1;
