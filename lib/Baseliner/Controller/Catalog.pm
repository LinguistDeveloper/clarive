package Baseliner::Controller::Catalog;
use Baseliner::Plug;
BEGIN { extends 'Catalyst::Controller' }

use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;

register 'menu.nature.baseline' => {
    label    => _loc('Catalog'),
    url_comp => '/catalog/grid',
    icon => '/static/images/icons/catalog.gif',
    title    => _loc('Catalog'),
};

sub grid : Local {
    my ($self,$c)=@_;
    $c->stash->{template} = '/comp/catalog_grid.js';
}

sub json : Local {
    my ($self,$c)=@_;
    my @data;
    my $p = $c->request->parameters;
    my $query = delete $p->{query};
    my $limit = delete $p->{limit};
    my $start = delete $p->{start};
    for my $pkg ( packages_that_do( 'Baseliner::Role::Catalog' ) ) {
        my %cat = ( pkg=>$pkg,
            url         => $pkg->catalog_url,
            icon        => $pkg->catalog_icon,
            name        => $pkg->catalog_name,
            description => $pkg->catalog_description ); 
        for my $rec ( $pkg->catalog_list( query=>$query, start=>$start, limit=>$limit ) ) {
            my $h = { %cat, %$rec };
            $h->{ns} ||= '/';
            $h->{bl} ||= '*';
            $h->{project} = ( ns_get $h->{ns} )->ns_name;
            next if $query && ! grep { $_ =~ m/$query/i } values %$h;
            push @data, $h;
        }
    }
    #@data = ( { type=>'Manual Deployment', description=>'Deploy Files Manually by manual intervention', for => 'Path: /J2EE', mapping=>'action: action.manual_deploy' });
    $c->stash->{json} = {
        totalCount => scalar(@data),
        data => \@data,
    };
    $c->forward('View::JSON');  
}

sub types : Local {
    my ($self,$c)=@_;
    my @data = map {
        {
            name => $_->catalog_name,
            url  => $_->catalog_url,
            icon  => $_->catalog_icon,
        }
    } sort { $a->catalog_seq <=> $b->catalog_seq }
        packages_that_do( 'Baseliner::Role::Catalog' ) ;
    $c->stash->{json} = {
        totalCount => scalar(@data),
        data => \@data,
    };
    $c->forward('View::JSON');  
}

sub delete : Local {
    my ($self,$c)=@_;
    my $p = $c->request->parameters;
    try {
        my $pkg = $p->{pkg} or _throw 'Missing package';
        $pkg->does('Baseliner::Role::Catalog') or _throw "Package $pkg does not do Catalog";
        $pkg->catalog_del( %$p );
        $c->stash->{json} = { success=>\1 };
    } catch {
        $c->stash->{json} = { success=>\0 };
    };
    $c->forward('View::JSON');  
}

1;
