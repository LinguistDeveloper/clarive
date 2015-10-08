package BaselinerX::Type::Model::ConfigStore;
=head1 NAME

Model::ConfigStore - work with internal configuration data

=head1 SYNOPSIS

    my $config = Baseliner->model('ConfigStore')->get('config.thingy');
    say $config->{favorite};

    # or with a user provided value

    my $config = Baseliner->model('ConfigStore')->get('config.thingy', data=>{ favorite=>'foo' });
    say $config->{favorite};

=head1 DESCRIPTION

Config table, default and instance provided meshup model.

This is unrelated to standard Config files. 

=head1 METHODS

=cut
use Moose;
extends qw/Catalyst::Model/;
#with 'Catalyst::Component::InstancePerContext';

use Baseliner::Utils;
use BaselinerX::Type::Config;
use Scalar::Util qw(blessed);

use Try::Tiny;


=head2 store_long

Stores a hashref of long.keys => value

=cut
sub store_long {
    my ($self, %p ) = @_;
    my $data = $p{data};
    $p{ns} ||= '/';
    $p{bl} ||= '*';
    for my $key ( keys %{ $p{data} || {} } ) {
        my $config = mdb->config->update(
            {
                key     => $key,
                ns      => $p{ns},
                bl      => $p{bl},
            },
            {   
                key     => $key,
                ns      => $p{ns},
                bl      => $p{bl},
                value   => $data->{$key},
                ts      => mdb->ts
            },
            {'upsert' => 1}
        ) or die $!;
    }
    return 1;
}

=head2 get

The one and definitive way to get things out of the Config table. 

Can check one or more keys.

Options:
    
    ns       : optional namespace, default is /
    bl       : optional environment, default is *
    data     : user provided data
    long_key : uses the full key "config.etc.etc" as hash key names.

Returns a hashref to the config data structure. 

=cut

sub get {
    my ($self, $key, %p ) = @_;
    $p{ns} ||= '/';
    $p{bl} ||= '*';
    $p{bl} = '*' if ref $p{bl} eq 'ARRAY';
    my $data = $p{data} || {};
    my $enforce_metadata = delete $p{enforce_metadata};
    my $long_key = $p{long_key};
    my %values;

    # 1) try catalyst config - first look for ->{xxx.yyy}, otherwise ->{xxx}->{yyy}
    # accepts 2 formats:
    #    config_get('mykey')->{xxx}
    #    config_get('mykey.xxx')
    #
    my $v = Baseliner->config->{ $key };
    if( ! defined $v ) {
        my $config_eval = sprintf 'Baseliner->config->{%s}', join('}{', split /\./, $key );
        $v =  eval $config_eval; 
    }
    $values{ $key } = [ { key=>$key, ns=>'/', bl=>'*', value=>$v } ] if defined $v ;

    # load all values for the keyinto a temp hash
    my $where;
    $where->{ns} = $p{ns} if $p{ns};
    $where->{'$or'} = [{key => qr/^$key\./}, {key => qr/^$key$/}];

    my @rs = mdb->config->find($where)->fields(
            {ns => 1, key => 1, bl => 1, value => 1, _id => 0}
        )->all; 

    for my $r ( @rs ) {
        push @{ $values{ $r->{key} } }, { ns=>$r->{ns}, bl=>$r->{bl}, value=>$r->{value} };
    }	

    # now find the best_match
    foreach my $k ( keys %values ) {
        if( $k =~ /^(.*)\.(.*?)$/ ) {  # get the last word as value
            my $k1 = $1;
            my $k2 = $2;
            my $value = BaselinerX::Type::Config::best_match_on_viagra( $p{ns}, $p{bl}, @{ $values{$k} || [] } );
            $data->{ $long_key ? $k : $k2} = $value;
        } else {
            $data->{ $k } = BaselinerX::Type::Config::best_match_on_viagra( $p{ns}, $p{bl}, @{ $values{$k} || [] } );
        }
    }

    # if no data found, use default values
    my $config = $self->config_for_key( $key ) // {};
    if( defined $config && blessed($config) && blessed($config) eq 'BaselinerX::Type::Config' ) {
        foreach my $item ( @{ $config->metadata || [] } ) {
            my $data_key = $long_key ? $key.$item->{id} : $item->{id};

            # use default value ?
            $data->{ $data_key } = $item->{default}
                unless exists $data->{ $data_key }; 
    
            # expand key type
            $data->{$data_key} = $self->_expand( $item->{type}, $data->{ $data_key } );
            #TODO no expasion needed when already of type: unless ref $data->{$data_key} =~ /HASH|ARRAY/ || blessed($data->{$data_key});

            # resolve vars
            my $new_value = $data->{ $data_key } // '';
            #$new_value =~ s/\$\{ns\}/$p{ns}/g ; 
            #$new_value =~ s/\$\{bl\}/$p{bl}/g ; 
            #$new_value =~ s/\$\{key\}/$key/g ; 
            #$new_value =~ s/\$\{id\}/$item->{id}/g;

            $new_value = $self->variable_parse(
                value => $new_value,
                vars  => {
                    ns   => $p{ns},
                    bl   => $p{bl},
                    key  => $key,
                    item => $item->{id}
                }
            );
            $new_value = $self->variable_parse_config( key=>$key, ns=>$p{ns}, bl=>$p{bl}, value=>$new_value );
            $new_value = $self->variable_parse( value=>$new_value, vars=>$p{vars} );
            $data->{ $data_key } = $new_value;

            # callbacks
            if( ref $p{callback} eq 'CODE' ) {
                #TODO - maybe it's not necessary
            }

        }
    } else {
        my $msg = _loc( "Could not find metadata for the key '%1' in the registry.", $key );
        _throw $msg if($enforce_metadata);
        _debug $msg if $ENV{BASELINER_DEBUG_METADATA};
    }
    
    if( $p{value} ) {
        my ( $first_key ) = keys %{ $data || {} };
        return defined $first_key ? $data->{ $first_key } : undef;
    } else {
        return $data;
    }
}

