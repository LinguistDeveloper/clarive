package Clarive::Code::JS;
use Moose;

BEGIN { $ENV{PERL_INLINE_DIRECTORY} = "$ENV{CLARIVE_BASE}/local/lib/_Inline" }

use JSON ();
use Storable ();
use Try::Tiny;
use File::Basename ();
use Scalar::Util qw(blessed);
use JavaScript::Duktape;
use Class::Load qw(is_class_loaded);
use Time::HiRes qw(usleep);

use Baseliner::Mongo;
use BaselinerX::Type::Model::ConfigStore;
use Baseliner::Utils qw(parse_vars packages_that_do _to_camel_case to_base_class _unbless :logging _load _dump _encode_json _decode_json _json_pointer _array);

use Clarive::App;
use Clarive::Code::Utils;

has dump_code     => qw(is rw isa Bool default 0);
has enclose_code  => qw(is rw isa Bool default 0);
has strict_mode   => qw(is rw isa Bool default 0);
has allow_pragmas => qw(is rw isa Bool default 0);

has extend_cla    => qw(is rw isa HashRef default),sub{+{}};
has global_ns     => qw(is rw isa HashRef default),sub{+{}};

has save_vm  => qw(is rw isa Bool default 0);
has _last_vm => qw(is rw isa Any);

has prefix => qw(is rw isa Str required 1 lazy 1), default => sub{
    my $self = shift;

    my $prefix = <<"EOF";
Duktape.modSearch = function (id) {
    var res = cla.loadModule(id);
    return res;
};
EOF
    $prefix .= qq{"use strict";\n} if $self->strict_mode;

    $prefix;
};

has _prefix_lines => qw(is rw isa Num lazy 1), default => sub{
    my $self = shift;
    scalar split /\n/, $self->prefix;
};

