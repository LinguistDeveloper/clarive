package Baseliner::Controller::REPL;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sugar;
use JSON::XS;
#use IO::CaptureOutput;
use Time::HiRes qw(gettimeofday tv_interval);
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller' }
use experimental 'autoderef';

register 'action.development.repl' => {name => 'Baseliner REPL'};
register 'action.development.js_reload', => { name => 'JS Reload'};
register 'action.development.cache_clear', => { name => 'Wipe Cache'};
register 'action.development.ext_api' => { name => 'ExtJS API Reference'};
register 'action.development.ext_examples' => { name => 'ExtJS Examples'};
register 'action.development.gui_designer', => { name => 'GUI Designer'};
register 'action.development.baliref', => { name => 'Baseliner Reference'};
# Action sequences
register 'action.development.sequences', => { name => 'Sequences'};


register 'menu.development' => {
    label => 'Development', 
    action => 'action.development.%', 
    index => 30
};
register 'menu.development.repl' => {
    label    => 'REPL',
    url_comp => '/repl/main',
    title    => 'REPL',
    action   => 'action.development.repl',
    icon     => '/static/images/icons/console.png',
    index    => 10,
};
register 'menu.development.js_reload' => {
    label    => 'JS Reload',
    url_eval => '/site/js-reload.js',
    title    => 'JS Reload',
    icon     => '/static/images/icons/js-reload.png',
    action   => 'action.development.js_reload',
    index      => 20,
};

register 'menu.development.cache_clear' => {
    label    => 'Wipe Cache',
    url_run  => '/cache_clear',
    title    => 'Wipe Cache',
    action   => 'action.development.cache_clear',
    icon     => '/static/images/icons/wipe_cache.png',
    index      => 30,
};

register 'menu.development.ext_api' => {
    label      => 'ExtJS API',
    url_iframe => '/static/ext/docs/index.html',
    title      => 'ExtJS API',
    action     => 'action.development.ext_api',
    icon     => '/static/images/icons/extjs.png',
    index      => 1000,
};
register 'menu.development.ext_examples' => {
    label      => 'ExtJS Examples',
    url_iframe => '/static/ext/examples/index.html',
    title      => 'ExtJS Examples',
    action     => 'action.development.ext_examples',
    icon     => '/static/images/icons/extjs_examples.png',
    index      => 1000,
};
# register 'menu.development.gui_designer' => {
#     label      => 'GUI Designer',
#     url_iframe => '/static/gui/index.html',
#     title      => 'GUI Designer',
#     action     => 'action.development.gui_designer',
#     index      => 1000,
# };
# register 'menu.development.baliref' => {
#     label              => 'Baseliner Reference',
#     url_browser_window => '/pod',
#     title              => 'Baseliner Reference',
#     index              => 999,
#     action => 'action.development.baliref',
#     index      => 100,
# };

##########################################################################
register 'menu.development.sequences' =>{
    label    => 'Sequences',
    # Ruta del controlador
    url_comp => '/repl/sequences',
    title    => 'Sequences',
    action   => 'action.development.sequences',
    icon     => '/static/images/icons/sequence.png',
    #index    => 10, 
};


sub sequence_store : Local {
    my ($self,$c)=@_;
    $c->stash->{json} = try {
        my @rows = mdb->master_seq->find->all;
        { success=>\1, data=>\@rows, totalCount=>scalar(@rows) };
    } catch {
        my $err = shift;
        { success=>\0, msg=>_loc('Error getting sequences: %1', $err) };
    };
    $c->forward( 'View::JSON' );
}

sub sequences : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = '/comp/sequences.js';
}

