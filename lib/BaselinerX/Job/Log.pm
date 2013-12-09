package BaselinerX::Job::Log;
use Baseliner::Plug;
use Baseliner::Utils;
use Compress::Zlib;
use Try::Tiny;

with 'Baseliner::Role::Logger';

# register 'menu.job.logs' => { label => _loc('Job Logs'), url_comp => '/job/log/list', title=>_loc('Job Logs') };
register 'config.job.log' => {
    metadata => [
        { id=>'job_id', label=>'Job', width=>200 },
        { id=>'log_id', label=>'Id', width=>80 },
        { id=>'lev', label=>_loc('Level'), width=>80 },
        { id=>'text', label=>_loc('Message'), width=>200 },
    ]

};

=head1 Logging

Handles all job logging. 

The basics:

    my $job = $c->stash->{job};
    my $log = $job->logger;
    $log->error( "An error" );

With data:

    $log->error(
        "Another error",
        data      => $stdout_file,
        data_name => 'A title for a log tab'
    );

A file:

    $log->info(
        "An interesting file",
        data      => $file_contents,
        data_name => 'goodfile.txt'
    );

=cut

has job             => ( is => 'rw', isa => 'BaselinerX::CI::job', weak_ref=>1 );
has exec            => ( is => 'rw', isa => 'Int', default => 1 );
has current_section => ( is => 'rw', isa => 'Str', default => 'general' );
has current_service => ( is => 'rw', isa => 'Maybe[Str]', default => '' );
has rc_config       => ( is => 'rw', isa => 'HashRef', default => sub { { 0 => 'info', 1 => 'warn', 2 => 'error' } } );
has last_log        => ( is => 'rw', isa => 'Any', default => sub { {} } );

sub log_levels { +{ warn => 3, error => 4, debug => 2, info => 2 } }
has max_service_level => ( is => 'rw', isa => 'Int', default => 2 );
has max_step_level    => ( is => 'rw', isa => 'Int', default => 2 );

# set the execution number for this log roll
sub BUILD {
    my ($self,$params) = @_;
    $self->current_service( $self->job->current_service ); 
    if( ref $self->job ) {
        $self->exec( $self->job->exec ); # unless defined $self->exec;
    }
}

=head2 common_log

Centralizes all logging levels. You may create your own levels if you wish.

All data is compressed. 

=cut
sub common_log {
    my ( $lev, $self, $text )=( shift, shift, shift);
    my ($package, $filename, $line) = caller 1;
    my $module = "$package - $filename ($line)";
    my %p = ( 1 == scalar @_ ) ? ( data=>shift ) : @_; # if it's only a single param, its a data, otherwise expect param=>value,...  
    $p{data}||='';
    ref $p{data} and $p{data}=_dump( $p{data} );  # auto dump data if its a ref
    $p{'dump'} and $p{data}=_dump( delete $p{'dump'} );  # auto dump data if its a ref
    my $job_exec = $self->exec;
    my $jobid = $self->jobid;
    my $row;
    # set max level
    if( my $log_level = $self->log_levels->{ $lev } ) {
        $self->max_service_level( $log_level ) if $log_level > $self->max_service_level;
        $self->max_step_level( $log_level ) if $log_level > $self->max_step_level;
    }
    if( length($text) > 2000 ) {
        # publish exceeding log to data
        $p{data}.= '=' x 50;
        $p{data}.= "\n$text";
        # rewrite text message
        $text = substr( $text, 0, 2000 );
        $text .= '=' x 20;
        $text .= "\n(continue...)";
    }
    try {
        $row = Baseliner->model('Baseliner::BaliLog')->create({ id_job =>$jobid, text=> $text, lev=>$lev, module=>$module, exec=>$job_exec }); 
        $row = mdb->job_log->create({ id_job =>$jobid, text=> $text, lev=>$lev, module=>$module, exec=>$job_exec }); 

        $p{data} && $row->data( compress $p{data} );  ##TODO even with compression, too much data breaks around here - use dbh directly?
        defined $p{more} && $row->more( $p{more} );
        $p{data_name} && $row->data_name( $p{data_name} );
        $p{data} && $row->data_length( length( $p{data} ) );
        $p{prefix} and $row->prefix( $p{prefix} );
        $p{milestone} and $row->milestone( $p{milestone} );
        $row->service_key( $self->current_service );

        # print out too
        Baseliner::Utils::_log_lev( 5, sprintf "[JOB %d][%s] %s", $self->jobid, $lev, $text );
        Baseliner::Utils::_log_lev( 5, substr($p{data},0,1024*10) )
            if Baseliner->debug && defined $p{data} && !$p{data_name} # no files wanted!;

        # store the current section
        ;
        $p{username} && $lev eq 'comment'
            ? $row->section( $p{username} )
            : $row->section( $self->current_section );

        # store the current step
        my $step = $row->job->step;
        $row->step( $step ) if $step;

        $row->update;
        $self->last_log( $row->get_columns ) if $lev ne 'debug';
    } catch {
        my $err = shift;
        _log "*** Error writing log entry: $err";
        _log "*** Log text: $text (lev=$lev, jobid=$jobid)";
    };
    return $row;
}

sub comment { common_log('comment',@_) }
sub warn { common_log('warn',@_) }
sub error { common_log('error',@_) }
sub fatal { common_log('fatal',@_) }
sub info { common_log('info',@_) }
sub debug { common_log('debug',@_) }


=head2 log_on_rc

Allows change the log level depending on a return code value. 

    $log->rc_config({ 0=>'info', 1=>'warn', 99=>'error' });

    # 0 = info
    # 1 to 98 = warning
    # >99 = error

    $log->log_on_rc( $some_rc, 'This can be an error or something else', data=>$lots_of_data );

The message will have a " (RC=$rc_code)" string part appended at the end. 

=cut
sub log_on_rc {
    my $self = shift;
    my $rc = shift;
    my $msg = shift;
    for my $err ( sort { $b <=> $a } keys %{ $self->rc_config || {} } ) {
        if( $rc >= $err ) {
            common_log( $self->rc_config->{$err}, $self, $msg . " (RC=$rc)" , @_);
            return;
        }
    }
    $self->warn( $msg, @_);
}

=head1 TODO

=over 4

=item * 

Add pluggable log data viewers on the value of "more"

=cut
1;
