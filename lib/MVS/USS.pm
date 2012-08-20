package MVS::USS;
use strict;
use base 'Net::Telnet';
our $VERSION = '0.01';

use Time::HiRes;
use File::Spec::Unix;

sub new {
    my $class = shift;
	my $parms = {@_};
	# connect to telnet
	my %telnet_opts = @_;
	delete $telnet_opts{$_}
		for( qw/host port user password uss_tmp_dir uss_tmp_prefix/ );
	$telnet_opts{Prompt} ||= '/IBMUSER\:.*$/';
	$telnet_opts{Timeout} ||= 20;
    my $self = new Net::Telnet( %telnet_opts );
	# now do USS specifics
    $parms->{uss_tmp_dir} ||= '/tmp';
    $parms->{uss_tmp_prefix} ||= 'mvs_uss';
    $parms->{uss_end_block} ||= '__END__';
	$parms->{uss_put_delay} ||= 1000; # in microseconds
	# open connection if needed
    $self->open( Host => $parms->{host}, Port=> $parms->{port} || 1023 ) 
		if exists $parms->{host} ;
	# send login, if needed
    $self->login( $parms->{user}, $parms->{password} )
		if exists $parms->{user} && exists $parms->{password};
	# done
	*$self->{mvs_uss} = $parms;
    return bless $self, $class;
}

sub env {
    my ( $self, %vars ) = @_;
    for my $key ( keys %vars ) {
        $self->cmd( $key . "=" . $vars{ $key } );
    }
}

sub parms { my $self = shift; *$self->{mvs_uss}; }

sub rexx {
	my $self = shift;
	my $rexx = join '',@_;
	my $parms = $self->parms; 
	$self->print("\n");
	$self->print("\n");
	$self->print("\n");
	$self->print("\n");
	# cleanup
    $rexx =~s{\t|\r}{}g;
    # temp file 
    my ($rem_pid) = $self->cmd('echo $$');
    $rem_pid =~s{\r|\n}{}g;
	$rem_pid ||= $$;
    my $tmpfile = File::Spec::Unix->catfile( $parms->{uss_tmp_dir}, $parms->{uss_tmp_prefix} .'_'. $rem_pid. '.rexx' );
    $self->binmode(1);
    $self->buffer_empty;
    # write file
	my $end_block = $parms->{uss_end_block};
    $self->put(
        qq{cat <<$end_block > $tmpfile 2>&1; chmod +x $tmpfile; $tmpfile 2>&1; rm $tmpfile >/dev/null 2>&1\n/* REXX */ }
    );
	# put one line at a time, and slowly
    for ( split /\n/, $rexx ) {
        $self->put(qq{$_\n});
        Time::HiRes::usleep( $parms->{uss_put_delay} );
    }
    # execute rexx
	my @ret = $self->cmd(qq{\n$end_block\n});
	# warn "Endevor output: \n". join'',@ret;
	my @RET = map { s{^(\>\s)*}{}g; $_ } @ret;
	# warn "Endevor Editted output: \n". join'',@RET;
    # return map { s{^\>\s}{}g; $_ } $self->cmd(qq{\n$end_block\n});
    return @RET;
}

sub tso {
	my $self = shift;
	my $cmd  = join '',@_;
	my $parms = $self->parms; 
	Time::HiRes::usleep( $parms->{uss_put_delay} );
	$self->print("\n");
	#$cmd =~ s{"}{\"}g;
	print "Running '$cmd'\n";
    $self->buffer_empty;
	return $self->cmd(qq{tso -t $cmd 2>&1\n});
}

=head1 NAME

MVS::USS - MVS USS (OMVS) interface for running commands remotely

=head1 DESCRIPTION

This module extends L<Net::Telnet> and adds a few features that are
hopefully useful for running commands on a Unix System Services (USS) 
manfraime subsystem.

=head1 METHODS

=head2 new

Creates a new instance of L<MVS::USS>.

Parameters:

    uss_tmp_dir     : remote temporary directory  (default: /tmp )
    uss_tmp_prefix  : prefix to be added to temp files (default: mvs_uss)
    uss_end_block   : end of file marker to identify output (default __END__)
	uss_put_delay   : microseconds to wait before sendind data (default 1000)

=head2 rexx

Runs a REXX program remotely and returns the stdout 
without any noise.

    my $program = q{
        i = 10
        say "hello from rexx" i
    };
    $uss->rexx( $program );

=head2 tso

Runs a TSO command.

    $uss->tso( q{DELETE //"'my.data.set'"} );

=cut

1;