=head2 _expand

Convert value data to metadata type

=cut
sub _expand {
    my ( $self, $type, $value ) = @_;

    $value = $value->() if ref $value eq 'CODE';
    return $value unless $type;
    return undef unless $value;

    return try {
        $value = $value->() if ref $value eq 'CODE';
        if( $type eq 'hash' ) {
            return { } unless $value;
            return eval "{ $value }";
        }
        elsif( $type eq 'array' ) {
            return [ split(/,/, $value ) ]; 
        }
        elsif( $type eq 'eval' ) {
            return eval $value;
        }
        else {
            return $value;
        }
    } catch {
        _log "Error expanding config type '$type' and value '$value': " . shift; 
        return $value;
    };
}

=head2 ns_config

Find to which config object this key belongs to (config.my.stuff.key => config.my.stuff )

=cut
sub ns_config {
    my ($self, $key ) = @_;
    #TODO pending     
}

=head2 all_keys

Just give me all keys

=cut
sub all_keys {
    my ($self) = @_;
    return Baseliner::Core::Registry->starts_with('config');
}

=head2 all

Just give me all config objects.

=cut
sub all {
    my ($self) = @_;
    my @configs;
    foreach my $key ( $self->all_keys ) {
        push @configs, Baseliner->registry->get( $key );
    }
    return @configs;
}
    
=head2 filter_ns

Get all config keys available for a ns.

=cut
sub filter_ns {
    my ($self, $ns, $bl ) = @_;
    $ns ||= '/';
    my $search = { ns=>$ns };
    $search->{bl} = $bl if( $bl );
    my $rs = mdb->config->find($search)->fields({key => 1, bl => 1, ns => 1, _id => 0});
    my %keys;
    while( my $r = $rs->next ) {
        $keys{ $r->key } = ();
    }
    return keys %keys;
}

=head2 search

List everything in the table.

=cut
sub search {
    my $self = shift;
    my $p = _parameters(@_);
    
    my $query = $p->{query};
    my $where = {};
    $query and $where = mdb->query_build(query => $query, fields=>[qw(ns bl key value ts)]);

    my $rs = mdb->config->find($where);
    # paging
    my $has_paging = defined($p->{start}) && defined($p->{limit});
    if( $has_paging ) {
        $rs->skip($p->{start});
        $rs->limit($p->{limit});
    }

    # sorting
    my $dir;
    if($p->{dir} && $p->{dir} eq 'desc'){
        $dir = -1;
    }else{
        $dir = 1;
    }
    my $sort = $p->{sort} ? {$p->{sort} => $dir} : {key => 1}
        unless  $p->{sort} && $p->{sort} =~ /^config_/i;   
    $rs->sort($sort);

    my $count = 0;
    my @rows;
    while( my $r = $rs->next ) {
            my $config = $self->config_for_key( $r->{key} ) or warn 'No config for ' . $r->{key};
            my $metadata = { type=>'?', default=>'', label=>$r->{label} };  # default values
            if( $config ) {
                try { $metadata = $config->metadata_for_key( $r->{key} ) or warn 'No metadata for ' . $r->{key}; } catch { _debug $r->{key};};
            }
            my $value = $self->get( $r->{key}, ns=>$r->{ns}, bl=>$r->{bl}, value=>1, long_key=>1 );
            my $data = {
                resolved        => $value,
                composed        => $self->key_compose( key=>$r->{key}, ns=>$r->{ns}, bl=>$r->{bl} ),
                config_name    => $config->{name} || '',
                config_key     => $config->{key} || '',
                config_module  => $config->{module} || '',
                config_type    => $metadata->{type} || '',
                config_default => $metadata->{default} || '',
                config_label   => _loc( $metadata->{label} ) || '',
            };
            $data = +{ %$data, %$r };
            $data->{config_default} = $self->check_value_type( $data->{config_default} );
            $data->{id} = $data->{_id} = $data->{_id}{value};
            push @rows, $data;
            $count++;
    }
    # add registry items not already in the db
    my %already;
    my @keys = map { $_->{key} } @rows;
    foreach (@keys){
        $already{$_} = 1;
    }
    my @registry = grep { not $already{ $_->{key} } } $self->search_registry; # XXX dead code, delete?

    # manual sorting
    if( $p->{sort} && $p->{sort} =~ /^config_/i ) {
        my $col = $p->{sort};
        @rows = sort { $a->{$col} cmp $b->{$col} } @rows;
    }

    if( $has_paging ) {
        my $total = $rs->count();
        return { data=>\@rows, total=>$total };
    } else {
        return { data=>\@rows, total=>$count };
    }
}

