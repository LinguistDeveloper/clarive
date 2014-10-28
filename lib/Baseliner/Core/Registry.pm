package Baseliner::Core::Registry;
use Moose;
use MooseX::ClassAttribute;
use Moose::Exporter;
use Try::Tiny;
use Carp;
use Baseliner::Utils;

Moose::Exporter->setup_import_methods();

class_has registrar =>
    ( is      => 'rw',
      isa     => 'HashRef',
      default => sub { {} },
    );

class_has registor_data =>
    ( is      => 'rw',
      isa     => 'HashRef',
      default => sub { {} },
    );
    
class_has registor_keys_added =>
    ( is      => 'rw',
      isa     => 'HashRef',
      default => sub { {} },
    );

class_has classes =>
    ( is      => 'rw',
      isa     => 'HashRef',
      default => sub { {} },
    );

class_has module_index =>
    ( is      => 'rw',
      isa     => 'HashRef',
      default => sub { {} },
    );

class_has 'keys_enabled' => ( is=>'rw', isa=>'HashRef', default=>sub{{}} );
class_has '_registrar_enabled' => ( is=>'rw', isa=>'HashRef', );

{
    package Baseliner::Core::RegistryNode;
    use Mouse;

    has key     => ( is => 'rw', isa => 'Str',     required => 1 );
    has id      => ( is => 'rw', isa => 'Str',     required => 1 );
    has module  => ( is => 'rw', isa => 'Str',     required => 1 );
    has version => ( is => 'rw', isa => 'Str',     default  => '1.0' );
    has init_rc => ( is => 'rw', isa => 'Int',     default  => 5 );
    has param   => ( is => 'rw', isa => 'HashRef', default  => sub { {} } );
    has instance => ( is => 'rw', isa => 'Object' );
    has registor_key => ( is => 'rw', isa => 'Str' ), default=>'';
    has actions  => ( is => 'rw', isa => 'ArrayRef' );  # TODO deprecated
    has all_actions  => ( is => 'rw', isa => 'HashRef' );   # my actions, parent actions, etc. (cache)
}	

sub registors {
    my ($self)=@_;
    if( cache->get('registry:reload:all') && !cache->get('registry:reload_registor:'.$$) ) {
        _debug "Reload Registry Registor requested for $$";
        cache->set('registry:reload_registor:'.$$, 1);
        my @keys = keys %{ $self->registor_keys_added || {} };
        delete $self->registrar->{$_} for @keys;
        $self->registor_data({});
        return $self->registor_data;
    } else {
        return $self->registor_data;
    }
}

sub reload_all {
    cache->remove( qr/^registry:/ );
    cache->set( 'registry:reload:all', 1 );
}

sub _registrar {
    my $self = shift;
    #return $self->_registrar_enabled if ref $self->_registrar_enabled;
    #$self->_registrar_enabled({});
    my @disabled_keys = 
        grep { ! $self->is_enabled($_) }
        keys %{ $self->_registrar };
    for my $key ( @disabled_keys ) {
       delete $self->_registrar->{$key} 
        if defined $self->_registrar->{$key};
    }
    return $self->_registrar;
    #return $self->_registrar;
}

# the 'register' command
sub add {
    my ($self, $pkg, $key, $param)=@_;
    return if $ENV{BALI_CMD} && $key =~ /^(menu|registor.menu)/;   # TODO the class should tell me it its superfluous in CLI mode
    my $reg = $self->registrar;
    $param //= {};
    if( ref $param eq 'HASH' ) {
        $param->{key}=$key unless($param->{key});
        $param->{short_name} = $key; 
        $param->{short_name} =~ s{^.*\.(.+?)$}{$1}g if( $key =~ /\./ );
        $param->{id}= $param->{id} || $param->{short_name};
        $param->{module} //=$pkg;
    
        my $node = Baseliner::Core::RegistryNode->new( $param );
        $node->param( $param );
        $node->param->{registry_node} = $node;
        Scalar::Util::weaken( $node->param->{registry_node} );
        $reg->{$key} = $node;
        push @{ $self->module_index->{ $param->{module} } }, $node; # used by Role/CI.pm
    } else {
        #TODO register 'a.b.c' => 'BaselinerX::Service::MyService'
        die "Error registering '$pkg->$key': not a hashref. Not supported yet.";
    }
}

