package Baseliner::Controller::REPL;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use JSON::XS;
use IO::CaptureOutput;
use Time::HiRes qw(gettimeofday tv_interval);
use Try::Tiny;

BEGIN {  extends 'Catalyst::Controller' }

register 'action.admin.develop' =>  { name=>'Baseliner Developer' };

register 'menu.development' => { label => 'Development', action=>'action.admin.develop' };
register 'menu.development.repl' => {
    label    => 'REPL',
    url_comp => '/repl/main',
    title    => 'REPL',
    action   => 'action.admin.develop',
    icon     => '/static/images/icons/console.png',
};
register 'menu.development.ext_api' =>
    { label => 'ExtJS API', url_iframe => '/static/ext/docs/index.html', title => 'ExtJS API', action => 'action.admin.develop' };
register 'menu.development.ext_examples' => {
    label      => 'ExtJS Examples',
    url_iframe => '/static/ext/examples/index.html',
    title      => 'ExtJS Examples',
    action     => 'action.admin.develop'
};
register 'menu.development.gui_designer' =>
    { label => 'GUI Designer', url_iframe => '/static/gui/index.html', title => 'GUI Designer', action => 'action.admin.develop' };
register 'menu.development.baliref' =>
    { label => 'Baseliner Reference', url_browser_window => '/pod', title => 'Baseliner Reference', index => 999 };

register 'menu.development.js_reload' => {
    label    => 'JS Reload',
    url_eval => '/site/js-reload.js',
    title    => 'JS Reload',
    action   => 'action.admin.develop',
    icon     => '/static/images/icons/js-reload.png',
};

sub test : Local {
    my ($self, $c ) = @_;
    $c->response->body( "hola");
}

sub main : Local {
    my ($self, $c ) = @_;
    $c->stash->{template} = '/comp/repl.js';
}

sub eval : Local {
    my ($self, $c ) = @_;
    my $p    = $c->req->parameters;
    my $code = $p->{code};
    my $eval = $p->{eval};
    my $dump = $p->{dump} || 'yaml';
    my $sql = $p->{sql};
     
    # save history
    my @hist;
    if( @hist = @{ $c->session->{repl_hist} || [] } > 20 ) {
        @hist = shift @hist; 
    }
    push @hist, { text=>_now(), code=>$code };
    $c->session->{repl_hist} = \@hist;

    my ($res,$err);
    my $t0 = [gettimeofday];
    my ($stdout, $stderr);

    IO::CaptureOutput::capture( sub {
        if( $sql ) {
            eval {
                $res = $self->sql( $sql, $code );
            }
        } else {
            $code = "use v5.10;$code";
            $res = [ eval $code ];
            $res = $res->[0] if @$res <= 1;
        }
        #my @arr  = eval $code;
        #$res = @arr > 1 ? \@arr : $arr[0];
        $err  = $@;
    }, \$stdout, \$stderr );
    my $elapsed = tv_interval( $t0 );
    $res = _to_utf8( _dump( $res ) ) if $dump eq 'yaml';
    $res = _to_utf8 JSON::XS::encode_json( $res ) if $dump eq 'json' && ref $res && !blessed $res;
    my ($line) = ( $err . $stderr . $stdout ) =~ /line ([0-9]+)/;
    
    $c->stash->{json} = {
        stdout => $stdout,
        stderr => $stderr,
        elapsed => "$elapsed",
        result => "$res",
        error  => "$err",
        line => $line,
        success => \( $err ? 0 : 1 ) ,
    };
    $c->forward('View::JSON');
}

sub sql {
    my ($self, $sql_out, $code ) = @_;
    my $model = 'Baseliner';

    my @sts = $self->sql_normalize( $code );

    my $db = new Baseliner::Core::DBI({ model=>$model });
    if( $sql_out eq 'hash' ) {
        my %results;
        for my $st ( @sts ) {
            %results = $db->hash( $st );
        }
        return \%results;
    } else {
        my @results;
        for my $st ( @sts ) {
            next unless $st;
            push @results, $db->array_hash( $st );
        }
        return \@results;
    }
}

