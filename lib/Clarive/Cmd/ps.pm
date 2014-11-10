package Clarive::Cmd::ps;
use Mouse;
extends 'Clarive::Cmd';
use v5.10;
use strict;
use Proc::ProcessTable;
use Proc::Exists 'pexists';
use Path::Class;

our $CAPTION = 'list server processes';

with 'Clarive::Role::TempDir';

sub run {
    my ($self, %opts) = @_;
    my $FORMAT = "%-6s %-6s %-6s %-6s %-8s %-24s %s";
    my $t = new Proc::ProcessTable;
    my (%disp, %server, %jobs);
    my $top = sprintf($FORMAT, "PID", "PPID", "CPU", "MEM", "STAT", "START", "COMMAND");
    $opts{v} and say "PID_DIR = " . $self->pid_dir;
    my %pids = map {
        my $pid = file( $_ )->slurp;
        $pid =~ s/^([0-9]+).*$/$1/gs;
        $opts{v} and say "PID detected [$pid] in $_";
        my $type = /-web/ ? 'server' : /-job/ ? 'job' : 'disp';
        $pid>0 && pexists($pid) ? ( $pid => { type=>$type, pid=>$pid } ) : ();
    } glob $self->pid_dir . '/cla*.pid';

    say "PARENT PIDS: " . Clarive->yaml( \%pids ) if $opts{v};
    
    my %procs = ( job=>{},server=>{},disp=>{} );
    
    foreach my $p ( @{$t->table} ){
        my $line = sub {
            my ($type) = @_;
            sprintf($FORMAT,
              $p->pid,
              $p->ppid,
              ( $^O eq 'cygwin' ? '??' : $p->pctcpu . '%' ),
              ( $^O eq 'cygwin' ? '??' : $p->pctmem . '%' ),
              #$p->ttydev,
              $p->state,
              scalar(localtime($p->start)),
              $self->filter_cmd($type, $^O eq 'cygwin' ? $p->fname : $p->cmndline) 
            );
        };
        
        no warnings;
        if( my $parent = $pids{$p->ppid} || $pids{$p->pid} ) {
            my $type = $parent->{type};
            $procs{$type}{$p->pid} = +{ %$parent, line=>$line->($type) }; 
            $pids{$p->pid} = $parent;
        } else {
            my $type = $parent->{type};
        }
        
        #for my $pid ( @pids ) {
        #    if( $pid->{pid}>1 && ($pid->{pid} == $p->pid || $pid->{pid} == $p->ppid) ) {
        #        if( $pid->{type} eq 'server' || $server_pids{$p->ppid} ) {
        #            $server{ $p->pid } = $line->($pid->{type});
        #            $server_pids{$p->pid}=1;
        #        } elsif( $pid->{type} eq 'job' ) {
        #            $jobs{ $p->pid } = $line->($pid->{type});
        #        } else {
        #            $disp{ $p->pid } = $line->($pid->{type});
        #        }
        #    }
        #}
    }

    say "--------------|    Jobs    |-----------";
    say $top if keys $procs{job};
    say $procs{job}{$_}{line} for sort keys $procs{job};
    say "--------------| Dispatcher |-----------";
    say $top if keys $procs{disp};
    say $procs{disp}{$_}{line} for sort keys $procs{disp};
    say "--------------|   Server   |-----------";
    say $top if keys $procs{server};
    say $procs{server}{$_}{line} for sort keys $procs{server};
}

sub run_filter {
    my ($self) = @_; 
    my $FORMAT = "%-6s %-6s %-8s %-24s %s";
    my $t = new Proc::ProcessTable;
    my @disp;
    my @server;
    my $top = sprintf($FORMAT, "PID", "PPID", "STAT", "START", "COMMAND");
    foreach my $p ( @{$t->table} ){
        my $lin = sprintf($FORMAT,
              $p->pid,
              $p->ppid,
              #$p->ttydev,
              $p->state,
              scalar(localtime($p->start)),
              $self->filter_cmd( $^O eq 'cygwin' ? $p->fname : $p->cmndline) );
        given( $^O eq 'cygwin' ? $p->fname : $p->cmndline ) {
            when( /starman|plackup|bali_server|start_server/ ) {
                push @server, $lin;
            }
            when( /perl/ && /ba.*pl/ ) {
                push @disp, $lin;
            }
        }
    }

    say "--------------| Dispatcher |-----------";
    say $top if @disp;
    say for @disp;
    say "--------------|   Server   |-----------";
    say $top if @server;
    say for @server;
}

sub filter_cmd {
    my ($self,$type,$cmd) = @_;
    if( $type eq 'job' && $cmd !~ /^clarive/ ) {
        $cmd =~ s/(\n|\r)+/ /g;
        $cmd = "internal: $cmd";
    }
    $cmd =~ s/\s+/ /g;
    $cmd = substr( $cmd, 0, 64 );
    return $cmd;
}

1;
