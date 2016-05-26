package Clarive::Code::SQL;
use Moose;
BEGIN { extends 'Clarive::Code::Base' }

use Baseliner::Utils qw(_fail _loc);

sub eval_code {
    my $self = shift;
    my ( $code, $stash ) = @_;

    $stash ||= {};

    return $self->_sql($code);
}

sub _sql {
    my ( $self, $code ) = @_;

    my @conn = $code =~ /^(.+?),(.*?),(.*?)\n(.*)$/s;
    _fail _loc( 'Missing first line DBI connect string. '
          . 'Ex: DBI:mysql:database=<db>;host=<hostname>;port=<port>,my-username,my-password' )
      unless @conn;

    $code = pop @conn;

    my @statements = $self->_sql_normalize($code);

    my $dbs = Util->_dbis( \@conn );

    my @results;
    foreach my $statement (@statements) {
        if ( $statement =~ m/^select/i ) {
            my $result = $dbs->query($statement);
            push @results, $result->hashes;
        }
        else {
            my $cnt = $dbs->dbh->do($statement);
            push @results,
              {
                Rows            => $cnt,
                'Error Code'    => $dbs->dbh->err,
                'Error Message' => $dbs->dbh->errstr,
                Statement       => $statement
              };
        }
    }

    return \@results;
}

sub _sql_normalize {
    my ( $self, $sql ) = @_;

    my @sts;
    my $st;
    for ( split /\n|\r/, $sql ) {
        next if /^\s*--/;

        if (/^(.+);\s*$/) {
            $st .= $1;
            push @sts, $st;
            $st = '';
        }
        else {
            $st .= $_;
        }
    }

    push @sts, $st if $st;

    return @sts;
}

1;
