package Baseliner::Controller::Search;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;
use 5.010;

BEGIN {  extends 'Catalyst::Controller' }

sub providers : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my @provs = packages_that_do('Baseliner::Role::Search');
    $c->stash->{json} =
        { providers => [ map { {pkg => $_, type => $_->search_provider_type, name => $_->search_provider_name } } @provs ] };
    $c->forward('View::JSON');
}

sub query : Local {
    my ( $self, $c ) = @_;
    my $lucy_here = try {
        require 'LucyX::Simple';
        1;
    } catch {
        0
    };
    my $t0 = [ Time::HiRes::gettimeofday ]; 

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

sub query_lucy : Local {
    my ( $self, $c ) = @_;
    my $p        = $c->request->parameters;
    my $provider = $p->{provider} or _throw _loc('Missing provider');
    my $query    = $p->{query} // _throw _loc('Missing query');
    my $lang = $c->languages->[0] || 'en';

    my $dir = '/tmp/search_index_' . _md5( join ',', $c->username , $$ , time );
    my $searcher = LucyX::Simple->new(
        index_path => $dir,
        language   => $lang, 
        resultclass => 'LucyX::Simple::Result::Hash',
        schema     => [
            { 'name' => 'title', 'boost' => 3, },
            { name => 'text' },
            { name  => 'url' },
            { name  => 'type' },
            { name => 'id', type => 'string', },
        ],
        'search_fields' => ['title', 'text'],
        'search_boolop' => 'OR',
    );
     
    my @provs = packages_that_do('Baseliner::Role::Search');

    # create Lucy docs
    my @results  = $provider->search_query( query => $query, c => $c );
    my $id=0;
    #_debug( \@results );
    map { 
        my $r = $_;
        $r->{id} //= $r->{mid} // $id++;
        $r->{text} = _utf8( $r->{text} );
        $searcher->create($r);
    } @results;

    $searcher->commit;

    my ( $results, $pager ) = try {
        $searcher->search( $query );
    } catch {
        _debug shift();
        ();
    };
    _dir( $dir )->rmtree; 

    $c->stash->{json} = {
        results  => $results,
        type     => $provider->search_provider_type,
        name     => $provider->search_provider_name,
        provider => $provider
    };
}

1;
