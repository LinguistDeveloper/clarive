package Baseliner::Controller::Search;
use Baseliner::PlugMouse;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use 5.010;

BEGIN {  extends 'Catalyst::Controller' }

register 'config.search' => {
    metadata => [
        { id=>'block_lucy', text=>'Block the use of Lucy in searches', default=>1 },
        { id=>'provider_filter', text=>'Regex to filter provider packages', default=>'' },
        { id=>'lucy_boolop', text=>'AND or OR default', default=>'OR' },
        { id=>'max_results', text=>'Number of results to return to user', default=>10_000 },
        { id=>'max_results_provider', text=>'Limit sent to provider', default=>10_000 },
        { id=>'max_excerpt_size', text=>'Max length of excerpt string', default=>120 },
        { id=>'max_excerpt_tokens', text=>'Max number of highlighted tokens excerpts', default=>5 },
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
        : $c->forward('/search/query_raw');
    my $inter = sprintf( "%.02f", Time::HiRes::tv_interval( $t0 ) );
    $c->stash->{json}->{elapsed} = $inter;
    $c->forward('View::JSON');
};

sub query_raw : Local {
    my ( $self, $c ) = @_;
    my $p        = $c->request->parameters;
    my $config   = $c->stash->{search_config};
    my $provider = $p->{provider} or _throw _loc('Missing provider');
    my $query    = $p->{query} // _throw _loc('Missing query');
    my @results  = $provider->search_query( username=>$c->username, query=>$query, language=>$c->languages->[0], limit=>$config->{max_results_provider} ); 
     
    $c->stash->{json} = {
        results  => $self->order_matches($query,$config,@results),
        type     => $provider->search_provider_type,
        name     => $provider->search_provider_name,
        provider => $provider
    };
} 

sub clean_match {
    my $self = shift;
    #$_[0] =~ s/^\B+\b(.*)$/X=$1=/; 
    #$_[0] =~ s/^(.*)\s+\S+$/$1/g; 
    $_[0] =~ s/^\S+\s+(.*)$/$1/g; 
}

sub order_matches {
    my ($self,$query,$config,@results) = @_;
    my $docs = [];
    my $max_excerpt_size = $config->{max_excerpt_size} // 120;
    my $max_excerpt_tokens = $config->{max_excerpt_tokens} // 5;
    for my $doc ( @results ) {
        my @found;
        my $idexact  = $$doc{mid} eq $query;
        my $idmatch  = length join '',( "$$doc{mid}" =~ /($query)/gsi );
        my $tmatch  = length join '', ( "$$doc{title}" =~ /($query)/gsi );
        for my $doc_txt ( $$doc{info}, $$doc{text} ) {
            my $kfrag = 0;
            while ( $doc_txt =~ /(?<bef>.{0,20})?(?<mat>$query)(?<aft>.{0,20})?/gsi ) {
                my $t = '';
                if( $kfrag <= $max_excerpt_tokens ) {   # otherwise excerpt too long
                    my ( $bef, $mat, $aft ) = ( $+{bef}, $+{mat}, $+{aft} );
                    $self->clean_match($bef);
                    $t = sprintf '%s<strong>%s</strong>%s', $bef, $mat, $aft;
                }
                push @found, $t;
                $kfrag++;
            }
        }
        $$doc{excerpt} = !@found ? '' : join( "...", grep { length } @found ) . '...';
        $$doc{text} = substr $$doc{text},0,$max_excerpt_size; # if no excerpt, search_results.js uses text, so we better trim
        $$doc{matches} = $idexact*1000000 + ($idmatch>0?(10**(1/$idmatch)*10000):0) + ($tmatch>0?(10**(1/$tmatch)*1000):0) + scalar @found;
        $$doc{title} = "$$doc{title}";
        push $docs, $doc;  # we don't filter results
    }
    #my $res = { results => , query => $query, matches => @$docs };
    [ sort { 
        $$a{matches} == $$b{matches} ? $$a{mid} <=> $$b{mid} : $$b{matches} <=> $$a{matches} 
        } @$docs ];
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
    require LucyX::Simple::Result::Hash;

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

    #push @results, @results for 1..8;
    my $id=0;
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

    $c->stash->{json} = {
        results  => $results,
        type     => $provider->search_provider_type,
        name     => $provider->search_provider_name,
        provider => $provider
    };
}

1;

