package BaselinerX::Model::CargaLdifQueries;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Core::DBI;
use v5.10;
BEGIN { extends 'Catalyst::Model' }

sub insert_new_users_to_public {
    my ( $self, $c ) = @_;
    my $db = Baseliner::Core::DBI->new( { model => 'Harvest' } );
    
    my $sql =  qq{  INSERT INTO harusersingroup
                                (usrobjid,
                                 usrgrpobjid)
                    SELECT hu.usrobjid,
                           2
                    FROM   haruser hu
                    WHERE  NOT EXISTS (SELECT 'x'
                                       FROM   harusersingroup huig
                                       WHERE  huig.usrobjid = hu.usrobjid
                                              AND huig.usrgrpobjid = 2) };

    #return $sql;
}

1;