sub eval_code {
    my $self = shift;
    my ( $code, $stash ) = @_;

    $code = template_literals( $code );

    $stash ||= {};

    # create / load / save JS vm
    my $js = $self->_last_vm || JavaScript::Duktape->new;
    if( $self->save_vm ) {
        $self->_last_vm( $js );
    }

    $js->set(
        toJSON => js_sub {
            shift;
            my ($what) = @_;

            return $self->_to_json($what);
        }
    );

    # cla ns setup
    my $cla_ns = $self->_generate_cla($stash);
    foreach my $ns ( keys %{ $self->extend_cla } ) {
        $cla_ns->{$ns} = $self->extend_cla->{$ns};
    }
    $js->set( cla => $cla_ns );

    # top level ns setup
    foreach my $ns ( keys %{ $self->global_ns } ) {
        $js->set( $ns => $self->global_ns->{$ns} );
    }

    local $Clarive::Code::Utils::GLOBAL_ERR = '';

    if( $self->allow_pragmas ) {
        $self->_process_pragmas($code);
    }

    my $fullcode;

    if( $self->enclose_code ) {
        $fullcode = $self->prefix . "(function(){$code}())";
    } else {
        $fullcode = $self->prefix . $code;
    }

    printf STDERR $fullcode if $self->dump_code;

    return try {
        $js->eval( $fullcode );
    }
    catch {
        my $err = $_;
        my $msg = "Error executing JavaScript: $err: $Clarive::Code::Utils::GLOBAL_ERR\n";
        if( my ($err_line) = $err =~ /\(line (\d+)\)/ ) {
            $err_line--;
            my @lines = ( split "\n", $fullcode );
            my $start_line = $err_line > ($self->_prefix_lines+2) ? $err_line - 2 : $self->_prefix_lines;
            my $end_line   = $err_line < ( $#lines - 2 ) ? $err_line + 2 : $#lines;
            for my $line ( $start_line..$end_line ) {

                my $real_line = $line + 1 - $self->_prefix_lines;

                if( $line == $err_line ) {
                    $msg =~ s/(\(line )(\d+)\)/(line $real_line)/;
                }

                $msg .= sprintf "%d%s %s\n", $real_line, ( $line == $err_line ? '>>>' : ':  ' ), $lines[$line];
            }
        }
        die $msg;
    };
}

sub _map_ci {
    my $self = shift;
    my $name = shift;

    return js_sub {
        shift;
        my $instance = ci->$name->new(@_);

        return $self->_map_instance($instance);
    }
}

sub _map_instance {
    my $self = shift;
    my ($instance) = @_;

    return unless $instance;

    my @methods = $self->_map_methods($instance);

    my $method_map = {};

    foreach my $method (@methods) {
        my $method_camelized = _to_camel_case($method);
        $method_map->{$method_camelized} = js_sub { shift; $self->_serialize( {}, $instance->$method(@_) ) };
    }

    return $method_map;
}

sub _map_methods {
    my $self = shift;
    my ($instance) = @_;

    my @methods;

    my @current_methods =
      $instance->can('meta')
      ? ( map { +{ name => $_->name, full => $_->fully_qualified_name } }
          $instance->meta->get_all_methods )
      : ( map { +{ name => [ /^.*::(.*?)$/ ]->[0], full => $_ } }
          _array( Class::Inspector->methods( ref $instance, 'full', 'public' ) ) );

    for my $method ( @current_methods ) {
        my $name = $method->{name};

        # Skip private methods
        next if $name =~ m/^_/;

        # Skip special methods like DESTROY
        next if $name =~ m/^[A-Z]/;

        my $full_name = $method->{full};

        # Skip everything that comes from Moose
        next if $full_name =~ m/^(?:Moose|UNIVERSAL)::/;

        push @methods, $name;
    }

    return @methods;
}

sub _serialize {
    my $self = shift;
    my ( $options, @docs ) = @_;

    $options->{_seen} //= {};

    my @result;
    foreach my $doc (@docs) {
        if ( ref $doc ) {
            $options->{_seen}->{"$doc"}++;

            if ( $options->{_seen}->{"$doc"} > 1 ) {
                push @result, '__cycle_detected__';
                next;
            }
        }

        if ( Scalar::Util::blessed($doc) ) {
            push @result, $self->_map_instance( $doc );
        }
        elsif ( ref $doc eq 'CODE' ) {
            push @result, sub{ $self->_serialize( $options, $doc->(@_) ) };
        }
        elsif ( ref $doc eq 'ARRAY' ) {
            my $array = [];
            foreach my $el (@$doc) {
                push @$array, scalar $self->_serialize( $options, $el );
            }

            push @result, $array;
        }
        elsif ( ref $doc eq 'HASH' ) {
            my $hash = {};
            foreach my $key ( keys %$doc ) {
                $hash->{$key} = $self->_serialize( $options, $doc->{$key} );
            }
            push @result, $hash;
        }
        elsif ( $options->{convert_subs} && ref $doc eq 'CODE' ) {
            return 'function() { ... }';
        }
        else {
            push @result, $doc;
        }
    }

    return wantarray ? @result : $result[0];
}

sub _to_json {
    my $self = shift;
    my ($what) = @_;

    return 'undefined' unless defined $what;

    my $doc = $self->_serialize( { convert_subs => 1 }, $what );
    return $doc unless ref $doc;

    JSON->new->pretty(1)->canonical(1)->encode($doc);
}

sub _generate_cla {
    my $self = shift;
    my ($stash) = @_;
    return {
        loadCla => js_sub {
            shift;
            my $id = shift;
            my $ns = $self->_generate_ns($id,$stash) || die "Clarive standard library namespace not found: $id\n";
            return $ns;
        },
        loadModule => js_sub {
            shift;
            my $id = shift;

            if( $id =~ /^cla\/(.+)$/ ) {
                return sprintf q{
                    (function(){
                        module.exports = cla.loadCla("%s");
                    }());
                }, $1;
            }
            elsif( my $path = Clarive->app->plugins->locate_path( "modules/$id", "modules/$id.js") ) {
                return scalar Util->_file($path)->slurp;
            }
            else {
                die sprintf(
                    "Could not find module `%s` in the following plugins: %s\n",
                    $id, join( ',', Clarive->app>plugins->all_plugins( name_only=>1 ) )
                );
            }
        },
        each => js_sub {
            shift;
            my ($arr, $cb) = @_;

            return 0 unless ref $arr eq 'ARRAY' || !@$arr;

            my $cnt = 0;
            foreach my $el ( @$arr ) {
                $cb->($el,++$cnt);
            }

            $cnt;
        },
        loc => js_sub {
            shift;
            my ($lang, $fmt, @args) = @_;

            my $handle = Baseliner::I18N->get_handle($lang);
            return $handle->maketext($fmt,@args);
        },
        lastError => js_sub {
            shift;
            return $!;
        },
        regex => js_sub {
            my $js = shift;
            my ($re, $opts) = @_;
            { __cla_js=>'regex', re=>$re, opts=>$opts }
        },
        printf => js_sub {
            my $js = shift;

            printf( @_ );
        },
        sprintf => js_sub {
            my $js = shift;
            my $fmt = shift;

            sprintf( $fmt, @_ );
        },
        dump => js_sub {
            my $js = shift;

            print Util->_dump( @_ );
        },
        parseVars => js_sub {
            my $js = shift;
            my ($str, $local_stash) = @_;

            return parse_vars( $str, { %$stash, %{ $local_stash || {} } } );
        },
        sleep => js_sub {
            shift;
            my $s = shift;
            usleep( $s * 1_000_000 );
        },
        stash => js_sub {
            shift;
            my ( $pointer, $value ) = @_;

            return $stash if @_ == 0;

            @_ == 2 ? 
                _json_pointer( $stash, $pointer, $value ) :
                _json_pointer( $stash, $pointer );
        },
        config => js_sub {
            shift;
            my ( $pointer, $value ) = @_;

            @_ == 2 ? 
                _json_pointer( Clarive->app->config, $pointer, $value ) :
                _json_pointer( Clarive->app->config, $pointer );
        },
        configTable => js_sub {
            shift;
            my ( $key, $value ) = @_;

            @_ == 2 ? 
                BaselinerX::Type::Model::ConfigStore->set( key=>$key, value=>$value ) :
                BaselinerX::Type::Model::ConfigStore->get( $key, value=>1 );
        },
    };
}

sub _generate_ns {
    my $self = shift;
    my ($id,$stash) = @_;

    my $all_ns = {
        db => {
            seq => js_sub {
                my $js = shift;
                mdb->seq( @_ );
            },
            getDatabase => js_sub {
                my $js = shift;
                my ($name) = @_;

                my $db = Baseliner::Mongo->new( db_name=>$name );

                return +{
                    ( $self->_generate_db_methods( $db ) ),
                }
            },
            ( $self->_generate_db_methods( $Clarive::_mdb ) ),
        },
        fs => {
            slurp => js_sub {
                my $sh = shift;
                my ($file) = @_;

                local $/;
                my $data;
                open my $fh, '<', $file or _fail "Cannot open file $file: $!";
                $data = <$fh>;
                close $fh or _fail "Cannot close $file: $!";

                return $data;
            },
            openFile => js_sub {
                my $js = shift;
                my ( $file, $mode ) = @_;

                _fail 'file required' unless $file;

                $mode = 'r' unless $mode && $mode =~ m/^r|w$/;
                my $perl_mode = $mode eq 'r' ? '<' : '>';

                open my $fh, $perl_mode, $file or _fail "Cannot open file $file: $!";

                return {
                    write => js_sub {
                        my $js = shift;
                        my ($data) = @_;

                        print $fh $data;
                    },
                    binMode => js_sub {
                        binmode($fh);
                    },
                    readChunk => js_sub {
                        shift;
                        my ($length) = @_;
                        local $/ = \$length;
                        <$fh>;
                    },
                    readLine => js_sub {
                        <$fh>;
                    },
                    eof => js_sub {
                        eof( $fh );
                    },
                    fileno => js_sub {
                        fileno($fh);
                    },
                    close => js_sub {
                        close $fh or _fail "Cannot close $file: $!";
                    }
                };
            },
            stat => js_sub {
                shift;
                my ($file) = @_;
                my @st = stat $file;
                +{
                    file => $file,
                    ( map { $_ => shift(@st) } qw(dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks) )
                }
            },
            iterateDir => js_sub {
                shift;
                my ($dir, $cb) = @_;

                opendir my $dh, $dir or _fail "Cannot open dir $dir: $!";
                foreach my $f ( readdir $dh ) {
                    $cb->($f, File::Spec->catfile($dir,$f) );
                }
                closedir $dh;
            },
            isDir  => js_sub { shift; !!-d $_[0] },
            isFile => js_sub { shift; !!-f $_[0] },
            createFile => js_sub {
                my $js = shift;
                my ( $file, $content ) = @_;

                open my $fh, '>', $file or die "Cannot create file $file: $!";
                print $fh $content if defined $content;
                close $fh;
            },
            deleteFile => js_sub {
                to_duk_bool( unlink $_[1] );
            },
            deleteDir => js_sub {
                to_duk_bool( rmdir $_[1] );
            },
            createDir => js_sub {
                my $js = shift;
                my ($dir) = @_;

                mkdir $dir;
            },
            createPath => js_sub {
                my $js = shift;
                my ($dir) = @_;

                to_duk_bool( Util->_mkpath( $dir ) );
            },
        },
        path => {
            basename => js_sub { File::Basename::basename( $_[1] ) },
            dirname  => js_sub { File::Basename::dirname( $_[1] ) },
            extname  => js_sub { ( File::Basename::fileparse( $_[1], qr/(?<=.)\.[^.]*/ ) )[2] },
            join     => js_sub { shift; File::Spec->catfile(@_) },
        },
        sem => {
            take => js_sub {
                shift;
                my $key = shift || die "Missing semaphore key\n";
                my $cb = shift || die "Missing semaphore function\n";

                my $sem = Baseliner::Sem->new( key=>$key );
                $sem->take;
                return $cb->($sem);
            },
        },
        ci => {
            getClass => js_sub {
                shift;
                my ($camel) = @_;

                die "Missing parameter `classname`\n" unless $camel;

                my $classname = from_camel_class( $camel );

                die "Class `$camel` not found\n" unless $classname;

                $self->_map_ci($classname);
            },
            new => js_sub {
                shift;
                my ($camel,$obj) = @_;

                die "Missing parameter `classname`\n" unless $camel;

                my $classname = from_camel_class( $camel );

                my $instance = ci->$classname->new($obj);

                return $self->_map_instance($instance);
            },
            create => js_sub {
                shift;
                my ($classname,$obj) = @_;

                die "Missing parameter `classname`\n" unless $classname;

                my $package = 'BaselinerX::CI::' . $classname;

                die "Class `$classname` already exists\n" if is_class_loaded( $package );

                my $attributes = delete( $obj->{has} ) || {};
                my $methods    = delete( $obj->{methods} ) || {};
                my $roles      = delete( $obj->{roles} ) || [];
                my $superclasses = delete( $obj->{superclasses} ) || [];

                my $class = Moose::Meta::Class->create( $package,
                    attributes => [
                        map { Moose::Meta::Attribute->new( $_, %{ $attributes->{$_} } ) } keys %$attributes
                    ],
                    roles => ['Baseliner::Role::CI', @$roles ],
                    methods => {
                        icon  => sub { '/static/images/icons/ci.png' },
                        _lang => sub { 'js' },
                        map { $_ => $methods->{$_} } keys %$methods
                    },
                    superclasses => [
                        map { 'BaselinerX::CI::' . from_camel_class( $_ ) } @$superclasses
                    ],
                    %$obj,
                );
                $class->make_immutable;

                return $self->_map_ci($classname);
            },
            listClasses => js_sub {
                shift;
                my $role = shift;
                [ map { ucfirst _to_camel_case( to_base_class($_) ) } packages_that_do($role || 'Baseliner::Role::CI') ];
            },
            find => js_sub {
                shift;
                my $class_or_query = shift;

                if( !ref $class_or_query ) {
                    my $class = from_camel_class( $class_or_query );
                    my $query = shift;
                    $self->_db_wrap_cursor( ci->$class->find($query, @_) );
                } else {
                    my $query = $class_or_query;
                    $self->_db_wrap_cursor( Baseliner::Role::CI->find($query, @_) );
                }

            },
            findOne => js_sub {
                shift;
                my $class_or_query = shift;

                my ($class, $query);

                if( !ref $class_or_query ) {
                    my $class = from_camel_class( $class_or_query );
                    my $query = shift;
                    $self->_serialize( {}, ci->$class->find_one($query, @_) );
                } else {
                    my $query = $class_or_query;
                    $self->_serialize( {}, Baseliner::Role::CI->find_one($query, @_) );
                }
            },
            load => js_sub { shift; $self->_map_instance( ci->new(@_) ) },
            delete => js_sub { shift; ci->delete(@_) }
        },
        log => {
            info  => js_sub { shift; _info( @_ ) },
            debug => js_sub { shift; _debug( @_ ) },
            warn  => js_sub { shift; _warn( @_ ) },
            error => js_sub { shift; _error( @_ ) },
            fatal => js_sub { shift; _fail( @_ ) },
        },
        rule => {
            create => js_sub {
                shift;
                my ($opts,$rule_tree) = @_;

                Baseliner::Model::Rules->save_rule(
                    rule_tree         => $rule_tree,
                    rule_active       => '1',
                    rule_name         => $opts->{name},
                    rule_when         => $opts->{when},
                    rule_event        => $opts->{event},
                    rule_type         => $opts->{type},
                    rule_compile_mode => $opts->{compileMode},
                    rule_desc         => $opts->{description},
                    subtype           => $opts->{subtype},
                    authtype          => $opts->{authtype},
                    wsdl              => $opts->{wsdl},
                );
            },
            run => js_sub {
                shift;
                my ($id_rule,$rule_stash) = @_;

                my $ret_rule = Baseliner::Model::Rules->run_single_rule(
                    id_rule   => $id_rule,
                    stash     => ( ref $rule_stash ? $rule_stash : $stash ),
                    contained => 1
                );

                ref $rule_stash ? $rule_stash : $stash;
            }
        },
        web => {
            agent => js_sub {
                shift;
                my $opts = shift;

                require LWP::UserAgent;

                my $ua = LWP::UserAgent->new( agent=>'clarive/js', %{ $opts || {} } );

                # rgo: map_instance does not work for $ua
                return {
                    request       => js_sub { shift; $ua->request(@_) },
                    get           => js_sub { shift; $self->_map_instance( $ua->get(@_) ) },
                    head          => js_sub { shift; $self->_map_instance( $ua->head(@_) ) },
                    post          => js_sub { shift; $self->_map_instance( $ua->post(@_) ) },
                    put           => js_sub { shift; $self->_map_instance( $ua->put(@_) ) },
                    delete        => js_sub { shift; $self->_map_instance( $ua->delete(@_) ) },
                    mirror        => js_sub { shift; $self->_map_instance( $ua->mirror(@_) ) },
                    simpleRequest => js_sub { shift; $self->_map_instance( $ua->simple_request(@_) ) },
                    isOnline      => js_sub { shift; $ua->is_online(@_) },
                    isProtocolSupported => js_sub { shift; $ua->is_protocol_supported(@_) },
                }
            },
            request => js_sub {
                shift;
                my ($method, $endpoint, $opts) = @_;

                require HTTP::Request::Common;
                my $req = HTTP::Request->new( $method => $endpoint, %{ $opts || {} } );

                return $req;
            },
        },
        ws => {
            request => js_sub {
                shift;
                return {
                    url => js_sub {
                        shift;
                        my $header = shift;
                        return $stash->{WSURL};
                    },
                    body => js_sub {
                        shift;
                        my $header = shift;
                        return $stash->{ws_body};
                    },
                    args => js_sub {
                        shift;
                        return $stash->{ws_arguments} || [];
                    },
                    headers => js_sub {
                        shift;
                        my $header = shift;
                        return length $header
                            ? $stash->{ws_headers}{$header}
                            : $stash->{ws_headers}
                    },
                    params => js_sub {
                        shift;
                        my $param = shift;
                        return length $param
                            ? $stash->{ws_params}{$param}
                            : $stash->{ws_params}
                    }
                }
            },
            response => js_sub {
                shift;
                return {
                    body => js_sub { shift; $stash->{ws_response} = shift },
                    cookies => js_sub { shift; $stash->{ws_response_methods}{cookies} = shift },
                    status => js_sub { shift; $stash->{ws_response_methods}{status} = shift },
                    redirect => js_sub { shift; $stash->{ws_response_methods}{redirect} = shift },
                    location => js_sub { shift; $stash->{ws_response_methods}{location} = shift },
                    write => js_sub { shift; $stash->{ws_response_methods}{write} = shift },
                    content_type => js_sub { shift; $stash->{ws_response_methods}{content_type} = shift },
                    headers => js_sub { shift; $stash->{ws_response_methods}{headers} = shift },
                    header => js_sub { shift; $stash->{ws_response_methods}{header} = shift },
                    get => js_sub {
                        shift;
                        $stash->{ws_response} //= {};
                    },
                    data => js_sub {
                        shift;
                        my ($key,$value) = @_;
                        $stash->{ws_response}{$key} = $value;
                    }
                }
            }
        },
        util => {
            loadYAML => js_sub {
                shift;
                my ( $yaml ) = @_;
                _load( $yaml );
            },
            dumpYAML => js_sub {
                shift;
                my ( $ref ) = @_;
                _dump( $ref );
            },
            loadJSON => js_sub {
                shift;
                _decode_json( @_ );
            },
            dumpJSON => js_sub {
                shift;
                $self->_to_json( @_ );
            },
            unaccent => js_sub {
                shift;
                my ( $str ) = @_;

                return Util->_unac( $str );
            },
            benchmark => js_sub {
                shift;
                my ( $count, $cb ) = @_;

                require Benchmark;

                Benchmark::timethis($count,$cb);
            },
        },
    };
    return $all_ns->{$id};
}

sub _generate_db_methods {
    my $self = shift;
    my ($db) = @_;

    return (
        getCollection => js_sub {
            my $js = shift;
            my ($name) = @_;

            my $col = $db->collection($name);

            return {
                insert => js_sub {
                    my $js = shift;

                    return $col->insert(@_);
                },
                remove => js_sub {
                    my $js = shift;

                    return $col->remove(@_);
                },
                update => js_sub {
                    my $js = shift;

                    return $col->update(@_);
                },
                drop => js_sub {
                    my $js = shift;

                    return $col->drop;
                },
                findOne => js_sub {
                    my $js = shift;

                    my $doc = $col->find_one( @_ );

                    return $self->_serialize( {}, $doc );
                },
                clone => js_sub {
                    my $js = shift;

                    return $col->clone( @_ );
                },
                find => js_sub {
                    my $js = shift;

                    my $cursor = $col->find(@_);

                    return $self->_db_wrap_cursor( $cursor );
                }
            };
        }
    );
}

sub _db_wrap_cursor {
    my $self = shift;
    my $cursor = shift;
    return {
        next    => js_sub { $self->_serialize( {}, $cursor->next ) },
        hasNext => js_sub { $cursor->has_next },
        forEach => js_sub {
            my $js = shift;
            my ($cb) = @_;

            return unless $cb && ref $cb eq 'CODE';

            while ( my $entry = $cursor->next ) {
                $cb->( $self->_serialize( {}, $entry ) );
            }

            return;
        },
        count => js_sub { $cursor->count },
        fields=> js_sub { shift; $cursor->fields(@_) },
        limit => js_sub { shift; $cursor->limit(@_) },
        skip  => js_sub { shift; $cursor->skip(@_) },
        sort  => js_sub { shift; $cursor->sort(@_) },
    };
}

sub _process_pragmas {
    my $self = shift;
    my $code = shift;

    for my $pragma ( $code =~ m{//CLA-PRAGMA (\S+)}g ) {
        if( $pragma =~ 'enclose=(\d+)' ) {
            $self->enclose_code($1);
        }
        elsif( $pragma =~ 'dump_code=(\d+)' ) {
            $self->dump_code($1);
        }
    }
}
1;
