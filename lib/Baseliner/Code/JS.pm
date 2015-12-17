package Baseliner::Code::JS;
use Moose;

use JavaScript::Duktape;
use JSON ();
use Try::Tiny;
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
            }
        }
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