sub sequences_update : Local {
    my ($self,$c)=@_;
    my $p = $c->request->parameters;
    $c->stash->{json} = try {
        my $modified_records = _load $p->{modified_records};
        foreach my $updated_seq (keys $modified_records)
        {
            my $new_value = $modified_records->{$updated_seq}[0];
            my $actual_value = mdb->master_seq->find( { _id => $updated_seq } )->next->{seq};
            my $old_value = $modified_records->{$updated_seq}[1];
            if ($old_value != $actual_value ){
                die _loc('Error sync updating sequences');
            }
            my $ret = mdb->master_seq->update({ _id => $updated_seq, seq => $old_value }, { '$set' => { seq => $new_value } });
        }
        { success=>\1, msg=>_loc('Modified rows updated successfully') };
    } catch {
        my $err = shift;
        { success=>\0, msg=>_loc('Error updating sequences: %1', $err) };
    };
    $c->forward( 'View::JSON' );
 }

sub sequence_test : Local {
    my ( $self, $c )=@_;
    my $option = $c->request->parameters->{option};
    if ( $option == 0 ) {
        mdb->master_seq->remove({ _id => 'id1' });
        mdb->master_seq->remove({ _id => 'id2' });
        mdb->master_seq->insert({ _id => 'id1', seq => 1 });
        mdb->master_seq->insert({ _id => 'id2', seq => 1 });
        $c->stash->{json} = { success=>\1, msg=>_loc('Sequences added successfully') };
    }
    if ( $option == 1 ) {
        mdb->master_seq->update({ _id => "id1" }, { '$set' => { seq => 2 } });
        $c->stash->{json} = { success=>\1, msg=>_loc('Simulation of modification of sequence by other user') };
    }
    if ( $option == 2 ){
        my $seq_id = $c->request->parameters->{seq_id};
        my $seq = mdb->master_seq->find({ _id => $seq_id })->next->{seq}; 
        $c->stash->{json} = { success=>\1, msg=>_loc('Get seq value of ' . $seq_id), seq => $seq };
    }
    if ( $option == -1 ) {
        mdb->master_seq->remove({ _id => 'id1' });
        mdb->master_seq->remove({ _id => 'id2' });
        $c->stash->{json} = { success=>\1, msg=>_loc('Initial state establishet') };
    }
    $c->forward( 'View::JSON' );
}
##########################################################################



sub test : Local {
    my ( $self, $c ) = @_;
    $c->response->body( "hola" );
}

sub main : Local {
    my ( $self, $c ) = @_;
    model->Permissions->user_has_action( username=>$c->username, action=>'action.development.repl', fail=>1 );
    $c->stash->{template} = '/comp/repl.js';
}

sub eval : Local {
    my ( $self, $c ) = @_;
    my $p    = $c->req->parameters;
    my $code = $p->{code};
    my $eval = $p->{eval};
    my $dump = $p->{dump} || 'yaml';
    my $sql  = $p->{sql};

    # save history
    $self->push_to_history( $c->session, $code, $p->{lang} );

    my ( $res, $err );
    my ( $stdout, $stderr );

    require Capture::Tiny;
    local $ENV{BASELINER_LOGCOLOR} = 0;
    my $t0; # = [ gettimeofday ];
    my $elapsed; # = tv_interval( $t0 );
    _log "================================ REPL START ==========================\n";
    ($stdout, $stderr) = Capture::Tiny::tee(
        sub {
            if ( $sql ) {
                $t0=[gettimeofday];
                eval { $res = $self->sql( $sql, $code ); };
                $elapsed = tv_interval( $t0 );
            } else {
                $code = "use v5.10;\$t0=[gettimeofday];$code";
                $res  = [ eval $code ];
                $elapsed = tv_interval( $t0 );
                $res  = $res->[ 0 ] if @$res <= 1;
            }

            #my @arr  = eval $code;
            #$res = @arr > 1 ? \@arr : $arr[0];
            $err = $@;
        }
    );
    _log "================================ REPL END ============================\n";
    
    $res = _to_utf8( _dump( $res ) ) if $dump eq 'yaml';
    $res = _to_utf8( JSON::XS->new->pretty->encode( _damn( $res ) ) )
        if $dump eq 'json' && ref $res && !blessed $res;
    my ( $line ) = ( $err . $stderr . $stdout ) =~ /line ([0-9]+)/;

    $c->stash->{json} = {
        stdout  => $stdout,
        stderr  => $stderr,
        elapsed => sprintf('%.08f', $elapsed),
        result  => "$res",
        error   => "$err",
        line    => $line,
        success => \( $err ? 0 : 1 ),
    };
    $c->forward( 'View::JSON' );
} ## end sub eval :