sub sql_normalize {
    my ($self, $sql) = @_;
    my @sts;
    my $st;
    for( split /\n|\r/, $sql ) {
        next if /^\s*--/;  # comments
        if( /^(.+);\s*$/ ) {
            $st .= $1;
            push @sts, $st;
            $st = '';
        } else {
            $st .= $_;  
        }
    }
    push @sts, $st if $st;
    return @sts;
}

sub save : Local {
    my ($self, $c ) = @_;
    my $p    = $c->req->parameters;
    if( $p->{id} ) {
        _log "Saving REPL: " . $p->{id};
        my $key = join'/','saved.repl',$p->{id};
        $c->model('Repository')->set( ns=>$key, data=>{ code=> $p->{code}, output=>$p->{output}, username=>$c->username });
    }
}

sub delete : Local {
    my ($self, $c ) = @_;
    my $p    = $c->req->parameters;
    if( $p->{ns} ) {
        $c->model('Repository')->delete( ns=>'saved.repl/' . $p->{ns} );
    }
}

sub load : Local {
    my ($self, $c ) = @_;
    my $p    = $c->req->parameters;
    my $item = $c->model('Repository')->get( ns=>'saved.repl/' . $p->{ns} );
    $c->stash->{json} = $item;
    $c->forward('View::JSON');
}

# deprecated
sub list_saved : Local {
    my ($self, $c ) = @_;
    my $p    = $c->req->parameters;
    my @ns = $c->model('Repository')->list( provider=>'saved.repl' );
    my $k = 0;
    $c->stash->{json} = {
        data=> [ sort { lc $a->{ns} cmp lc $b->{ns} }map {
            my $ns= (ns_split($_))[1];
            { id=>$k++, ns=>$ns, leaf=>\0 } 
        } @ns ]
    };
    $c->forward('View::JSON');
}

sub tree_saved : Local {
    my ($self, $c ) = @_;
    my $p    = $c->req->parameters;
    my $query = $p->{query};
    my @ns = $c->model('Repository')->list( provider=>'saved.repl' );
    my $k = 0;
    $c->stash->{json} = [
        grep { $query ? $_->{text} =~ /$query/i : 1 }
        sort { lc $a->{text} cmp lc $b->{text} }
        map {
            my $ns= (ns_split($_))[1];
            { text=>$ns, leaf=>\1, url_click=>'/repl/load', data=>{ ns=>$ns } } 
        } @ns
    ];
    $c->forward('View::JSON');
}

sub tree_hist : Local {
    my ($self, $c ) = @_;
    my $p    = $c->req->parameters;
    my $query = $p->{query};
    my $i = 0;
    $c->stash->{json} = [
        map {
            { text=>$_->{text}, leaf=>\1, url_click=>'/repl/load_hist', data=>{ i=>$i++ } }
        }
        grep { $query ? $_->{code}=~/$query/i : 1 }
        grep { ref eq 'HASH' }
        _array( $c->session->{repl_hist} )
    ];
    $c->forward('View::JSON');
}

sub load_hist : Local {
    my ($self, $c ) = @_;
    my $p    = $c->req->parameters;
    my $i    = $p->{i};
    my $h    = $c->session->{repl_hist}->[ $i ];
    $c->stash->{json} = ref $h 
        ? { code=>$h->{eval}, output=>$h->{output} }
        : { output=>'not found' };
    $c->forward('View::JSON');
}

sub tree_class : Local {
    my ($self, $c ) = @_;
    my $p = $c->req->parameters;
    my $query = $p->{query};
    my %cl=Class::MOP::get_all_metaclasses;
    my @classes = keys %cl;
    if( $p->{filter} ) {
       @classes = grep /$p->{filter}/, @classes; 
    }
    $c->stash->{json} = [ map {
        { text=>$_, leaf=>\0, url=>'/repl/class_meth', url_click=>'/repl/class_pod', data=>{ class=>$_ }, iconCls=>'icon-cmp' } 
        }
        grep { length $query ? /$query/i : 1 }
        sort @classes
     ];
    $c->forward('View::JSON');
}

