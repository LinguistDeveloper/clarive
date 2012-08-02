package Baseliner::Controller::Feature;
use Baseliner::Plug;
use Baseliner::Utils;
use DateTime;
use Carp;
use Path::Class qw(dir);

BEGIN { extends 'Catalyst::Controller' }

register 'menu.admin.features' => { label => 'Features', icon=>'/static/images/chromium/plugin.png' };
register 'menu.admin.features.list' => { label => 'List Features', url_comp=>'/feature/grid', title=>'Features', icon=>'/static/images/chromium/plugin.png' };
register 'menu.admin.features.install' => { label => 'Install Features', url_comp=>'/feature/install', title=>'Install', icon=>'/static/images/chromium/plugin.png'};

sub details : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $id = $p->{id};
    my @data;
    for my $f ( $c->features->list ) {
        if( $f->id eq $id ) {
            my $home = dir( $f->path );
            $home->recurse( callback=>sub{
                my $d = shift;
                push @data, $d->absolute;
            });
            last;
        }
    }
    $c->response->body( '<pre><li>' . join'<li>',@data );
}

sub list : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = @{$p}{qw/start limit query dir sort/};
    my @rows;
    for my $f ( $c->features->list ) {
        next if( $query && !query_array($query, $f->id, $f->name, $f->version ));
        push @rows, {
            id      => $f->id,
            name    => $f->name,
            description    => $f->name,
            path    => $f->path,
            provider       => $f->name,
            version => $f->version,
        } if( ($cnt++>=$start) && ( $limit ? scalar @rows < $limit : 1 ) );
    }
    @rows = sort { $a->{ $sort } cmp $b->{ $sort } } @rows if $sort;
    $c->stash->{json} = {
        totalCount=>scalar @rows,
        data=>\@rows
    };
    $c->forward('View::JSON');
}

sub grid : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = '/comp/feature_grid.mas';
}

1;
