package Baseliner::Model::Rules;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use v5.10;

with 'Baseliner::Role::Service';

has tidy_up => qw(is rw isa Bool default 1);

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

register 'statement.try' => {
    text => 'TRY statement', 
    type => 'if',
    data => { },
    dsl => sub { 
        my ($self, $n ) = @_;
        sprintf(q{
            try {
                %s
            };
            
        }, $self->dsl_build( $n->{children} ) );
    },
};

register 'statement.let.key_value' => {
    text => 'LET key => value', 
    type => 'let',
    holds_children => 0, 
    data => { key=>'', value=>'' },
    dsl => sub { 
        my ($self, $n ) = @_;
        sprintf(q{
           $stash->{ '%s' } = '%s';
        }, $n->{key}, $n->{value}, $self->dsl_build( $n->{children} ) );
    },
};

register 'statement.let.merge' => {
    text => 'MERGE value INTO stash', 
    type => 'let',
    holds_children => 0, 
    data => { value=>{} },
    dsl => sub { 
        my ($self, $n ) = @_;
        sprintf(q{
           $stash = merge_data( $stash, %s );
        }, Data::Dumper::Dumper($n->{value}), $self->dsl_build( $n->{children} ) );
    },
};

register 'statement.delete.key' => {
    text => 'DELETE hashkey', 
    type => 'if',
    holds_children => 0, 
    data => { key=>'' },
    dsl => sub { 
        my ($self, $n ) = @_;
        sprintf(q{
           delete $stash->{ '%s' } ;
        }, $n->{key}, $self->dsl_build( $n->{children} ) );
    },
};

register 'statement.foreach' => {
    text => 'FOREACH stash[ variable ]', type => 'for', data => { variable=>'' },
    type => 'loop',
    dsl => sub { 
        my ($self, $n ) = @_;
        sprintf(q{
            foreach my $item ( _array( $stash->{'%s'} ) ) {
                %s
            }
            
        }, $n->{variable}, $self->dsl_build( $n->{children} ) );
    },
};

register 'service.echo' => {
    data => { msg => '', args=>{}, arr=>[] },
    handler=>sub{
        my ($self, $c, $data ) = @_;
        $data->{hello} = $data->{msg} || 'world';
        _log _loc "Loggin echo: %1", $data->{hello};
        $data;
    }
};

register 'service.fail' => {
    data => { msg => 'dummy fail' },
    handler=>sub{
        my ($self, $c, $data ) = @_;
        Baseliner::Utils::_fail( $data->{msg} || 'dummy fail' );
    }
};

register 'event.rule.tester' => {
    text => '%1 posted a comment on %2: %3',
    description => 'Dummy Event to Test a Rule',
    vars => ['hello'],
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
        #_log $n;
        push @tree, $n;
    }
    return @tree;
}

sub dsl_build {
    my ($self,$stmts )=@_;
    #_debug $stmts;
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
        my $attr = defined $s->{attributes} ? $s->{attributes} : $s;  # attributes is for a json treepanel
        delete $attr->{loader} ; # node cruft
        delete $attr->{events} ; # node cruft
        #_debug $attr;
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
    
    
    ##Al hacer referencia a "$self->tidy_up" da un error del tipo:
    ##Can't use string ("Baseliner::Model::Rules") as a HASH ref while "strict refs" in use at accessor Baseliner::Model::Rules::tidy_up
    ##REVISAR
    #if( $self->tidy_up ) {
        my $tidied = '';
        Perl::Tidy::perltidy( argv => ' ', source => \$dsl, destination => \$tidied );
        return $tidied;
    #} else {
    #    return $dsl;
    #}
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
        #_debug $ret;
        my $return_data = $ret->data // {};
        $return_data = ref $return_data eq 'HASH' ? $return_data : {} ;
        return merge_data( $data, $return_data );
    }
    my $ret;
    my $stash = $p{stash} // {};
    $ret = eval $dsl;
    _fail( _loc("Error during DSL Execution: %1", $@) ) if $@;
    return $stash;
}

sub run_rules {
    my ($self, %p) = @_;
    my @rules = DB->BaliRule->search(
        { rule_event => $p{event}, rule_type => 'event',      rule_when => $p{when} },
        { order_by   => [          { -asc    => 'rule_seq' }, { -asc    => 'id' } ] }
    )->hashref->all;
    my $stash = $p{stash};
    my @rule_log;
    for my $rule ( @rules ) {
        my ($runner_output, $rc, $dsl, $ret);
        try {
            my @tree = $self->build_tree( $rule->{id}, undef );
            $dsl = try {
                $self->dsl_build( \@tree ); 
            } catch {
                _fail( _loc("Error building DSL for rule '%1' (%2): %3", $rule->{rule_name}, $rule->{rule_when}, shift() ) ); 
            };
            $ret = try {
                ################### RUN THE RULE DSL ######################
                IO::CaptureOutput::capture( sub {
                    $self->dsl_run( dsl=>$dsl, stash=>$stash );
                }, \$runner_output, \$runner_output );
            } catch {
                _fail( _loc("Error running rule '%1' (%2): %3", $rule->{rule_name}, $rule->{rule_when}, shift() ) ); 
            };
        } catch {
            my $err = shift;
            $rc = 1;
            if( ref $p{onerror} eq 'CODE') {
                $p{onerror}->( { err=>$err, ret=>$ret, id=>$rule->{id}, dsl=>$dsl, stash=>$stash, output=>$runner_output, rc=>$rc } );
            } elsif( ! $p{onerror} ) {
                _fail $err;
            }
        };
        push @rule_log, { ret=>$ret, id => $rule->{id}, dsl=>$dsl, stash=>$stash, output=>$runner_output, rc=>$rc };
    }
    return { stash=>$stash, rule_log=>\@rule_log }; 
}
1;