sub sql {
    my ( $self, $sql_out, $code ) = @_;
    my $model = 'Baseliner';
    my @conn = $code=~/^(.+?),(.*?),(.*?)\n(.*)$/s;
    _fail _loc 'Missing first line DBI connect string. Ex: DBI:mysql:database=<db>;host=<hostname>;port=<port>,my-username,my-password'
        unless @conn > 1;
        
    $code = pop @conn;
    my @sts = $self->sql_normalize( $code );
    my $dbs = Util->_dbis( \@conn );

    if ( $code !~ m/^[\s\W]*select/si ) {    # run script
        my @rets;
        for my $st ( split /\;/, $code ) {
            $st =~ s{^\s+}{}g;
            $st =~ s{\s+$}{}g;
            next unless $st;
            next if $st =~ /^--/;
            my $cnt = $dbs->dbh->do( $st );
            push @rets,
                {
                Rows            => $cnt,
                'Error Code'    => $dbs->dbh->err,
                'Error Message' => $dbs->dbh->errstr,
                Statement       => $st
                };
        } ## end for my $st ( split /\;/...)
        return \@rets;
    } elsif ( $sql_out eq 'hash' ) {    # select returning hash on first col
        my %results;
        for my $st ( @sts ) {
            for my $row ( $dbs->arrays( $st ) ) {
                next unless ref $row eq 'ARRAY';
                my $first = pop @$row;
                $first // next;
                $results{$first} = $row;
            }
        }
        return \%results;
    } else {                            # select returning array ref
        my @results;
        for my $st ( @sts ) {
            next unless $st;
            push @results, $dbs->hashes( $st );
        }
        return \@results;
    } ## end else [ if ( $code !~ m/^[\s\W]*select/si)]
} ## end sub sql

sub sql_normalize {
    my ( $self, $sql ) = @_;
    my @sts;
    my $st;
    for ( split /\n|\r/, $sql ) {
        next if /^\s*--/;    # comments
        if ( /^(.+);\s*$/ ) {
            $st .= $1;
            push @sts, $st;
            $st = '';
        } else {
            $st .= $_;
        }
    } ## end for ( split /\n|\r/, $sql)
    push @sts, $st if $st;
    return @sts;
} ## end sub sql_normalize

sub save : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->parameters;
    $p->{text} //= $p->{id};
    my $doc = mdb->repl->find_one({ _id=>$p->{id} });
    if ( $doc ) {
        mdb->repl->save({ %$doc, %$p });
    } else {
        $p->{_id} //= $p->{id};
        mdb->repl->insert($p);
    }
} 

sub load : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->parameters;
    my $doc = mdb->repl->find_one({ _id=>$p->{id} });
    _fail _loc 'REPL entry not found: %1', $p->{id} unless $doc;
    $c->stash->{json} = $doc;
    $c->forward( 'View::JSON' );
} 

sub delete : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->parameters;
    my $id = $p->{_id} || $p->{id} || $p->{ns};
    if ( $id ) {
        mdb->repl->remove({ _id=>$p->{id} });
    } else {
        _fail _loc 'Missing REPL id';
    }
} 

sub tree_saved : Local {
    my ( $self, $c ) = @_;
    my $p     = $c->req->parameters;
    my $query = $p->{query};
    my @docs  = mdb->repl->find->all;
    my $k     = 0;
    $c->stash->{json} = [
        grep { $query ? $_->{text} =~ /$query/i : 1 }
        sort { lc $a->{text} cmp lc $b->{text} }
        map {
            my $id = "$_->{_id}";
            { _id=>$id, text =>$_->{text},leaf => \1, url_click => '/repl/load', data=>{ _id=>$id, id=>$id } };
        } @docs
    ];
    $c->forward( 'View::JSON' );
} 

