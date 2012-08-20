use v5.10;

my ($start, $limit, $query, $dir, $sort, $cnt ) = @{$p}{qw/start limit query dir sort/};
$start||=0;
$limit||=10;
my $page = to_pages( start=>$start, limit=>$p->{limit} );
my $where = {};
$where->{username} = $p->{name} if defined $p->{name};
$where->{realname} = $p->{realname} if defined $p->{realname};

$query = 'inf';
$where->{'lower(username||realname)'} = { -like => '%' . lc($query) . '%' } if $query;

## ({ -and=>[ { username =>{ -like => 'infro%'} }, { username =>{ -like => 'infsb%' } } ]  });

my $args = { columns=>['username'], page=>$page, rows=>$limit };
$args->{order_by} = "$sort $dir" if $sort;

my $rs = Baseliner->model('Harvest::Haruser')->search( $where, $args );
rs_hashref( $rs );
my @data = $rs->all;
#my @users = grep { $_ =~ /^inf/ } map { $_->{username} } @data;

#Baseliner->model('Harvest::Haralluser')->search({ username => { -in =>  } 

#$c->stash->{json} = {
#    totalCount => @data,
#    data => \@data
#};


\@data


#\@users
__END__
--- 
- 
  username: "infaac                          "
- 
  username: "infaadx                         "
- 
  username: "infaagx                         "
- 
  username: "infaal                          "
- 
  username: "infaamx                         "
- 
  username: "infabrx                         "
- 
  username: "infabsx                         "
- 
  username: "infacp                          "
- 
  username: "infacr                          "
- 
  username: "infadf                          "

