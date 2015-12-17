package Baseliner::Code::JS;
use Moose;

use JavaScript::Duktape;
use JSON ();
use Try::Tiny;
use File::Basename ();
use Baseliner::Mongo;
use Baseliner::Utils qw(parse_vars _fail);

sub eval_code {
    my $self = shift;
    my ( $code, $stash ) = @_;

    my $js = JavaScript::Duktape->new;
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

                                return $self->_serialize($doc);

                            },
                            find => sub {
                                my $js = shift;

                                my $cursor = $col->find(@_);

                                return {
                                    next    => sub { $self->_serialize( $cursor->next ) },
                                    hasNext => sub { $cursor->has_next },
                                    forEach => sub {
                                        my $js = shift;
                                        my ($cb) = @_;

                                        while ( my $entry = $cursor->next ) {
                                            $cb->( $self->_serialize($entry) );
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

sub _serialize {
    my $self = shift;
    my ($doc) = @_;

    my $json = JSON->new->allow_blessed->convert_blessed;

    $doc = $json->encode($doc);
    $doc = $json->decode($doc);

    return $doc;
}

1;
