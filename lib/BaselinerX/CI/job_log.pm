package BaselinerX::CI::job_log;
use Baseliner::Moose;
use Baseliner::Utils;
use Compress::Zlib;
use Try::Tiny;

with 'Baseliner::Role::Logger';

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

has jobid           => ( is => 'rw', isa => 'Int', required => 1 );
has job             => ( is => 'rw', isa => 'Object', weak_ref=>1 );
has exec            => ( is => 'rw', isa => 'Int', required => 1 );
has current_section => ( is => 'rw', isa => 'Str', default => 'general' );
has current_service => ( is => 'rw', isa => 'Maybe[Str]', required =>1 );
has rc_config       => ( is => 'rw', isa => 'HashRef', default => sub { { 0 => 'info', 1 => 'warn', 2 => 'error' } } );
has last_log        => ( is => 'rw', isa => 'Any', default => sub { {} } );

has max_service_level => ( is => 'rw', isa => 'Int', default => 2 );
has max_step_level    => ( is => 'rw', isa => 'Int', default => 2 );

sub log_levels { +{ warn => 3, error => 4, debug => 2, info => 2 } }

=head2 common_log

Centralizes all logging levels. You may create your own levels if you wish.

All data is compressed. 

=cut
sub common_log {
    my ( $self, $lev, $text )= ( shift, shift, shift );
    my $caller_lev = 1;
    if( ref $lev eq 'ARRAY' ) {
        $caller_lev = $lev->[1];
        $lev = $lev->[0];
    }
    my ($package, $filename, $line) = caller $caller_lev;
    my $module = "$package - $filename ($line)";
    my %p = ( 1 == scalar @_ ) ? ( data=>shift ) : @_; # if it's only a single param, its a data, otherwise expect param=>value,...  
    $p{data}||='';
    ref $p{data} and $p{data}=_dump( $p{data} );  # auto dump data if its a ref
    $p{'dump'} and $p{data}=_dump( delete $p{'dump'} );  # auto dump data if its a ref
    my $job_exec = 0+$self->exec;
    my $jobid = $self->jobid;
    my $mid = ''.$self->job->mid;
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
    # check for password patterns - TODO put this in config
#    $text =~ s{(\S+/)\S+@}{$1\************@}g;  # XXX the asterisk is "bold" in log textile
    # Using config.global.password_patterns
    $text = Baseliner::Utils::hide_passwords($text);    
    try {
        my $id = 0+ mdb->seq('job_log_id');  # numeric, good for sorting
        my $doc = { id=>$id, mid =>$mid, text=> $text, lev=>$lev, module=>$module, exec=>$job_exec, ts=>Util->_now(), t=>Time::HiRes::time() };
        
        $doc->{_id} = mdb->job_log->insert($doc); 
        
        $doc->{pid} = $$;
        $doc->{more} = $p{more} if defined $p{more};
        $doc->{data_name} = $p{data_name} if $p{data_name};
        $doc->{data_length} = length( $p{data} ) if $p{data};
        $doc->{prefix} = $p{prefix} if $p{prefix};
        $doc->{milestone} = "$p{milestone}" if $p{milestone};
        $doc->{service_key} = $self->current_service;
        $doc->{rule} =  $self->job->{id_rule} if defined $self->job->{id_rule};
        if( $p{data} ) {
            my $data = Util->hide_passwords( $p{data});
            my $d = compress( $data );  ## asset in grid
            my $ass = mdb->asset( $d, parent=>$doc->{_id}, parent_mid=>$mid, id_log=>$id, filename=>$doc->{data_name}//'', parent_collection=>'log' );
            $ass->insert;
            $doc->{data} = $ass->id;
        }
        
        # save top level for this statement if higher
        my $loglevels = $self->log_levels;
        my $top_service_level = $self->job->service_levels->{ $self->job->step }{ $self->current_service };
        $self->job->service_levels->{ $self->job->step }{ $self->current_service } = $lev 
            if $loglevels->{$lev} > ( $top_service_level ? $loglevels->{$top_service_level} : 0 ); 

        # print out too
        {
            local $Baseliner::logger = undef;  # prevent recursivity
            Baseliner::Utils::_log_lev( 5, sprintf "[JOB %d][%s] %s", $self->jobid, $lev, $text );
            Baseliner::Utils::_log_lev( 5, substr($p{data},0,1024*10) )
                if Clarive->debug && defined $p{data} && !$p{data_name}; # no files wanted!
        }

        # store the current section
        ;
        $p{username} && $lev eq 'comment'
            ? $doc->{section} = $p{username}
            : $doc->{section} = $self->current_section;

        # store the current step
        my $step = $self->job->step;
        $doc->{step} = $step if $step;

        mdb->job_log->save( $doc );
        
        $self->last_log( $doc ) if $lev ne 'debug';
        $row = $doc;
    } catch {
        my $err = shift;
        local $Baseliner::logger = undef;  # prevent recursivity
        _log "*** Error writing log entry: $err";
        _log "*** Log text: $text (lev=$lev, jobid=$jobid)";
    };
    return $p{return_row} ? $row : undef;
}

sub comment { shift->common_log('comment',@_) }
sub warn { shift->common_log('warn',@_) }
sub error { shift->common_log('error',@_) }
sub fatal { shift->common_log('fatal',@_) }
sub info { shift->common_log('info',@_) }
sub debug { shift->common_log('debug',@_) }


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
            $self->common_log( $self->rc_config->{$err}, $self, $msg . " (RC=$rc)" , @_);
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

