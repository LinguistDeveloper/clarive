package Baseliner::Model::NamespacesFork;
use Moose;
extends qw/Catalyst::Model/;
use Baseliner::Utils;
use Baseliner::Core::Registry;
use Try::Tiny;

=head2 namespaces

List all namespaces. 

Be careful, this is not cached. If you want a cached list, use the /namespace/list controller.

=cut
use YAML;
use Baseliner::Core::Registry;
sub namespaces {
    my $self = shift;
    my $p = ref $_[0] ? $_[0] : { @_ };
    my @ns_list;

    my @role_list = ( _array($p->{does}), _array($p->{does_not}) );

    _log "Starting provider request from " . join',',caller(1);
    my $list_key = 'search_' . _nowstamp();
    my @pids;

    my @ns_prov_list = Baseliner::Core::Registry->starts_with('namespace');
    for my $ns_prov ( @ns_prov_list ) {
        my $prov = Baseliner::Core::Registry->get( $ns_prov );

        # queries 
        unless( !scalar(@role_list) or $prov->module->isa('BaselinerX::Type::Namespace') or !$prov->module->namespace ) {
            my $found;
            QUERY: foreach my $namespace_provided ( _array $prov->module->namespace ) {
                for my $role ( @role_list ) {
                    $found=1, last QUERY if $namespace_provided->does( $role );
                }
            }
            next if $p->{does} && !$found ;
            next if $p->{does_not} && $found ;
        }
        next if( $p->{can_job} && !$prov->can_job );
        next if( $p->{class} && !( $prov->root =~ /$p->{class}/ ) );  #TODO root rename to class or something

        # run the provider
        if( my $pid = fork ) {
            push @pids, $pid;
            next;
        }
        try {
            my $prov_list = $prov->handler->($prov, Baseliner->app, $p);
            Baseliner->model('Repository')->set( ns=>$list_key . '/' . $ns_prov, data=>$prov_list );
        } catch {
            my $error = shift;
            _log $error;
        }
        exit;
    }
    waitpid($_,1) for @pids;
    for( Baseliner->model('Repository')->all( provider=> $list_key ) ) {
        my $data = $_->{data};
        if( ref $data eq 'HASH' ) {
            push @ns_list, _array($data->{data} );
        } else {
            push @ns_list, _array($data);
        }
    }
    return sort {
        return -1 if $a->ns eq '/';
        ( $a->ns_type . $a->ns ) cmp ( $b->ns_type . $b->ns )
    } @ns_list;
}

sub providers {
    my $self = shift;
    my $p = _parameters( @_ );
    my @found;

    # does setup...
    if( defined $p->{does_any} ) {
        $p->{does} = $p->{does_any};
        $p->{does_type} = 'any';
    } elsif( defined $p->{does_all} ) {
        $p->{does} = $p->{does_all};
        $p->{does_type} = 'all';
    }
    my $does_type = $p->{does_type} || 'any';
    my @does_list = _array $p->{does};
    my @does_not_list = _array $p->{does_not};

    # isa setup
    my @isa_list = _array $p->{isa}, $p->{isa_any}, $p->{isa_all};
    my $isa_type = $p->{isa_type} || defined $p->{isa_all} ? 'all' : 'any';
    my $isa_check = scalar @isa_list;

    # list all providers
    my @providers = packages_that_do( 'Baseliner::Role::Provider' );
    foreach my $provider ( @providers ) {
        my ($found_does, $found_does_not, $found_isa);

        # isa
        if( $isa_check ) {
            foreach my $namespace_provided ( _array $provider->namespace ) {
                if( $isa_type eq 'all' ) {
                    my $isa_count = grep { $namespace_provided->isa($_) } @isa_list;
                    $found_isa=1 if $isa_count == scalar @isa_list;
                } else { #any
                    foreach my $who ( @isa_list ) {
                        $found_isa=1 if $namespace_provided->isa( $who );
                    }
                }
            }
        }

        # does
        my ( $does_check, $does_not_check ) = ( scalar(@does_list), scalar(@does_not_list) );
        if( $does_check || $does_not_check ) {
            foreach my $namespace_provided ( _array $provider->namespace ) {
                if( $does_type eq 'all' ) {
                    $found_does=1 if $does_check and $namespace_provided->does( @does_list );
                } else { # any
                    foreach my $role ( @does_list ) {
                        $found_does=1 if $does_check and $namespace_provided->does( $role );
                    }
                }
                $found_does_not=1 if $does_not_check and $namespace_provided->does( @does_not_list );
            }
        }
        next if $does_check && !$found_does;
        next if $does_not_check && $found_does_not;
        next if $isa_check && !$found_isa;
        push @found, $provider; 
    }
    return @found;
}

=head2 list

Returns a list of items of a given role.

    does => ARRAYREF | SCALAR of a role name
    does_type => 'any' | 'all' of the roles specified
    