sub add_class {
    my ($self, $pkg, $key, $class)=@_;
    my $reg = $self->classes();
    $reg->{$key} = $class;
}

# everything starts here, called from Baseliner.pm
sub setup {
    my $self= shift; 
    # XXX DEPRECATED - slow: $self->load_enabled_list;
    $self->load_config_registry;
    $self->initialize( @_ );
}

sub load_config_registry {
    my $self= shift; 
    my $keys = Baseliner->config->{registry}{'keys'};
    return unless ref $keys eq 'HASH';
    for my $key ( keys %$keys ) {
        $self->add( 'config', $key, $keys->{$key} );
    }
}

## blesses all registered objects into their registrable classes (new Service, new Config, etc.)
sub initialize {
    my $self= shift; 

    my %init_rc = ();
    my @namespaces = ( @_ ? @_ : keys %{ $self->registrar || {} } );

    ## order by init_rc
    my $reg = $self->registrar;
    for my $key ( @namespaces ) {
        my $node = $reg->{$key};
        next if ref $node->instance;  ## already initialized
        push @{ $init_rc{ $node->init_rc } } , [ $key, $node ];
    }

    ## now, startup ordered based on init_rc
        ##TODO solve dependencies with a graph
    for my $rc ( sort keys %init_rc ) {
        for my $rc_node ( sort @{ $init_rc{$rc} } ) {
            my ($key, $node) = @{  $rc_node };
            ## search for my class backwards	
            $self->instantiate( $node );
        }
    }
    $self->initialize(@_) if keys %init_rc;  # recurse in case there is more to do
}

## bless an object instance with the provided params
sub instantiate {
    my ($self,$node,$class)=@_;	
    $class ||= $self->_find_class( $node->key );
    $node->{instance} = $class->new( $node->param );
}

## find the corresponding class for a component
sub _find_class {
    my ($self,$key)=@_;
    my $class = $key;
    my $node = $self->get_node($key);
    my @domain = split /\./, $key;
    for( my $i=$#domain; $i>=0; $i-- ) {
        $class = join '.',@domain[ 0..$i ];
        last if( $self->classes->{$class} ) ;
    }
    my $class_module = $self->classes->{$class} || $node->module; ## if no class found, bless onto itself
        #'BaselinerX::Type::Generic';  ## if no class found, assign it to generic
    #$ENV{CATALYST_DEBUG} && print STDERR "\t\t*** CLASS: $class ($class_module) FOR $key\n";
    return $class_module;
}

=head2 get_node

Return the key registration object (node). 
If not found, check registors are loaded and try 
again.

=cut
sub get_node {
    my ($self,$key)=@_;
    $key || croak "Missing parameter \$key";
    return $self->registrar->{$key} || do{
        $self->registor_loader( $key );  # make sure registor data is loaded
        $self->registrar->{$key};   
    };
}

=head2 get_instance (get)

Returns the actual instantiated object (ie isa BaselinerX::Type::Action)
or fail.

=cut
sub get { 
    my ($self,$key)=@_;
    return $self->get_instance($key) // _fail _loc("Could not find key '%1' in the registry", $key); 
}

sub get_instance {
    my ($self,$key)=@_;
    my $node = $self->get_node($key) || return undef;

    # is it from registor? check data then
    if( my $registor_key = $node->registor_key ) {
        if( !$self->registors->{$registor_key} ) {
            # we need a reload!
            $self->registor_loader( $key );  # make sure registor data is loaded
            $node = $self->get_node($key) || return undef;
        }
    }

    my $obj = $node->instance;
    return ( ref $obj ? $obj : $self->instantiate( $node ) );
}

=head2 find

Returns the actual instantiated object (ie isa BaselinerX::Type::Action)
or undef if not found.

=cut
sub find {
    my ($self,$key)=@_;
    return $self->get_instance($key); 
}

