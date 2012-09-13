package Baseliner::Model::Rules;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use v5.10;

register 'statement.if.var' => {
    text => 'IF var THEN',
    type => 'if',
    data => { variable=>'', value=>'' },
    dsl => sub { 
        my ($self, $n ) = @_;
        sprintf(q{
            if( $stash->{'%s'} eq '%s' ) {
                %s
            }
            
        }, $n->{variable}, $n->{value} , $self->dsl_build( $n->{children} ) );
    },
};

register 'statement.foreach' => {
    text => 'FOREACH stash[ variable ]', type => 'for', data => { variable=>'' },
    dsl => sub { 
        my ($self, $n ) = @_;
        sprintf(q{
            foreach my $item ( _array( $stash->{'%s'} ) ) {
                %s
            }
            
        }, $n->{variable}, $self->dsl_build( $n->{children} ) );
    },
};

sub build_tree {
    my ($self, $id_rule, $parent) = @_;
    my @tree;
    # TODO run query just once and work with a hash ->hash_for( id_parent )
    my @rows = DB->BaliRuleStatement->search( { id_rule => $id_rule, id_parent => $parent },
        { order_by=>{ -asc=>'id' } } )->hashref->all;
    for my $row ( @rows ) {
        my $n = { text=>$row->{stmt_text} };
        $row->{stmt_attr} = _load( $row->{stmt_attr} );
        $n = { %$n, %{ $row->{stmt_attr} } } if length $row->{stmt_attr};
        my @chi = $self->build_tree( $id_rule, $row->{id} );
        if(  @chi ) {
            $n->{children} = \@chi;
            $n->{leaf} = \0;
            $n->{expanded} = \1;
        } elsif( ! ${$n->{leaf} // \1} ) {  # may be a folder with no children
            $n->{children} = []; 
            $n->{expanded} = \1;
        }
        delete $n->{loader};  
        delete $n->{isTarget};  # otherwise you cannot drag-drop around a node
        _log $n;
        push @tree, $n;
    }
    return @tree;
}

sub dsl_build {
    my ($self,$stmts)=@_;
    _debug $stmts;
    my @dsl = (
        #'my $stash = {};',
        #'my $ret;',
    );
    require Data::Dumper;
    require Perl::Tidy;
    my $spaces = sub { '   ' x $_[0] };
    my $level = 0;
    local $Data::Dumper::Terse = 1;
    for my $s ( _array $stmts ) {
        #_debug( $s );
        my $children = $s->{children} || {};
        my $attr = $s->{attributes} || {};
        delete $attr->{loader} ; # node cruft
        delete $attr->{events} ; # node cruft
        _debug $attr;
        my $name = $attr->{text};
        push @dsl, sprintf '# statement: %s', $name; 
        my $key = $attr->{key};
        my $data = $attr->{data} || {};
        my $reg = Baseliner->registry->get( $attr->{key} );
        if( $reg->isa( 'BaselinerX::Type::Service' ) ) {
            push @dsl, $spaces->($level) . sprintf('$stash = merge_data($stash, %s );', Data::Dumper::Dumper( $data ) );
            push @dsl, $spaces->($level) . sprintf('$stash = launch( "%s", $stash );', $key );
            #push @dsl, $spaces->($level) . sprintf('merge_data($stash, $ret );', Data::Dumper::Dumper( $data ) );
        } else {
            push @dsl, _array( $reg->{dsl}->($self, { %$attr, %$data, children=>$children }) );
        }
    }
    #push @dsl, sprintf '$stash;';

    my $dsl = join "\n", @dsl;
    my $tidied = '';
    Perl::Tidy::perltidy( argv => '-npro', source => \$dsl, destination => \$tidied );
    return $tidied;
}

sub dsl_run {
    my ($self, %p ) = @_;
    my $dsl = $p{dsl};
    local $@;
    sub merge_data {
        my $d = { %{ $_[0] || {} }, %{ $_[1] || {} } };
        parse_vars( $d, $d );
    }
    sub launch {  # launch always returns a hash
        my ($key,$data)=@_;
        _debug "LAUNCH KEY = $key";
        #my $ret = Baseliner->launch( $key, data=>$data );  # comes with a dummy job
        my $ret = Baseliner->registry->get( $key )->run( Baseliner->app, $data ); 
        _debug $ret;
        my $return_data = $ret->data // {};
        $return_data = ref $return_data eq 'HASH' ? $return_data : {} ;
        return merge_data( $data, $return_data );
    }
    my $ret;
    my $stash = $p{stash} // {};
    my $ret = eval $dsl;
    _fail "Error during DSL Execution: $@" if $@;
    return $stash;
}

1;
