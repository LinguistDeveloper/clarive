package Baseliner::Code::JS;
use Moose;

use JavaScript::Duktape;
use JSON ();
use Try::Tiny;
use File::Basename ();
use Scalar::Util qw(blessed);
use Baseliner::Mongo;
use Baseliner::Utils qw(parse_vars packages_that_do _to_camel_case _unbless :logging);
use Storable ();
use Clarive::App;

sub eval_code {
    my $self = shift;
    my ( $code, $stash ) = @_;

    my $js = JavaScript::Duktape->new;
    $js->set(
        toJSON => sub {
            shift;
            my ($what) = @_;

            return $self->_to_json($what);
        }
    );

    $js->set(
        Cla => {
            parseVars => sub {
                my $js = shift;
                my ($str) = @_;

                return parse_vars( $str, $stash );
            },
            DB => sub {
                my $db = Baseliner::Mongo->new;

                return {
                    getCollection => sub {
                        my $js = shift;
                        my ($name) = @_;

                        my $col = $db->collection($name);

                        return {
                            insert => sub {
                                my $js = shift;

                                return $col->insert(@_);
                            },
                            remove => sub {
                                my $js = shift;

                                return $col->remove(@_);
                            },
                            update => sub {
                                my $js = shift;

                                return $col->update(@_);
                            },
                            findOne => sub {
                                my $js = shift;

                                my $doc = $col->find_one(@_);

                                return $self->_serialize( {}, $doc );

                            },
                            find => sub {
                                my $js = shift;

                                my $cursor = $col->find(@_);

                                return {
                                    next    => sub { $self->_serialize( {}, $cursor->next ) },
                                    hasNext => sub { $cursor->has_next },
                                    forEach => sub {
                                        my $js = shift;
                                        my ($cb) = @_;

                                        while ( my $entry = $cursor->next ) {
                                            $cb->( $self->_serialize( {}, $entry ) );
                                        }

                                        return;
                                    },
                                    count => sub { $cursor->count },
                                    limit => sub { shift; $cursor->limit(@_) },
                                    skip  => sub { shift; $cursor->skip(@_) },
                                    sort  => sub { shift; $cursor->sort(@_) },
                                };
                            }
                        };
                    }
                };
            },
            FS => {
                slurp => sub {
                    my $sh = shift;
                    my ($file) = @_;

                    local $/;
                    my $data;
                    open my $fh, '<', $file or _fail "Cannot open file $file: $!";
                    $data = <$fh>;
                    close $fh or _fail "Cannot close $file: $!";

                    return $data;
                },
                openFile => sub {
                    my $js = shift;
                    my ( $file, $mode ) = @_;

                    _fail 'file required' unless $file;

                    $mode = 'r' unless $mode && $mode =~ m/^r|w$/;
                    my $perl_mode = $mode eq 'r' ? '<' : '>';

                    open my $fh, $perl_mode, $file or _fail "Cannot open file $file: $!";

                    return {
                        write => sub {
                            my $js = shift;
                            my ($data) = @_;

                            print $fh $data;
                        },
                        readLine => sub {
                            <$fh>;
                        },
                        close => sub {
                            close $fh or _fail "Cannot close $file: $!";
                        }
                    };
                },
                openDir => sub {
                    my $js = shift;
                    my ($dir) = @_;

                    opendir my $dh, $dir or _fail "Cannot open dir $dir: $!";

                    return {
                        path    => $dir,
                        readDir => sub {
                            my $js = shift;

                            return readdir $dh;
                        },
                        close => sub {
                            closedir $dh;
                        }
                    };
                },
                isDir  => sub { shift; !!-d $_[0] },
                isFile => sub { shift; !!-f $_[0] },
                createFile => sub {
                    my $js = shift;
                    my ( $file, $content ) = @_;

                    open my $fh, '>', $file or die "Cannot create file $file: $!";
                    print $fh $content if defined $content;
                    close $fh;
                },
                deleteFile => sub {
                    unlink $_[1];
                },
                deleteDir => sub {
                    rmdir $_[1];
                },
                createDir => sub {
                    my $js = shift;
                    my ($dir) = @_;

                    mkdir $dir;
                },
            },
            Path => {
                basename => sub { File::Basename::basename( $_[1] ) },
                dirname  => sub { File::Basename::dirname( $_[1] ) },
                extname  => sub { ( File::Basename::fileparse( $_[1], qr/(?<=.)\.[^.]*/ ) )[2] },
                join     => sub { shift; File::Spec->catfile(@_) },
            },
            CI  => { map { _to_camel_case($_) => $self->_map_ci($_) } $self->_list_available_ci_classes },
            Log => {
                info  => sub { shift; _info($self->_to_json(@_)) },
                debug => sub { shift; _debug($self->_to_json(@_)) },
                warn  => sub { shift; _warn($self->_to_json(@_)) },
                error => sub { shift; _error($self->_to_json(@_)) },
                fatal => sub { shift; _fail($self->_to_json(@_)) },
            }
        },
    );

    return try {
        $js->eval($code);
    }
    catch {
        _fail "Error executing JavaScript: $_";
    };
}

sub _list_available_ci_classes {
    my $self = shift;

    my @coll;
    for my $pkg ( packages_that_do('Baseliner::Role::CI') ) {
        my $coll = $pkg->collection;
        push @coll, $coll;
    }

    return @coll;
}

sub _map_ci {
    my $self = shift;
    my $name = shift;

    return sub {
        shift;
        my $instance = ci->$name->new(@_);
        return unless $instance;

        my @methods = $self->_map_methods($instance);

        my $method_map = {};

        foreach my $method (@methods) {
            my $method_camelized = _to_camel_case($method);
            $method_map->{$method_camelized} = sub { shift; $self->_serialize( {}, $instance->$method(@_) ) };
        }

        return $method_map;
      }
}

sub _map_methods {
    my $self = shift;
    my ($instance) = @_;

    my @methods;
    for my $method ( $instance->meta->get_all_methods ) {
        my $name = $method->name;

        # Skip private methods
        next if $name =~ m/^_/;

        # Skip special methods like DESTROY
        next if $name =~ m/^[A-Z]/;

        my $full_name = $method->fully_qualified_name;

        # Skip everything that comes from Moose
        next if $full_name =~ m/^(?:Moose|UNIVERSAL)::/;

        push @methods, $name;
    }

    return @methods;
}

sub _serialize {
    my $self = shift;
    my ( $options, @docs ) = @_;

    my @result;
    foreach my $doc (@docs) {
        if ( Scalar::Util::blessed($doc) ) {
            push @result, _unbless($doc);
        }
        elsif ( ref $doc eq 'ARRAY' ) {
            my $array = [];
            foreach my $el (@$doc) {
                push @$array, $self->_serialize( $options, $el );
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
        if ( $options->{convert_subs} && ref $doc eq 'CODE' ) {
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

1;