sub get_partial {
    my ($self,$key)=@_;
    my $reg = $self->registrar;
    my @found = map { $reg->{$_} } grep /$key$/, keys %{ $reg || {} };
    return wantarray ? @found : $found[0];
}

sub dir {
    my ($self,$key)=@_;
    return keys %{ $self->registrar || {} }
}

sub dump_yaml {
    _dump( shift->registrar );
}

sub load_enabled_list {
    my ( $self ) = @_;
    my $rs = mdb->config->find({ ns=>'/', bl=>'*', key=> qr/\.enabled$/});
    while( my $row = $rs->next ) {
        my $key = $row->key;
        my $enabled = $row->value;
        $self->keys_enabled->{ $key } = $enabled;
    }
}

## check the db if its key=>enabled|disabled
sub is_enabled {
    my ($self, $key) = @_;
    my $state = 1;
    try {
        if( defined $self->keys_enabled->{ $key } ) {
            $state = $self->keys_enabled->{ $key };
        }
    } catch {
        my $e = shift;
        _log "is_enabled: error while checking '$key': $e";
    };
    return $state;
}

=head2 search_for_node

Search for registered objs with matching attributes

Returns: nodes (not instances)

Options:
    
    allowed_actions => [qw//]   # filters nodes with allowed actions only

Configuration:

    <registry>
        disabled_key menu.admin.users
        disabled_key menu.admin.files
    </registry>

=cut
sub search_for_node {
    my ($self,%query)=@_;
    my @found = ();

    # query parameters
    my $check_enabled = delete $query{check_enabled} // 1;
    my $has_attribute = delete $query{has_attribute};
    my $key_prefix = delete $query{key} || '';
    my $q_depth = delete $query{depth};
    my $allowed_actions = delete $query{allowed_actions};
    my $username = delete $query{username};
    my $disabled_keys = Baseliner->config->{registry}->{disabled_key} if $check_enabled;  # cannot use config_get here, infinite loop..
    $disabled_keys = { map { $_ => 1 } _array $disabled_keys };

    my $reg = $self->registrar;
    
    my @allowed;
    foreach my $action ( _array $allowed_actions ) {
        if( blessed $action ) {
            #FIXME ???
            #push @allowed, $action->
            #warn "--------------ACTION=" . _dump $action;
        }
    }

    # loop thru services
    $q_depth //= 99; 
    OUTER: for my $key ( $self->starts_with( $key_prefix ) ) {
        my $depth = ( my @ss = split /\./,$key ) -1 ;
        next if( $depth > $q_depth );
        next if $check_enabled && exists $disabled_keys->{ $key };

        my $node = $reg->{$key};
        my $node_instance = $node->instance;

        # skip nodes that the user has no access to
        my $has_permission = 0;
        if ( !$username  || (!$node_instance->actions && !$node_instance->action) || $key_prefix eq 'action.') {
            $has_permission = 1;
        } else {        
            for ( _array( $node_instance->action, $node_instance->actions ) ) {
                $has_permission = 1 if Baseliner->model("Permissions")->user_has_any_action( action => $_, username => $username)
            }
        }
        next if !$has_permission;

        # query for attribute existence
        next if( $has_attribute && !defined $node->{$has_attribute} );

        # query for attribute value
        foreach my $attr( keys %query ) {
            my $val = $query{$attr};	
            if( defined $val ) {
                if( defined $node->{$attr} ) {
                    next OUTER unless( $node->{$attr} eq $val);
                }
                elsif( defined $node->{param}->{$attr} ) {
                    #warn "..........CHECK: $val, $key, $attr = " .  $node->{param}->{$attr};
                    next OUTER unless( $node->{param}->{$attr} eq $val);
                }
                else {
                    next OUTER;
                }
            }
        }
        push @found, $node;
    }
    return wantarray ? @found : $found[0];
}

=head2 search_for

Searches for nodes with C<search_for_node>, but returns
instances of the node object instead.

=cut
sub search_for {
    my $self=shift;
    my @found_nodes = $self->search_for_node( @_ );
    return map { $_->instance } @found_nodes;
}

=head2 registor_loader

Given a registry node key, look for candidate 
registors and check if their data is loaded. 

If registor loaded, return. 

If not, call registor node generator. Then register
each one of them.

=cut
sub registor_loader {
    my ($self, $key)=@_;

    my @registor_nodes;
    my $reg = $self->registrar;
    my $registors = $self->registors;  
    my ($key_prefix) = split /\./, $key; # look for registor like 'registor.menu', 'registor.action', ...
    return unless $key_prefix; 
    
    # look in registry for candidate registors
    for my $registor_key ( grep{ index($_, "registor.$key_prefix.")==0 } keys %{ $reg || {} } ) {
        #    _debug( "Looking in registor $registor_key for key $key_prefix" );
        # if registor not executed before, run it
        if ( !$registors->{$registor_key} ) {
            _debug "Registor data needed $registor_key...";
            $registors->{$registor_key} = 1;
            my $registor = $self->get($registor_key);
            # check cache for registor data, that way we have inter-worker communication
            #    TODO unfortunately this still requires instantiation to occur, which is slow, but better than registor generation
            if( my $cached_data = cache->get('registry:registor_data:'. $registor_key) ) {
                push @registor_nodes, { registor=>$registor, data=>$cached_data };
                _debug "Registor data from cache $registor_key";
            } else {
                # get data first time
                # call registor and retrieve keys
                my $registor_data = $registor->generator->($key_prefix);
                cache->set('registry:registor_data:'. $registor_key, $registor_data );
                push @registor_nodes, { registor=>$registor, data=>$registor_data };
                _debug "Registor data loaded fresh $registor_key";
            }
        }
    }
    return unless @registor_nodes; # nothing to register, leave
    
    
    # register into registry hash all registor data found
    my $flag = 0;
    for my $regs ( @registor_nodes ) {
        my $data = $regs->{data};
        my $registor = $regs->{registor};
        next unless ref $data eq 'HASH'; 
        # for each registry entry returned by Registor...
        for my $key ( keys %$data ) {
            next if exists $reg->{$key} && ! $data->{$key}->{_overwrite};
            #  register( $key, $data->{$key} );
            $data->{$key}{registor_key} = $registor->key;  # so everyone knows I come from a registor
            $self->add( $registor->module, $key, $data->{$key} );
            $self->registor_keys_added->{$key} = 1;  # so we can delete from registry on remove
            $flag ||= 1;
        }
    }
    # instanciate new keys in registry
    $self->initialize if $flag;
    # everything should be in memory (registrar) now 
    return;
}

sub starts_with {
    my ($self, $key_prefix )=@_;
    my @keys;
    my $reg = $self->registrar;
    $self->registor_loader( $key_prefix );  # make sure registor data is loaded
    for my $key ( keys %{ $reg || {} } ) {
        push @keys, $key if index( $key, $key_prefix ) == 0;
    }
    return @keys;
}

sub get_all {
    my ($self, $key_prefix )=@_;
    my @ret;
    #warn "GETALL=$key_prefix";
    my $reg = $self->registrar;
    for( keys %{ $reg || {} } ) {
        push @ret, $self->get($_) if( /^\Q$key_prefix/ );
    }
    return @ret;
}

sub write_registry_file {
    my ($self, $file) = @_;
    open my $fr, '>', 'baseliner.registry';
    print $fr _dump( $self->registrar );
    close $fr;
}

sub print_table {
    my $self = shift;

    my $reg = $self->registrar;
    my $table = <<"";
Registry:
.----------------------------------------+-----------------------------------------------.
| Key                                    | Package                                       |
+----------------------------------------+-----------------------------------------------+

    for( sort keys %{ $reg || {} } ) {
        my $node = $reg->{$_};
        $table .= sprintf("| %-38s ", $node->key );
        #$table .= sprintf("| %-22s ", $_->module );
        ( my $module = $node->module ) =~ s/BaselinerX/BX/g;
        $module =~ s/Baseliner/BL/g;
        $table .= sprintf("| %-45s |\n", $module );
    }

    $table .= <<"";
.----------------------------------------------------------------------------------------.

    print STDERR $table . "\n" if Clarive->debug && !$ENV{BALI_CMD};
}
1;