sub config_for_key {
    my ($self, $key) = @_;
    my $config;
    my $single_key = 0;
    eval { $config = Baseliner->registry->get( $key ) };
    if( $@ || !$config ) {  # try a shorter key if the key is not found
        eval { $config = Baseliner->registry->get( Util->_cut(-1, '\.', $key ) ) };
        $single_key = 1 unless $@;
    }
    return $config;
}

sub check_value_type {
    my ($self, $value) = @_;
    ref $value eq 'CODE' and return $value->();
    return $value;
}

sub search_registry {
    my $self = shift;
    my $p = _parameters(@_);

    my @rows;	
    my @config_list = Baseliner::Core::Registry->starts_with('config');
    for my $config_key ( @config_list ) {
        my $config = Baseliner::Core::Registry->get( $config_key );
        next unless ref $config;
        for my $subkey ( $config->individual_keys ) {
            my $resolved = $subkey->{value}; #$self->get( $subkey->key, ns=>'/', bl=>'*', value=>1, long_key=>1 );
            my %parms = (
                ns=>'/',
                bl=>'*',
                key=>$subkey->{key},
                value=>$subkey->{default},
                ts=>undef,
                data=>$subkey->{value},
                resolved => $resolved,
                composed => $self->key_compose( key=>$subkey->{key}, ns=>'/', bl=>'*' ),
                config_name    => $subkey->{name} || '',
                config_key     => $subkey->{parent_key} || '',
                config_module  => $subkey->{module} || '',
                config_type    => $subkey->{type} || '',
                config_default => $subkey->{default} || '',
                config_label   => _loc( $subkey->{label} ) || '',
            );
            $parms{config_default} = $self->check_value_type( $parms{config_default} );
            $parms{value} = $self->check_value_type( $parms{value} );
            $parms{data} = $self->check_value_type( $parms{data} );
            next unless Util->query_grep( query=>$p->{query}, all_fields=>1, rows=>[ \%parms ] ) || !$p->{query};
            push @rows, \%parms;
        }
    }

    # sort
    my $sort = $p->{sort};
    @rows = sort { 
        my $va = $a->{$sort};
        my $vb = $b->{$sort};
        !defined $va ? 1 : !defined $vb ? -1 : $va cmp $vb
    } @rows if $sort;

    # paging
    my $total = scalar @rows;
    if( defined $p->{start} ) {
        my $start = $p->{start} || 0;
        my $limit = $p->{limit} || $total;
        my $index = $start + $limit;
        $index = $index > $total-1 ? $total-1 : $index;
        @rows = @rows[ $start .. $index ];
    }

    return { data=>\@rows, total=>$total };
}

sub delete {
    my ($self,%p) = @_;
    my $ns = $p{ns} || '/';
    my $bl = $p{bl} || '*';
    if( $p{_id} ) {
        mdb->config->remove({_id => mdb->oid($p{_id})});
    } else {
        mdb->config->remove({ key=>$p{key}, ns=>$ns, bl=>$bl });
    }
}

