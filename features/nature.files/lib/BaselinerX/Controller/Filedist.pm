package BaselinerX::Controller::Filedist;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Sugar;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
# use BaselinerX::Ktecho::CamUtils;
use Data::Dumper;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' }

sub save : Local {
  my ($self, $c) = @_;
  my $p = $c->req->params;
  try {
    if (my $id = $p->{id}) {
      repo->set(ns => $id, data => $p);
    }
    else {
      my $id = int rand 99999999999;
      repo->set(ns => 'filedist/' . $id, data => $p);
    }
    $c->stash->{json} = {success => \1};
  }
  catch {
    my $err = shift;
    _log $err;
    $c->stash->{json} = {success => \0,
                         msg     => _loc('Error saving file mapping: %1', $err)};
  };
  $c->forward('View::JSON');
}

sub from_paths : Local {
  my ($self, $c) = @_;
  my $p = $c->req->parameters;
  try {
    my $nsid   = $p->{ns};
    my $query  = $p->{query};
    my $prefix = $p->{prefix};
    my $os     = $p->{os} =~ /win/ ? 'WIN' : 'UNIX';

    # TODO make this generic
    my @vp = defined $nsid
      ? do { my $ns = ns_get($nsid); $ns->project_viewpaths(query => $query) }
      : do { BaselinerX::CA::Harvest::DB->viewpaths_query_nofiles("$prefix\%$query\%") };

    @vp = map { s{\\}{/}g; +{path => $_} } grep(_pathxs($_, 3) eq $os, grep(_pathxs($_, 2) eq 'FICHEROS', @vp));
    $c->stash->{json} = {totalCount => scalar(@vp), data => \@vp};
  }
  catch {
    my $err = shift;
    _log $err;
    $c->stash->{json} = {success => \0, msg => _loc('Error selecting paths: %1', $err)};
  };
  $c->forward('View::JSON');
}

sub hosts : Local {
  my ($self, $c) = @_;
  my $p = $c->req->parameters;
  my $bl_letter  = substr($p->{bl}, 0, 1);
  my $cam        = substr($p->{project}, 0, 3);
  my $os         = $p->{os};
  my $inf        = inf $cam;

  my @ret;

  if ($os =~ /win/i) {
    my $where = {status_flag => 1, env => {like => "\%$p->{bl}\%"}};
    my $args  = {select => 'server'};
    my $rs = Baseliner->model('Inf::InfServerWin')->search($where, $args);
    rs_hashref($rs);
    my @data = $rs->all;
    @ret = map $_->{server}, @data;
  }
  else {
    my $data = $inf->get_inf(undef,
                             [map {
                               {column_name => 'AIX_SERVER',
                                idred       => $_,
                                ident       => $bl_letter},
                               {column_name => 'AIX_UFUN',
                                idred       => $_,
                                ident       => $bl_letter},
                               {column_name => 'AIX_GFUN',
                                idred       => $_,
                                ident       => $bl_letter}
                             } bde_nets]);
  
    my $resolver =
         BaselinerX::Ktecho::Inf::Resolver->new({cam     => $cam,
                                                 entorno => uc($p->{bl}),
                                                 sub_apl => 'none'});
  
    # Build array of hashes. Note that we pick only the values that can
    # be solved.
    @ret = map { $resolver->get_solved_value($_) =~ m/(.+)\(/ }
               grep ($resolver->get_solved_value($_), @{$data});
  }

  # Remove duplicates.
  my %hash = map { $_, 1 } @ret;
  @ret = map +{host => $_}, keys %hash;

  $c->stash->{json} = {totalCount => scalar(@ret),
                       data       => \@ret};

  $c->forward('View::JSON');
}

sub users : Local {
  my ($self, $c) = @_;
  my $p         = $c->req->parameters;
  my $ns        = $p->{ns};
  my $bl        = $p->{bl};
  my $ns_short  = lc(substr($p->{project}, 0, 3));
  my $bl_letter = lc(substr($bl, 0, 1));
  my @ret;
  push @ret, {user => 'v' . $bl_letter . $ns_short};
  $c->stash->{json} = {totalCount => scalar(@ret), data => \@ret};
  $c->forward('View::JSON');
}

sub groups : Local {
  my ($self, $c) = @_;
  my $p         = $c->req->parameters;
  my $ns        = $p->{ns};
  my $bl        = $p->{bl};
  my $ns_short  = lc(substr($p->{project}, 0, 3));
  my $bl_letter = lc(substr($bl, 0, 1));
  my @ret;
  push @ret, {group => 'g' . $bl_letter . $ns_short};
  $c->stash->{json} = {totalCount => scalar(@ret), data => \@ret};
  $c->forward('View::JSON');
}

=head2 Catalog role requirements 

Implements a catalog provider

=cut

sub catalog_add { }

sub catalog_del {
  my ($class, %p) = @_;
  $p{id} or _throw 'Missing id';
  repo->delete(ns => $p{id});
}

sub catalog_list {
  my @list;
  for my $ns (repo->list(provider => 'filedist')) {
    my $data = repo->get(ns => $ns);
    push @list,
      {id          => $ns,
       row         => $data,
       ns          => $data->{ns} || $data->{project},
       bl          => $data->{bl},
       description => $data->{description},
       for         => {from => $data->{from} || $data->{viewpath}, os => $data->{os} || 'any'},
       mapping     => {to => $data->{to}, user => $data->{user}, group => $data->{group}, host => $data->{host}},};
  }
  return wantarray ? @list : \@list;
}

sub catalog_name        {'Mapeo de Ficheros'}
sub catalog_description {'Mapea ficheros'}
sub catalog_icon        {'/static/images/icons/action_save.gif'}
sub catalog_url         {'/comp/filedist/form_unix.js'}
sub catalog_seq         {100}

1;