sub _file_for_class {
    my ($self, $class ) = @_;
    ( my $file = $class ) =~ s/::/\//g;
    $file .= '.pm';
    $INC{ $file } || _throw "Class file not found: $class";
}

sub class_pod : Local {
    my ($self, $c ) = @_;
    my $p    = $c->req->parameters;
    my $file = $self->_file_for_class( $p->{class} );
    #my $pod = (_file $file )->slurp;
    use Pod::Simple::HTML;
      my $psh = Pod::Simple::HTML->new;
      $psh->output_string(\my $pod);
      $psh->parse_file($file);
    unless( $pod ) {
        $pod = _file( $file )->slurp unless $pod  ;
        $pod = "<pre>$pod</pre>";
    }
    $c->stash->{json} = { div=>$pod };
    $c->forward('View::JSON');
}

sub meth_pod : Local {
    my ($self, $c ) = @_;
    my $p    = $c->req->parameters;
    my $meth = $p->{meth};
    my $file = $self->_file_for_class( $p->{class} );
    my $pod = (_file $file )->slurp;
    my $output = 
        $pod =~ m/(=head.\s+$meth(.*?)=cut)/sg
        ? $1
        : 'not found';
    $c->stash->{json} = { output=>$output };
    $c->forward('View::JSON');
}

sub class_meth : Local {
    my ($self, $c ) = @_;
    my $p    = $c->req->parameters;
    my $query = $p->{query};
    my $class = $p->{class};
    my @attrs = map {
            { text=>$_, leaf=>\1, url_click=>'/repl/attr_pod', data=>{ class=>$class, attr=>$_ }, iconCls=>'icon-prop' }
        } grep { $query ? /$query/ : 1 } sort $class->meta->get_attribute_list;
    my @meths = map {
            { text=>$_, leaf=>\1, url_click=>'/repl/meth_pod', data=>{ class=>$class, meth=>$_ }, iconCls=>'icon-method'  }
        } grep { $query ? /$query/ : 1 } sort $class->meta->get_method_list;
    $c->stash->{json} = [ @attrs, @meths ];
    $c->forward('View::JSON');
}

sub tree_main : Local {
    my ($self, $c ) = @_;
    my $p    = $c->req->parameters;
    $c->stash->{json} = [
        { text => 'History', url=>'/repl/tree_hist', leaf=>\0, expandable=>\1, expanded=>\0 },
        { text => 'Baseliner Classes', url=>'/repl/tree_class', leaf=>\0, expandable=>\1, expanded=>\0, data=>{filter=>'^Baseliner'} },
        { text => 'Other Classes', url=>'/repl/tree_class', leaf=>\0, expandable=>\1, expanded=>\0, data=>{filter=>'^(?!Baseliner)'}  },
        { text => 'Saved', url=>'/repl/tree_saved', leaf=>\0, expandable=>\1, expanded=>\0 },
    ];
    $c->forward('View::JSON');
}

sub save_to_file : Local {
    my ($self, $c ) = @_;
    my $p    = $c->req->parameters;
    my @ns = $c->model('Repository')->list( provider=>'saved.repl' );
    try {
        for ( @ns ) {
            my $name = (ns_split($_))[1];
            $name =~ s{\s}{_}g;
            my $item = $c->model('Repository')->get( ns=>$_ );
            my $file = Baseliner->path_to('etc', 'repl', "$name.t" );
            my $code = $item->{code};
            my $output = $item->{output};
            $code =~ s{\r}{}g;
            $output =~ s{\r}{}g;
            open my $out,'>',$file;
            print $out $code;
            print $out "\n__END__\n";
            print $out $output; 
            print $out "\n";
            close $out;
        }
        $c->stash->{json} = { success=>\1 };
    } catch {
        $c->stash->{json} = { success=>\0, msg=>shift };
    };
    $c->forward('View::JSON');
}
1;
