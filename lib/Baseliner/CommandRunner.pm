package Baseliner::CommandRunner;
use Moose;

has timeout          => qw(is ro isa Num);
has output_cb        => qw(is ro isa CodeRef);
has stdout_output_cb => qw(is ro isa CodeRef);
has stderr_output_cb => qw(is ro isa CodeRef);

use IO::Select;
use IPC::Open3 qw(open3);
use Symbol 'gensym';

sub run {
    my $self = shift;
    my ( $cmd, @args ) = @_;

    my ( $cmd_in, $cmd_out, $cmd_err );
    $cmd_err = gensym;

    my $pid = open3( $cmd_in, $cmd_out, $cmd_err, $cmd, @args );

    close($cmd_in);

    my $select = IO::Select->new( $cmd_out, $cmd_err );

    my $output        = '';
    my $stdout_output = '';
    my $stderr_output = '';

    while ( my @ready = $select->can_read() ) {
        foreach my $handle (@ready) {
            if ( sysread( $handle, my $buf, 4096 ) ) {
                if ( $handle == $cmd_out ) {
                    $output        .= $buf;
                    $stdout_output .= $buf;

                    $self->stdout_output_cb->($buf) if $self->stdout_output_cb;
                }
                else {
                    $output        .= $buf;
                    $stderr_output .= $buf;

                    $self->stderr_output_cb->($buf) if $self->stderr_output_cb;
                }

                $self->output_cb->($buf) if $self->output_cb;
            }
            else {
                $select->remove($handle);
            }
        }
    }

    if ( $select->count ) {
        kill( 'TERM', $pid );
    }

    close($cmd_out);
    close($cmd_err);

    waitpid( $pid, 0 );

    my $exit_code;

    if ( $? == -1 ) {
        $exit_code = 255;
    }
    elsif ( $? & 127 ) {
        $exit_code = 255;
    }
    else {
        $exit_code = $? >> 8;
    }

    return {
        exit_code     => $exit_code,
        stdout_output => $stdout_output,
        stderr_output => $stderr_output,
        output        => $output
    };
}

1;
