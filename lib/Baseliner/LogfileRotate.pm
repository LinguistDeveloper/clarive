package Baseliner::LogfileRotate;

use Config;    # do we have gzip
use Carp;
use IO::File;
use File::Copy;
use Fcntl qw(:flock);

use Baseliner::Utils;

use strict;

use vars qw($VERSION $COUNT $GZIP_FLAG);

$VERSION = do { my @r=(q$Revision: 1.5 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r};
$COUNT   =7; # default to keep 7 copies
$GZIP_FLAG='-qf'; # force writing over old logfiles


sub new {
	my ($class, %args) = @_;
	croak("usage: new( File => filename 
				[, Count    => cnt ]
				[, Gzip     => lib or \"/path/to/gzip\" or no ] 
				[, Signal   => \&sub_signal ]
				[, Pre      => \&sub_pre ]
				[, Post     => \&sub_post ]
				[, Flock    => yes or no ]
				[, Persist  => yes or no ]
				[, Dir      => \"dir/to/put/old/files/into\"] )")
		unless defined($args{'File'});

	my $self = {};
	$self->{'Fh'}	  = undef;
	$self->{'File'}   = $args{'File'};
	$self->{'Count'}  = ($args{'Count'} or 7);
	$self->{'Signal'} = ($args{'Signal'} or sub {1;});
	$self->{'Pre'} = ($args{'Pre'} or sub {1;});
	$self->{'Post'} = ($args{'Post'} or sub {1;});
	$self->{'Flock'}  = ($args{'Flock'} or 'yes');
	$self->{'Persist'}  = ($args{'Persist'} or 'yes');

	# deprecated methods
	carp "Signal is a deprecated argument, see Pre/Post" if $args{'Signal'};

	# mutual excl
	croak "Can not define both Signal and Post" 
		if ($args{Signal} and $args{Post});

	(ref($self->{'Signal'}) eq "CODE")
		or croak "error: Signal is not a CODE reference.";

	(ref($self->{'Pre'}) eq "CODE")
		or croak "error: Pre is not a CODE reference.";

	(ref($self->{'Post'}) eq "CODE")
		or croak "error: Post is not a CODE reference.";

	# Process compression arg
	unless ($args{Gzip}) {
		if (_have_compress_zlib()) {
			$self->{Gzip} = 'lib';
		} else {
			$self->{Gzip} = $Config{gzip};
		}
	} else {
		if ($args{Gzip} eq 'no') {
			$self->{Gzip} = undef;
		} else {
			$self->{Gzip} = $args{Gzip};
		}
	}


	# Process directory arg

	if (defined($args{'Dir'})) {
		$self->{'Dir'} = $args{'Dir'};
		# don't know about creating directories ??
		mkdir($self->{'Dir'},0750) unless (-d $self->{'Dir'});
	} else {
		$self->{'Dir'} = undef;
	}

	# confirm existence of dir

	if (defined $self->{'Dir'} ) {
		croak "error: $self->{'Dir'} not writable" 
		unless (-w $self->{'Dir'});
		croak "error: $self->{'Dir'} not executable" 
		unless (-x $self->{'Dir'});
	}

	# open and lock the file
	if( $self->{'Flock'} eq 'yes'){
	    $self->{'Fh'} = new IO::File "$self->{'File'}", O_WRONLY|O_EXCL;
	    croak "error: can not lock open: ($self->{'File'})" 
		unless defined($self->{'Fh'});
		flock($self->{'Fh'},LOCK_EX);
	}
	else{
	    $self->{'Fh'} = new IO::File "$self->{'File'}";
	    croak "error: can not open: ($self->{'File'})" 
		unless defined($self->{'Fh'});
	}

	bless $self, $class;
}

sub rotate {
    my ($self, %args) = @_;

    my ($prev,$next,$i,$j);

    # check we still have a filehandle
    croak "error: lost file handle, may have called rotate twice ?"
        unless defined($self->{'Fh'});
    my $curr  =  $self->{'File'};
    my $currn =  $curr;
    my $ext   =  $self->{'Gzip'} ? '.gz' : '';
	# Execute and exit if Pre method fails
	eval { &{$self->{'Pre'}}($curr); } if $self->{Pre};
	croak "error: your supplied Pre function failed: $@" if ($@);

	# TODO: what is this doing ??
    my $dir   =  defined($self->{'Dir'}) ? "$self->{'Dir'}/" : "";
    $currn    =~ s+.*/([^/]*)+$self->{'Dir'}/$1+ if defined($self->{'Dir'});
    
    for($i = $self->{'Count'}; $i > 1; $i--) {
        $j = $i - 1;
        my $date;
        my @files = Path::Class::dir( $ENV{CLARIVE_BASE}.'/logs//' )->children;
        for(@files){
            my $quoted = quotemeta $curr;
            if ( $i == 3 && $_ =~ qr/^$quoted\.3\.(?<date>.*)\.gz$/ ) {
                    unlink $_;
                    #last;
            }
        }
        for(@files){
            my $quoted = quotemeta $curr;
            if ( $_ =~ qr/^$quoted\.$j\.(?<date>.*)\.gz$/ ) {
                $date = $+{date};
                last;
            }
        }
        $next = "${curr}." . $i . ".$date" . $ext;
        $prev = "${curr}." . $j . ".$date" . $ext;
        #print "\n".$prev;
        if ( -r $prev && -f $prev ) {
            move($prev,$next)	## move will attempt rename for us
                or croak "error: move failed: ($prev,$next)";
            
        }       
    }
    ## copy current to next incremental
    $next = "${currn}.1";
    copy ($curr, $next);        
	## preserve permissions and status
	if ( $self->{'Persist'} eq 'yes' ){
		my @stat = stat $curr;
		chmod( $stat[2], $next ) or carp "error: chmod failed: ($next)";
		utime( $stat[8], $stat[9], $next ) or carp "error: failed: ($next)";
		sleep 15;
		chown( $stat[4], $stat[5], $next ) or carp "error: chown failed: ($next)";
	}

    # now truncate the file
	if( $self->{'Flock'} eq 'yes' )
	{
		truncate $curr,0 or croak "error: could not truncate $curr: $!"; }
	else{
		local(*IN);
		open(IN, "+>$self->{'File'}") 
			or croak "error: could not truncate $curr: $!";
	}

	if ($self->{'Gzip'} and $self->{'Gzip'} eq 'lib') 
	{
    	my $now = Util->_ts();
		my @parts = split ' ', $now;
		my $time = "$parts[0]T$parts[1]";
		my $find = ":";
		my $replace = "_";
		$find = quotemeta $find;
		$time =~ s/$find/$replace/g;
		$find = "-";
		$find = quotemeta $find;
		$time =~ s/$find/$replace/g;
		my $out_name = $next.".$time".$ext;
		_gzip($next, $out_name);
	}
	

	# TODO: deprecated: remove next release
	eval { &{$self->{'Signal'}}($curr, $next); } if ($self->{Signal});
	croak "error: your supplied Signal function failed: $@" if ($@);

	# Execute and exit on post method
	eval { &{$self->{'Post'}}($curr, $next); } if $self->{Post};
	croak "error: your supplied Post function failed: $@" if ($@);

	# if we made it here we have succeeded
	return 1;
}

sub DESTROY {
    my ($self, %args) = @_;
	return unless $self->{'Fh'};	# already gone
    flock($self->{'Fh'},LOCK_UN);
    undef $self->{'Fh'};    # auto-close
}

sub _have_compress_zlib {
	# try and load the compression library
	eval { require Compress::Zlib; };
	if ($@) {
		carp "warning: could not load Compress::Zlib, skipping compression" ;
		return undef;
	}
	return 1;
}

sub _gzip {
	my $in = shift;
	my $out = shift;

	# ASSERT
	croak "error: _gzip called without mandatory argument" unless $in;

	return unless _have_compress_zlib();
    my($buffer,$fhw);
	$fhw = new IO::File $in 
		or croak "error: could not open $in: $!";
    my $gz = Compress::Zlib::gzopen($out, "wb")
		or croak "error: could not gzopen $out: $!";
    $gz->gzwrite($buffer)
	while read($fhw,$buffer,4096) > 0 ;
    $gz->gzclose() ;
    $fhw->close;

	unlink $in or croak "error: could not delete $in: $!";

	return 1;
}

1;
