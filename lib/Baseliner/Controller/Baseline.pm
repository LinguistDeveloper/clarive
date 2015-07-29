package Baseliner::Controller::Baseline;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Try::Tiny;
BEGIN {  extends 'Catalyst::Controller' }

use Baseliner::Utils;
use Baseliner::Sugar;
use Baseliner::Core::Baseline;
use v5.10;

#register 'menu.admin.core.bl' => { label => _loc('List all Baselines'), url=>'/core/baselines', title=>_loc('Baselines')  };

#register 'action.admin.baseline' => { name => 'Administer baselines'};

# register 'menu.admin.baseline' => { label => _loc('Baselines'),
#     url_comp=>'/baseline/grid', title=>_loc('Baselines'),
#     icon=> '/static/images/icons/baseline.gif',
#     action => 'action.admin.baseline',
# };


# used as a forward everywhere
sub load_baselines : Private {
    my ($self,$c)=@_;
    my @bl_arr = ();
    my @bl_list = Baseliner::Core::Baseline->baselines();
    return $c->stash->{baselines} = [ [ '*', 'Common' ] ] unless @bl_list > 0;
    foreach my $n ( @bl_list ) {
        my $arr = [ $n->{bl}, _loc($n->{name}) ];
        push @bl_arr, $arr;
    }
    $c->stash->{baselines} = \@bl_arr;
}

sub json : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $common = _loc('Common');
    my @bl_list =
    map {
        my $bl = $_->{bl} eq '*' ? $common : $_->{bl};
        +{  name        => $_->{name},
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

sub list : Local {
    my ($self,$c)=@_;
    my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort) = ( @{$p}{qw/start limit query dir sort/});
    $start ||= 0;
    $limit ||= 100;
    $sort ||= 'seq';
    $dir ||= 'asc';
    
    my $where = $query
    ? { 'lower(bl||name||description)' => { -like => "%".lc($query)."%" } }
    : undef;
    
    my @rows = map {
        my $r = $_;
          {
            id          => $r->mid,
            bl 		    => $r->bl,
            name	    => _loc($r->name),
            description	=> _loc($r->description),
          };
    } sort { $a->seq <=> $b->seq } ci->search_cis( collection=>'bl' );
    my $cnt = @rows;
        
    $c->stash->{json} = { totalCount=>$cnt, data=>\@rows };
    $c->forward('View::JSON');    
}

1;


