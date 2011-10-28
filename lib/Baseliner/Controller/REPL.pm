package Baseliner::Controller::REPL;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use JSON::XS;
use Capture::Tiny qw/capture capture_merged/;
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

sub test : Local {
    my ($self, $c ) = @_;
    $c->response->body( "hola");
}

sub main : Local {
    my ($self, $c ) = @_;
    $c->stash->{template} = '/comp/repl.mas';
}

sub eval : Local {
    my ($self, $c ) = @_;
    my $p    = $c->req->parameters;
    my $code = $p->{code};
    my $eval = $p->{eval};
    my $dump = $p->{dump} || 'yaml';
    my $sql = $p->{sql};

    my ($res,$err);
	my $t0 = [gettimeofday];
    my ($stdout, $stderr) = capture {
        if( $sql ) {
            eval {
                $res = $self->sql( $sql, $code );
            }
        } else {
            $res = [ eval $code ];
            $res = $res->[0] if @$res <= 1;
        }
        #my @arr  = eval $code;
		#$res = @arr > 1 ? \@arr : $arr[0];
        $err  = $@;
    };
	my $elapsed = tv_interval( $t0 );
    $res = _dump( $res ) if $dump eq 'yaml';
    $res = JSON::XS::encode_json( $res ) if $dump eq 'json' && ref $res && !blessed $res;
    $c->stash->{json} = {
        stdout => $stdout,
        stderr => $stderr,
		elapsed => "$elapsed",
        result => "$res",
        error  => "$err",
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
