    my $rs_users = Baseliner->model("Harvest::Haruser")->search(
        undef,
        {
            select   => [ 'username', 'usergroupname' ],
            as       => [ qw/ USR GRP / ],
            join     => { harusersingroups => [ 'usrobjid', 'usrgrpobjid' ] },
            order_by => { -asc => [ 'username', 'usergroupname' ] },
        },
    );
    rs_hashref($rs_users);

    my @users = $rs_users->all;
    # Muestra usuarios y sus respectivos grupos

    my $count = 1;
    my $string;
    my $usr;
    my $grp;

    while ($count <= 10) {
        $string = shift @users;
        $usr    = $string->{USR};
        $grp    = $string->{GRP};
        $count++;

        print "USR: $usr\nGRP: $grp\n\n";
    }
__END__
USR: bob                             
GRP: Departamentos_Usuarios                                                                                                          

USR: bob                             
GRP: HAA                                                                                                                             

USR: bob                             
GRP: HNS                                                                                                                             

USR: bob                             
GRP: OAR                                                                                                                             

USR: bob                             
GRP: Public                                                                                                                          

USR: bob                             
GRP: RPT-BTS                                                                                                                         

USR: bob                             
GRP: RPT-ORACLE                                                                                                                      

USR: bob                             
GRP: RPT-WAS                                                                                                                         

USR: bob                             
GRP: RPT-WIN                                                                                                                         

USR: bob                             
GRP: SCT                                                                                                                             


--- ''