sub set {
    my ($self,%p) = @_;
    my $ns = $p{ns} || '/';
    my $bl = $p{bl} || '*';
    _throw 'Missing parameter key' unless $p{key};
    _throw 'Missing parameter value' unless defined $p{value};

    my $registry_data = $self->search_registry( query=> $p{key} );
    my ($original) = _array($registry_data->{data} // []) if $registry_data && $registry_data->{data} && $registry_data->{data}[0]->{key} eq $p{key};
    _warn $original;
    
    $self->delete( %p );
    
    my $row = mdb->config->insert(
        {   key     => $p{key}, 
            value   => $p{value}, 
            ns      => $ns, 
            bl      => $bl,
            ts      => mdb->ts,
            label   => $original->{config_label}
        }
    );
    return $row;
}

# create a key with ns and bl
sub key_compose {
    my $self = shift;
    my $p = _parameters(@_);
    my $key = $p->{key};
    if( $p->{bl} && $p->{bl} ne '*' ) {
        $key .= '@' . $p->{bl};
    }
    if( $p->{ns} && $p->{ns} ne '/' ) {
        $key .= ':' . $p->{ns};
    }
    return $key;
}

sub variable_parse {
    my $self = shift;
    my $p = _parameters(@_);
    
    _check_parameters($p, qw/value vars/ );

    my $value = $p->{value};
    my $vars = $p->{vars};

    #_throw 'Parameter vars should be a HASH ref of variable => value'
    return $value
        unless ref $vars eq 'HASH';

    # parse
    foreach my $var ( keys %{ $vars } ) {
        $self->variable_parse_single( data=>$value, variable=>$var, value=>$vars->{$var} );
        #$var_key.= '@'. $p->{bl} if $p->{bl} && $p->{bl} ne '*';
        #$var_key.= ':'. $p->{ns} if $p->{ns} && $p->{ns} ne '/';
    }
    return $value;
}

sub variable_parse_single {
    my $self = shift;
    my $p = _parameters(@_);
    _check_parameters($p, qw/data variable value/ );
    my $variable = '${' . $p->{variable} . '}';
    my $var_value = $p->{value};
    my $data = $p->{data};
    $data =~ s/\Q$variable\E/$var_value/g;
    return $data;
}

sub variable_parse_config {
    my $self = shift;
    my $p = _parameters(@_);
        
    _check_parameters($p, qw/key value/ );
    my $visited = $p->{visited} || {}; 
    my $value = $p->{value};

    # get the vars out of the data
    my @vars = $value=~m/\$\{(.+?)\}/gs;
    foreach my $variable ( @vars ) {
        my $var_key = $variable;
        my $variable_value;

        # ignore invalid variables 
        next unless $var_key;

        my ($var_ns, $var_bl) = ( $p->{ns}, $p->{bl} );
        # split ns config.key@bl:domain/item
        if( $var_key=~ /^(.+):(.+)/gs ) {
            $var_key = $1;
            $var_ns = $2 if $2;
        }
        # split bl: config.key@bl:domain/item
        if( $var_key=~ /^(.+)\@(.+)/gs ) {
            $var_key = $1;
            $var_bl = $2 if $2;
        }

        if( exists $visited->{$var_key} ) {
            $variable_value = $visited->{$var_key};
        } else {
            $variable_value = $self->get( $var_key, ns=>$var_ns, bl=>$var_bl, enforce_metadata=>0, long_key=>1, value=>1 );
            #_throw _loc( 'No data found for variable %1', $var_key )
              #if ref $variable_value && ! exists $data->{$var_key};
            $visited->{ $var_key }= $variable_value;
        }
        my $value_res = $self->variable_parse_single( data=>$value, variable=>$variable, value=>$variable_value );
        _throw 'Could not replace anything!' if $value_res eq $value;
        $value = $value_res;
        #$value = $self->variable_parse( variable=>$var_key, value=>$value, vars=>$data );
    }

    # recurse 
    if( $value =~ m/\$\{(.+?)\}/gs ) {
        $self->variable_parse_config( key=>$p->{key}, value=>$value,ns=>$p->{ns}, bl=>$p->{bl}, visited=>$visited );  
    }
    return $value;
}

sub export_to_file {
    my ($self, %p ) =@_;
    $p{file} ||= Baseliner->path_to('/etc/export/config_store');
    my ($vol,$path,$file) = File::Spec->splitpath( $p{file} );
    _mkpath $path;
    my $rs = mdb->config->find();
    my %data;
    for ( $rs->all ) {
        my $key = delete $_->{key} ;
        push @{ $data{$key} }, $_;
    }
    # conf
    require Config::General;
    my $conf = Config::General->new( \%data ) or _throw $@;
    $conf->save_file( $p{file} . ".dmp" );

    # yaml
    open my $yaml,'>', "$p{file}.yaml.dmp" or _throw $@;
        print $yaml _dump( \%data );
    close $yaml;

    #xml
    require IO::File;
    my $xml_file = IO::File->new( '> ' . $p{file} . '.xml');
    require XML::Simple;
    print $xml_file XML::Simple::XMLout( \%data );
    $xml_file->close;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