sub tree_hist : Local {
    my ( $self, $c ) = @_;
    my $p     = $c->req->parameters;
    my $query = $p->{query};
    my $i     = 0;
    $c->session->{repl_hist} = {} unless ref $c->session->{repl_hist} eq 'HASH';
    $c->stash->{json} = [
        map {
            my $code = $_->{code};
            $code =~ s/\n|\r//g;
            $code = substr( $code, 0, 30 );
            +{
                text      => sprintf( '%s (%s): %s', $_->{text}, $_->{lang}, $code ),
                leaf      => \1,
                url_click => '/repl/load_hist',
                data => {text => $_->{text}}
                }
            }
            sort {
            $b->{text} cmp $a->{text}
            }    # by date DESC
            grep { $query ? $_->{code} =~ /$query/i : 1 }
            grep { ref eq 'HASH' } values %{$c->session->{repl_hist}}
    ];
    $c->forward( 'View::JSON' );
} ## end sub tree_hist :

sub load_hist : Local {
    my ( $self, $c ) = @_;
    my $p    = $c->req->parameters;
    my $text = $p->{text};
    my $h    = $c->session->{repl_hist}->{$text};
    $c->stash->{json} =
        ref $h
        ? {code => $h->{code}, output => $h->{output}, lang => $h->{lang}, output => $h->{output}}
        : {output => 'not found'};
    $c->forward( 'View::JSON' );
} ## end sub load_hist :

sub save_hist : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->parameters;
    $self->push_to_history( $c->session, $p->{code}, $p->{lang} );
    $c->stash->{json} = {};
    $c->forward( 'View::JSON' );
} ## end sub save_hist :

sub tree_class : Local {
    my ( $self, $c ) = @_;
    my $p       = $c->req->parameters;
    my $query   = $p->{query};
    my %cl      = Class::MOP::get_all_metaclasses;
    my @classes = keys %cl;
    if ( $p->{filter} ) {
        @classes = grep /$p->{filter}/, @classes;
    }
    $c->stash->{json} = [
        map {
            {
                text      => $_,
                leaf      => \0,
                url       => '/repl/class_meth',
                url_click => '/repl/class_pod',
                data      => {class => $_},
                iconCls   => 'icon-cmp'
            }
            }
            grep {
            length $query ? /$query/i : 1
            }
            sort @classes
    ];
    $c->forward( 'View::JSON' );
} ## end sub tree_class :

sub _file_for_class {
    my ( $self, $class ) = @_;
    ( my $file = $class ) =~ s/::/\//g;
    $file .= '.pm';
    $INC{$file} || _throw "Class file not found: $class";
} ## end sub _file_for_class

sub class_pod : Local {
    my ( $self, $c ) = @_;
    my $p    = $c->req->parameters;
    my $file = $self->_file_for_class( $p->{class} );

    #my $pod = (_file $file )->slurp;
    use Pod::Simple::HTML;
    my $psh = Pod::Simple::HTML->new;
    $psh->output_string( \my $pod );
    $psh->parse_file( $file );

    unless ( $pod ) {
        $pod = _file( $file )->slurp unless $pod;
        $pod = "<pre>$pod</pre>";
    }
    $c->stash->{json} = {div => $pod};
    $c->forward( 'View::JSON' );
} ## end sub class_pod :

sub meth_pod : Local {
    my ( $self, $c ) = @_;
    my $p    = $c->req->parameters;
    my $meth = $p->{meth};
    my $file = $self->_file_for_class( $p->{class} );
    my $pod  = ( _file $file )->slurp;
    my $output =
          $pod =~ m/(=head.\s+$meth(.*?)=cut)/sg
        ? $1
        : 'not found';
    $c->stash->{json} = {output => $output};
    $c->forward( 'View::JSON' );
} ## end sub meth_pod :

