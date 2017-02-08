package Baseliner::Search;
use Moose;

use Baseliner::Utils qw(_debug _dump);

sub inject_search_query {
    my $self = shift;
    my ( $where, $query, %params ) = @_;

    my $what   = $params{what}   // '';
    my $fields = $params{fields} // [];

    if ( $query !~ /^\s*"/ && ( $query =~ m{\*|\?|/|\:} || $query =~ m{(^[\+\-])|(\s+[\+\-])} ) ) {
        _debug "$what QUERY REGEX=$query\n" . _dump($where);

        mdb->query_build( where => $where, query => $query, fields => $fields );
    }
    else {
        $query =~ s{(\S+[\.\-]\S+)}{"$1"}g;
        $query =~ s{""+}{"}g;

        _debug "$what QUERY FULL TEXT=$query";

        $where->{'$text'} = { '$search' => $query };
    }

    return $where;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
