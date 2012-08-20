package BaselinerX::Controller::Filedist;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use BaselinerX::Ktecho::CamUtils;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' }

sub save : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    try {
        if( my $id = $p->{id} ) {
            repo->set( ns=>$id , data=>$p );
        } else {
            my $id = int rand 99999999999;
            repo->set( ns=>'filedist/' . $id , data=>$p );
        }
        $c->stash->{ json } = { success=> \1 };
    } catch {
        my $err = shift;
        _log $err;
        $c->stash->{ json } = { success => \0, msg=>_loc( 'Error saving file mapping: %1', $err ) };
    };
    $c->forward( 'View::JSON' );
}

sub from_paths : Local {
    my ($self,$c)=@_;
    my $p = $c->req->parameters;
    try {
        my $nsid   = $p->{ns};
        my $query  = $p->{query}; 
        my $prefix = $p->{prefix}; 
        my $os     = $p->{os};
        # TODO make this generic
        my @vp = defined $nsid
                   ? do { my $ns = ns_get($nsid); $ns->project_viewpaths(query => $query); }
                   : do { BaselinerX::CA::Harvest::DB->viewpaths_query_nofiles("$prefix\%$query\%") };
#                  : do { BaselinerX::CA::Harvest::Namespace::Application->viewpath_query("$prefix\%$query\%") };
        #@vp = grep /$query/i, @vp;
        @vp = map { s{\\}{/}g; +{ path => $_ } } 
                  grep(_pathxs($_, 3) =~ m/$os/i,
                       grep(_pathxs($_, 2) eq 'FICHEROS', @vp));
        $c->stash->{ json } = { totalCount=>scalar(@vp), data=>\@vp };
    } catch {
        my $err = shift;
        _log $err;
        $c->stash->{ json } = { success => \0, msg=>_loc( 'Error selecting paths: %1', $err ) };
    };
    $c->forward( 'View::JSON' );
}

sub hosts : Local {
  my ($self, $c) = @_;
  my $p          = $c->req->parameters;
  my $bl_letter  = substr($p->{bl}, 0, 1);
  my $cam        = substr($p->{project}, 0, 3);
  my $inf        = inf $cam;

  # Get stuff from INF_DATA.
  my $data = $inf->get_inf(undef,
                           [{ column_name => 'AIX_SERVER'
                            , idred       => 'I'
                            , ident       => $bl_letter }]);

  # Solve values.
  my $resolver = 
       BaselinerX::Ktecho::Inf::Resolver->new({ cam     => $cam
                                              , entorno => uc($p->{bl})
                                              , sub_apl => 'none' });

  # Build array of hashes. Note that we pick only the values that can
  # be solved.
  my @ret = map { $resolver->get_solved_value($_) =~ m/(.+)\(/ }
                grep ($resolver->get_solved_value($_), @{$data});

  # Remove duplicates.
  my %hash = map { $_, 1 } @ret;
  @ret = map +{ host => $_ }, keys %hash;

  $c->stash->{json} = { totalCount => scalar(@ret)
                      , data       => \@ret };
  $c->forward('View::JSON');
}

sub users : Local {
    my ($self,$c)=@_;
    my $p = $c->req->parameters;
    my $ns = $p->{ns};
    my $bl = $p->{bl};
    my $ns_short = lc( substr( $p->{project}, 0,3 ) );
    my $bl_letter = lc( substr( $bl, 0,1 ) );
    my @ret;
    push @ret, { user=>'v' . $bl_letter . $ns_short };
    $c->stash->{ json } = { totalCount=>scalar(@ret), data=>\@ret };
    $c->forward( 'View::JSON' );
}

sub groups : Local {
    my ($self,$c)=@_;
    my $p = $c->req->parameters;
    my $ns = $p->{ns};
    my $bl = $p->{bl};
    my $ns_short = lc( substr( $p->{project}, 0,3 ) );
    my $bl_letter = lc( substr( $bl, 0,1 ) );
    my @ret;
    push @ret, { group=>'g' . $bl_letter . $ns_short };
    $c->stash->{ json } = { totalCount=>scalar(@ret), data=>\@ret };
    $c->forward( 'View::JSON' );
}

=head2 Catalog role requirements 

Implements a catalog provider

=cut

sub catalog_add { }

sub catalog_del {
    my ($class,%p) = @_;
    $p{id} or _throw 'Missing id';
    repo->delete( ns=>$p{id} );
}

sub catalog_list {
    my @list;
    for my $ns ( repo->list( provider=>'filedist' ) ) {
        my $data = repo->get( ns=>$ns );
        push @list, {
            id  => $ns,
            row => $data,
            ns  => $data->{ns} || $data->{project},
            bl  => $data->{bl},
            description => $data->{description},
            for => { from=>$data->{from} || $data->{viewpath}, os=>$data->{os}||'any' },
            mapping => { to=>$data->{to}, user=>$data->{user}, group=>$data->{group}, host=>$data->{host} },
        };
        #{
        #    for => { viewpath=>'/SCT/FICHEROS/UNIX' },
        #    mapping => { to=>'/tmp/prueba', user=>'vtscm', group=>'gtscm' },
        #    id => 1,
        #    name => 'Mapeo SCT',
        #};
    }
    return wantarray ? @list : \@list;
}

sub catalog_name { 'Mapeo de Ficheros' }
sub catalog_description { 'Mapea ficheros' }
sub catalog_icon { '/static/images/icons/action_save.gif' }
sub catalog_url { '/comp/filedist/form_unix.js' }
sub catalog_seq { 100 }

1;