=cut
our %provider_factory;
sub list {
    my $self = shift;
    my $p = _parameters( @_ );
    my @providers = $self->providers( $p );

    my $list_key = 'search_' . _nowstamp() . '_' . $$;
    my @pids;
    _log "Starting provider request '$list_key' from " . join',',caller(1);

    foreach my $provider ( @providers ) {
        $provider_factory{$provider} ||= $provider->new;
        my $instance = $provider_factory{$provider};
        # fork 
        if( my $pid = fork ) {
            push @pids, $pid;
            next;
        }
        # run the provider
        my $dbh = Baseliner->model('Baseliner')->storage->dbh;
        $dbh->do("alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss'");
        try {
            _log "Invoking provider $provider...";
            my $ns_list = $instance->list( Baseliner->app, $p );
            Baseliner->model('Repository')->set( ns=>$list_key . '/' . $provider, data=>$ns_list );
        } catch { #TODO inform the user
            _log "Provider $provider error: " . shift;
        };
        _log "-------------EXITING";
        exit;
    }
    _log "Providers running: " . join ',',@pids;
    for( @pids ) {
        while( !waitpid($_,1) ) { };
    }
    do {} until( waitpid(-1,1) );
    
    _log "Providers done.";
    my @ns;
    my ($count,$total);
    for( Baseliner->model('Repository')->all( provider=> $list_key ) ) {
        my $ns_list = $_->{data};
        if( ref $ns_list eq 'HASH' ) {
            push @ns, _array $ns_list->{data};
            $total += $ns_list->{total} || $ns_list->{count};
            $count += $ns_list->{count};
        } else {
            push @ns, _array $ns_list;
            $total += scalar @ns;
            $count += scalar @ns;
        }
    }

    _log "---------TOTAL: $total\n";
    return wantarray
        ? @ns
         : { data=>\@ns, total=>$total, count=>scalar(@ns) };
}

# returns a reverse sorted list of ns from more specific to most general (root)
sub sort_ns {
    my $self = shift;
    my $opts = ref($_[0]) ? shift : {};
    my @ns = @_;
    push @ns, '/' unless $opts->{no_root} ;
    #TODO graph analyze @ns against relationships
    return sort { 
            $opts->{asc}
            ?  length($a) <=> length($b) 
            :  length($b) <=> length($a) 
        } _unique @ns;  ## long to short - temp hack
}

sub namespaces_hash {
    my $self = shift; 
    my $p = _parameters(@_);
    my @ns_list = $self->namespaces($p);
    my %h;
    for( @ns_list ) {
        $h{ $_->ns } = $_;
    }
    return %h;
}

=head2 find_text 

Finds a descriptive representation for the Namespace. Heavly used, heavly memoized.

=cut
our %ns_text_cache;
sub find_text {
    my $self = shift; 
    my $ns = shift; 
    my $p = _parameters(@_);
return $ns; #FIXME
    return $ns_text_cache{$ns} if defined $ns_text_cache{$ns};
    my %h = $self->namespaces_hash($p);
    my $v = $h{ $ns };
    if( $v ) {
        return $ns_text_cache{$ns} = $v->ns_text;
    } else {
        return  $ns_text_cache{$ns} = _loc('Namespace') . " $ns";	
    }
}

sub does {
    my ($self, $role, %p ) = @_;
    $role = "Baseliner::Role::$role" unless $role =~ m/^Baseliner/g;
    return $self->namespaces( does=>$role, %p );
}

# get is a factory, turns a namespace into its object
sub get {
    my $self = shift; 
    return $self->_get( ns=>[ @_ ], one=>1 );
}
sub _first {
    my $self = shift; 
    return $self->_get( ns=>[ @_ ], one=>1 );
}
sub _get {
    my ( $self, %p ) = @_;

    foreach my $ns ( @{ $p{ns} } ) {
        my ( $domain, $item ) = ns_split( $ns );
        if( $domain && !$item ) {   # just domain
            my @providers = $self->find_providers_for( domain=>$domain ); 

            my @namespaces;
            for my $provider ( @providers ) {
                try {
                    push @namespaces, @{ $provider->handler->( $provider, Baseliner->app, {} ) || [] };
                } catch {
                    my $err =shift;
                    _log "Provider error: " . $err;
                };
            }
            return ( $p{one} || scalar(@namespaces) == 1 )
                ? $namespaces[0]
                : wantarray ? @namespaces : [ @namespaces ];
        }
        elsif( $domain && $item ) {   # normal 
            my @providers = $self->find_providers_for( domain=>$domain ); 

            my @namespaces;
            # first, try to get it straight from the exact domain matches
            for my $provider ( grep { $_->{root} eq $domain } @providers ) {
                my $ns_obj = $provider->get( $item ); 
                push @namespaces, $ns_obj if ref $ns_obj;
            }
            # now, the rest, so they stay behind the array
            for my $provider ( grep { $_->{root} ne $domain } @providers ) {
                my $ns_obj = $provider->get( $item ); 
                push @namespaces, $ns_obj if ref $ns_obj;
            }

            return ( $p{one} || scalar(@namespaces) eq 1 )
                ? $namespaces[0]
                : wantarray ? @namespaces : [ @namespaces ];
            
        }
        elsif( !$domain && $item ) {   # just item
            for my $namespace ( $self->namespaces ) {
                my ( $domain, $item ) = ns_split( $namespace->ns );
                return $namespace if $item eq $item; 
            }
        }
        else {
            my $provider = Baseliner::Core::Registry->get('namespace.root'); 
            my $list = $provider->handler->();
            return $list->[0] if ref $list eq 'ARRAY';
        }
    }
}

# gimme a domain and I'll find you providers
sub find_providers_for {
    my ( $self, %p ) = @_;

    my $domain = $p{domain};

    my @providers;
    my @all = Baseliner::Core::Registry->starts_with('namespace');
    for my $provider_name ( @all ) {
        my $provider = Baseliner::Core::Registry->get( $provider_name );
        if( $p{exact} ) {
            push( @providers, $provider )
                if( $provider->{root} eq $domain );         #TODO root should be domain
        } else {
            push( @providers, $provider )
                if( domain_match( $provider->{root}, $domain ) );  
        }
    }
    return @providers;
}

1;

