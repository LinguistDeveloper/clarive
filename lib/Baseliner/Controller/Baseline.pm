package Baseliner::Controller::Baseline;
use Baseliner::Plug;
use Try::Tiny;
BEGIN {  extends 'Catalyst::Controller' }

use Baseliner::Utils;
use Baseliner::Core::Baseline;
use utf8;

register 'menu.admin.core.bl' => { label => _loc('List all Baselines'), url=>'/core/baselines', title=>_loc('Baselines')  };
register 'menu.admin.baseline' => { label => _loc('Baselines'),
    url_comp=>'/baseline/grid', title=>_loc('Baselines'),
    icon=> '/static/images/icons/baseline.gif',
};

sub load_baselines : Private {
    my ($self,$c)=@_;
    my @bl_arr = ();
    my @bl_list = Baseliner::Core::Baseline->baselines();
    return $c->stash->{baselines} = [ [ '*', 'Global' ] ] unless @bl_list > 0;
    foreach my $n ( @bl_list ) {
        my $arr = [ $n->{bl}, $n->{name} ];
        push @bl_arr, $arr;
    }
    $c->stash->{baselines} = \@bl_arr;
}

sub load_baselines_no_root : Private {
    my ($self,$c)=@_;
    my @bl_arr = ();
    my @bl_list = Baseliner::Core::Baseline->baselines_no_root();
    return $c->stash->{baselines} = [ [ '*', 'Global' ] ] unless @bl_list > 0;
    foreach my $n ( @bl_list ) {
        my $arr = [ $n->{bl}, $n->{name} ];
        push @bl_arr, $arr;
    }
    $c->stash->{baselines} = \@bl_arr;
}

sub load_baselines_for_action : Private {
    my ($self,$c)=@_;
    my $action = $c->stash->{action} or _throw "Missing stash parameter 'action'";
    my @bl_arr = ();
    my @bl_list = Baseliner::Core::Baseline->baselines_no_root();
    return $c->stash->{baselines} = [ [ '*', 'Global' ] ] unless @bl_list > 0;
    my $is_root = $c->model('Permissions')->is_root( $c->username );
    foreach my $n ( @bl_list ) {
        next unless $is_root or $c->model('Permissions')->user_has_action( username=>$c->username, action=>$action, bl=>$n->{bl} );
        my $arr = [ $n->{bl}, $n->{name} ];
        push @bl_arr, $arr;
    }
    $c->stash->{baselines} = \@bl_arr;
}

sub bl_list : Path('/core/baselines') {
    my ($self,$c)=@_;
    my @bl_list = Baseliner::Core::Baseline->baselines();
    my $res='<pre>';
    for my $n ( @bl_list ) {
        $res.= Dump $n
    }
    $c->res->body($res);
}

sub grid : Local {
    my ($self,$c)=@_;
    $c->stash->{template} = '/comp/baseline_grid.mas';
}

sub list : Local {
    my ($self,$c)=@_;
    my $rs = $c->model('Baseliner::BaliBaseline')->search;
    rs_hashref $rs;
    my @bl_list = $rs->all;
    $c->stash->{json} = { data=>\@bl_list, totalCount=>scalar @bl_list };
    $c->forward('View::JSON');
}

sub update : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    $c->stash->{json} = try {
        case delete $p->{action} =>
            add => sub {
                $c->model('Baseliner::BaliBaseline')->create({
                 bl    => $p->{bl},
                 name  => $p->{name},
                 description=> $p->{description},
                });
            },
            delete => sub {  
                $c->model('Baseliner::BaliBaseline')->find( $p->{id} )->delete;
            },
            update => sub {  
                my $row = $c->model('Baseliner::BaliBaseline')->find( $p->{id} );
                _log _dump $p;
                $row->set_columns( $p );
                $row->update;
            },
         ;
        { msg=>_loc('Baselines updated'), success=>\1 }
    } catch {
        { msg=>_loc('Error updating Baselines: %1', shift()), success=>\1 }
    };
    $c->forward('View::JSON');
}

sub json : Local {
    my ($self,$c)=@_;
    my @bl_list =
    map {
        +{  name        => $_->{name},
            description => $_->{description} || $_->{name},
            id          => $_->{bl},
            bl          => $_->{bl},
            active      => 1
         }
    } Baseliner::Core::Baseline->baselines();
    $c->stash->{json} = { totalCount=>scalar(@bl_list), data=> \@bl_list };
    $c->forward('View::JSON');
}

1;


