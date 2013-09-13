package Baseliner::Controller::Baseline;
use Baseliner::Plug;
use Try::Tiny;
BEGIN {  extends 'Catalyst::Controller' }

use Baseliner::Utils;
use Baseliner::Sugar;
use Baseliner::Core::Baseline;
use utf8;
use v5.10;

register 'menu.admin.core.bl' => { label => _loc('List all Baselines'), url=>'/core/baselines', title=>_loc('Baselines')  };

register 'action.admin.baseline' => { name => 'Administer baselines'};

# register 'menu.admin.baseline' => { label => _loc('Baselines'),
#     url_comp=>'/baseline/grid', title=>_loc('Baselines'),
#     icon=> '/static/images/icons/baseline.gif',
#     action => 'action.admin.baseline',
# };


########################################################################################################################
#INICIO METODOS ANTERIORES
########################################################################################################################

sub load_baselines : Private {
    my ($self,$c)=@_;
    my @bl_arr = ();
    my @bl_list = Baseliner::Core::Baseline->baselines();
    return $c->stash->{baselines} = [ [ '*', 'Global' ] ] unless @bl_list > 0;
    foreach my $n ( @bl_list ) {
        my $arr = [ $n->{bl}, _loc($n->{name}) ];
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
        my $arr = [ $n->{bl}, _loc($n->{name}) ];
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
        my $arr = [ $n->{bl}, _loc($n->{name}) ];
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

sub json : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $common = _loc('Common');
    my @bl_list =
    map {
        my $bl = $_->{bl} eq '*' ? $common : $_->{bl};
        +{  name        => _loc($_->{name}),
            description => $_->{description} || _loc($_->{name}),
            id          => $_->{bl},
            bl          => $_->{bl},
            active      => 1,
            bl_name=>sprintf( ( defined $_->{name} ? "%s (%s)" : "%s" ),$bl, _loc($_->{name}) ),
            name_bl=>( defined $_->{name} ? sprintf("%s (%s)" , _loc($_->{name}), $bl ) : $bl )  
         }
    } Baseliner::Core::Baseline->baselines();
    @bl_list = grep { $_->{bl} ne '*' } @bl_list if $p->{no_common};
    $c->stash->{json} = { totalCount=>scalar(@bl_list), data=> \@bl_list };
    $c->forward('View::JSON');
}
########################################################################################################################
#FIN DE METODOS ANTERIORES
########################################################################################################################

sub grid : Local {
    my ($self,$c)=@_;
    $c->stash->{template} = '/comp/baseline_grid.js';
}

sub list : Local {
    my ($self,$c)=@_;
    my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = ( @{$p}{qw/start limit query dir sort/}, 0 );
    $start ||= 0;
    $limit ||= 100;
    $sort ||= 'seq';
    $dir ||= 'asc';
    
    my $page = to_pages( start=>$start, limit=>$limit );
    my @rows;
    my $where = $query
    ? { 'lower(bl||name||description)' => { -like => "%".lc($query)."%" } }
    : undef;
    
    my $rs = $c->model('Baseliner::BaliBaseline')->search(  $where,
                            { page => $page,
                              rows => $limit,
                              order_by => $sort ? "$sort $dir" : undef
                            }
                        );
    
    my $pager = $rs->pager;
    $cnt = $pager->total_entries;
    while( my $r = $rs->next ) {
        push @rows,
          {
            id          => $r->id,
            bl 		    => $r->bl,
            name	    => _loc($r->name),
            description	=> _loc($r->description),
          };
    }        
        
    $c->stash->{json} = { totalCount=>$cnt, data=>\@rows };
    $c->forward('View::JSON');    
}

sub update : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $action = $p->{action};

    given ($action) {
        when ('add') {
            try{
                my $seq;
                my $row;
                $row = $c->model('Baseliner::BaliBaseline')->search({},{ order_by=>'seq desc'})->first;
                
                if(ref $row){
                    $seq = $row -> seq + 1;
                }else{
                    $seq = 1
                }                
                $row = $c->model('Baseliner::BaliBaseline')->search(bl => $p->{bl})->first;
                if(!$row){
                    my $baseline;
                    master_new 'bl' => $p->{bl} => sub { 
                        my $mid = shift;
                        $baseline = $c->model('Baseliner::BaliBaseline')->create(
                                        {
                                            bl    => $p->{bl},
                                            mid   => $mid, 
                                            name  => $p->{name},
                                            description=> $p->{description},
                                            seq => $seq
                                        });
                    }; 
                    update_sequence($p->{sq});
                    
                    $c->stash->{json} = { msg=>_loc('Baseline added'), success=>\1, baseline_id=> $baseline->id };
                    
                    
                    
                }else{
                    $c->stash->{json} = { msg=>_loc('Baseline key already exists, introduce another baseline key'), failure=>\1 };
                }
            }
            catch{
                $c->stash->{json} = { msg=>_loc('Error adding Baseline: %1', shift()), failure=>\1 }
            }
        }
        when ('update') {
            try{
                my $id_baseline = $p->{id};
                my $baseline = $c->model('Baseliner::BaliBaseline')->find( $id_baseline );
                $baseline->bl( $p->{bl} );
                $baseline->name( $p->{name} );
                $baseline->description( $p->{description} );
                $baseline->update();
                update_sequence($p->{sq});
                $c->stash->{json} = { msg=>_loc('Baseline modified'), success=>\1, baseline_id=> $id_baseline };
            }
            catch{
                $c->stash->{json} = { msg=>_loc('Error modifying Baseline: %1', shift()), failure=>\1 };
            }
        }
        when ('delete') {
            my $id_baseline = $p->{id};
            
            try{
                my $row = $c->model('Baseliner::BaliBaseline')->find( $id_baseline );
                $row->delete;
                
                $c->stash->{json} = { success => \1, msg=>_loc('Baseline deleted') };
            }
            catch{
                $c->stash->{json} = { success => \0, msg=>_loc('Error deleting Baseline') };
            }
        }
    }
    
    $c->forward('View::JSON');    
}

sub update_sequence{
    my ( $self, $c ) = @_;
    my $sequence_services = shift;
    my $seq = 1;
    
    foreach my $sequence_service (_array $sequence_services){
    my $service = Baseliner->model('Baseliner::BaliBaseline')->find( $sequence_service );
    if( ref $service ) {
        $service->seq( $seq );
        $service->update;
    }
    $seq ++
    }
}

1;