sub class_meth : Local {
    my ( $self, $c ) = @_;
    my $p     = $c->req->parameters;
    my $query = $p->{query};
    my $class = $p->{class};
    my @attrs = map {
        {
            text      => $_,
            leaf      => \1,
            url_click => '/repl/attr_pod',
            data      => {class => $class, attr => $_},
            iconCls   => 'icon-prop'
        }
        } grep {
        $query ? /$query/ : 1
        } sort $class->meta->get_attribute_list;
    my @meths = map {
        {
            text      => $_,
            leaf      => \1,
            url_click => '/repl/meth_pod',
            data      => {class => $class, meth => $_},
            iconCls   => 'icon-method'
        }
        } grep {
        $query ? /$query/ : 1
        } sort $class->meta->get_method_list;
    $c->stash->{json} = [ @attrs, @meths ];
    $c->forward( 'View::JSON' );
} ## end sub class_meth :

sub tree_main : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->parameters;
    $c->stash->{json} = [
        {text => 'History', url => '/repl/tree_hist', leaf => \0, expandable => \1, expanded => \0},
        {
            text       => 'Baseliner Classes',
            url        => '/repl/tree_class',
            leaf       => \0,
            expandable => \1,
            expanded   => \0,
            data       => {filter => '^Baseliner'}
        },
        {
            text       => 'Other Classes',
            url        => '/repl/tree_class',
            leaf       => \0,
            expandable => \1,
            expanded   => \0,
            data       => {filter => '^(?!Baseliner)'}
        },
        {text => 'Saved', url => '/repl/tree_saved', leaf => \0, expandable => \1, expanded => \0},
    ];
    $c->forward( 'View::JSON' );
} ## end sub tree_main :

sub save_to_file : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->parameters;
    my @docs = mdb->repl->find->all;
    try {
 
        for my $item ( @docs ) {
            my $name = $item->{id};
            $name =~ Util->name_to_id( $name );
            my $file   = Baseliner->path_to( 'etc', 'repl', "$name.t" );
            my $code   = $item->{code};
            my $output = $item->{output};
            $code   =~ s{\r}{}g;
            $output =~ s{\r}{}g;
            open my $out, '>', $file;
            print $out $code;
            print $out "\n__END__\n";
            print $out $output;
            print $out "\n";
            close $out;
        } ## end for ( @ns )
        $c->stash->{json} = {success => \1};
    } ## end try
    catch {
        $c->stash->{json} = {success => \0, msg => shift};
    };
    $c->forward( 'View::JSON' );
} 

sub tidy : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->parameters;
    try {
        require Perl::Tidy;
        my $code = $p->{code};
        my $tidied;
        Perl::Tidy::perltidy( argv => ' ', source => \$code, destination => \$tidied );
        $c->stash->{json} = {success => \1, code => $tidied};
    } ## end try
    catch {
        $c->stash->{json} = {success => \0, msg => shift};
    };
    $c->forward( 'View::JSON' );
} ## end sub tidy :

sub push_to_history {
    my ( $self, $session, $code, $lang, $output ) = @_;
    $session->{repl_hist} = {} unless ref $session->{repl_hist} eq 'HASH';
    my $hist = $session->{repl_hist};
    my $md5  = _md5( $code );           # don't store duplicate repetitions
    if ( !$session->{repl_md5} || $session->{repl_md5} ne $md5 ) {

        if ( ( keys %$hist ) > 20 ) {
            my $oldest = [ sort keys %$hist ]->[ 0 ];
            delete $hist->{$oldest} if $oldest;
        }
        my $key = _now();
        $hist->{$key} = {text => $key, code => $code, lang => $lang, output => $output};

        #$session->{repl_hist} = \@hist;
        $session->{repl_md5} = $md5;
    } ## end if ( !$session->{repl_md5...})
} ## end sub push_to_history

1;
