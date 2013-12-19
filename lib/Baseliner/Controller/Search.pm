package Baseliner::Controller::Search;
use Baseliner::PlugMouse;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use 5.010;

BEGIN {  extends 'Catalyst::Controller' }

register 'config.search' => {
    metadata => [
        { id=>'block_lucy', text=>'Block the use of Lucy in searches', default=>0 },
        { id=>'provider_filter', text=>'Regex to filter provider packages', default=>'' },
        { id=>'lucy_boolop', text=>'AND or OR default', default=>'OR' },
        { id=>'max_results', text=>'Number of results to return to user', default=>10_000 },
        { id=>'max_results_provider', text=>'Limit sent to provider', default=>10_000 },
    ]
};

sub providers : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my @provs = packages_that_do('Baseliner::Role::Search');
#    my $config = config_get 'config.search';
#    if( my $filter = $config->{provider_filter} ) {
#        _debug "PROV FILTER=$filter";
        @provs = grep { $_->user_can_search($c->username) } @provs;
#    }
    $c->stash->{json} =
        { providers => [ map { {pkg => $_, type => $_->search_provider_type, name => $_->search_provider_name } } @provs ] };
    $c->forward('View::JSON');
}

sub query : Local {
    my ( $self, $c ) = @_;
    my $config = config_get 'config.search';
    my $lucy_here = !$config->{block_lucy} && try {
        require Baseliner::Lucy; # fails if no Lucy installed
        1;
    } catch {
        0
    };
    my $t0 = [ Time::HiRes::gettimeofday ]; 

    $c->stash->{search_config} = $config;

    $lucy_here 
        ? $c->forward('/search/query_lucy')
        : $c->forward('/search/query_sql');
    my $inter = sprintf( "%.02f", Time::HiRes::tv_interval( $t0 ) );
    $c->stash->{json}->{elapsed} = $inter;
    $c->forward('View::JSON');
};

sub query_sql : Local {
    my ( $self, $c ) = @_;
    my $p        = $c->request->parameters;
    my $provider = $p->{provider} or _throw _loc('Missing provider');
    my $query    = $p->{query} // _throw _loc('Missing query');
    my @results  = $provider->search_query( query => $query, c => $c );
    $c->stash->{json} = {
        results  => \@results,
        type     => $provider->search_provider_type,
        name     => $provider->search_provider_name,
        provider => $provider
    };
} 

=head2 query_lucy

Normally, this runs once for each provider. Gets called 
many times for a search.

Parameters:

    provider : where to search 
    tokenizer_pattern : how to break down words

=cut
sub query_lucy : Local {
    my ( $self, $c ) = @_;
    my $p        = $c->request->parameters;
    my $config   = $c->stash->{search_config};
    my $provider = $p->{provider} or _throw _loc('Missing provider');
    my $query    = delete $p->{query} // _throw _loc('Missing query');
    my $lang = $c->languages->[0] || 'en';

    #my $dir = _dir _tmp_dir(), 'search_index_' . _md5( join ',', $c->username , $$ , time );
    my $case_folder = Lucy::Analysis::CaseFolder->new;
    my $string_tokenizer = Lucy::Analysis::RegexTokenizer->new( pattern => $p->{tokenizer_pattern} // '\w');
    my $analyzer = Lucy::Analysis::PolyAnalyzer->new( analyzers => [$case_folder, $string_tokenizer]);
    my $searcher = Baseliner::Lucy->new(
        index_path => Lucy::Store::RAMFolder->new, # in-memory files "$dir",
        language   => $lang || $c->config->{default_lang} || 'en', 
        analyser   => $analyzer, 
        resultclass => 'LucyX::Simple::Result::Hash',
        entries_per_page => $config->{max_results},
        schema     => [
            { name  => 'title', 'boost' => 3, type=>'fulltext', highlightable=>1 },
            { name  => 'text', highlightable=>1, type=>'fulltext' },
            { name  => 'info', highlightable=>1, type=>'fulltext', boost=>1 },
            { name  => 'type' },
            { name  => 'mid', type=>'string', boost=>4 },
            { name  => 'id', type => 'string', },
        ],
        highlighter => 'Baseliner::Lucy::Highlighter',
        search_fields => ['title', 'text', 'mid','info'],
        search_boolop => $config->{lucy_boolop} // 'OR',
    );
     
    # create Lucy docs
    my @results  = $provider->search_query( username=>$c->username, query=>$query, language=>$c->languages->[0], limit=>$config->{max_results_provider} ); # query => $query don't send a query, its faster
    _debug \@results;

    #push @results, @results for 1..8;
    my $id=0;
    #_debug( \@results );
    my %extra_data; # for things that don't need to go into the index
    map { 
        my $r = $_;
        $r->{id} //= $r->{mid} // $r->{type} . '_' . $id++;
        $extra_data{ $r->{id} }{url} = delete $r->{url};
        $searcher->create($r);
    } @results;

    $searcher->commit;

    my ( $results, $pager ) = try {
        ( $searcher->search( $query ) );
    } catch {
        _debug shift(); # usually a "no results" exception
        ([],undef);
    };
    #$dir->rmtree; 

    # post procesing of results
    for( _array( $results ) ) {
        $_->{url} = $extra_data{ $_->{id} }{url};
        #$_->{excerpt} .= '[' . join ',',unpack('H*', $_->{excerpt} ) . ']';
    }
    _debug( $results );

    $c->stash->{json} = {
        results  => $results,
        type     => $provider->search_provider_type,
        name     => $provider->search_provider_name,
        provider => $provider
    };
}

1;
