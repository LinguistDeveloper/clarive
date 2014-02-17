package Clarive::Cmd::queue;
use Mouse;
extends 'Clarive::Cmd';
use v5.10;
use Term::ANSIColor qw/:constants/;

has server => qw(is rw isa Str), default => sub { 
    my ($self)=@_;
    return $self->app->config->{redis}{server} // 'localhost:6379';
};

has db => qw(is ro lazy 1), default => sub { 
    my ( $self ) = @_;
    require Redis;
    Redis->new( %{ $self->app->config->{redis} || {} }, server=>$self->server );
};

has queue => qw(is ro lazy 1), default => sub { 
    my ( $self ) = @_;
    require Redis;
    Redis->new( %$self );
};

with 'Clarive::Role::Baseliner'; 

our $CAPTION = 'queue management tools';

sub run {
    goto &run_workers;
}

sub run_workers {
    my ($self,%opts)=@_;
    
    require JSON::XS;
    
    say "workers:";
    for my $key ( $self->db->hkeys('queue:workers') ) {
        my $v = $self->db->hget( 'queue:workers', $key);
        if( $self->verbose ) {
            my $cy = $self->_format_conf( $v );
            say BLACK ON_BRIGHT_BLACK, $key, RESET, "\n$cy\n";
        } else {
            require BaselinerX::CI::worker_agent;
            my $msg = BaselinerX::CI::worker_agent->parse_message($v);
            say BLACK ON_BRIGHT_BLACK, $key, RESET, " $$msg{started_on} | $$msg{user}\@$$msg{host}:$$msg{home} | pid=$$msg{pid} | $$msg{os}-$$msg{arch}";
        }
    }

}

sub run_keys {
    my ($self,%opts)=@_;
    
    my $mask = $opts{mask} // '*';
    say "queue:$mask keys:";
    for my $key ( $self->db->keys("queue:$mask") ) {
        say "  $key";
    }
    say 'done.';
}

sub run_ping {
    my ($self,%opts)=@_;
    
    require JSON::XS;
    
    my $wid = $opts{wid} // $opts{workerid} // die "Missing option workerid\n";
    $self->queue->subscribe("queue:pong:$wid", sub{
        my ($msg)=@_;
        my $cy = $self->_format_conf( $msg );
        say "worker id $wid is alive:\n$cy"; 
        exit 0;
    });
    say "pinging $wid...";
    $self->db->publish("queue:$wid:ping", '');
    for( 1..5 ) {
        $self->queue->wait_for_messages( 5 );
        print '.';
    }
    say 'done.';
}

sub run_flush {
    my ($self,%opts)=@_;
    my @wids = $self->db->hkeys('queue:workers');
    say sprintf "pinging %d workers.", scalar @wids;
    my %found;
    $self->queue->psubscribe("queue:pong:*", sub{
        my ($msg, $topic)=@_;
        my ($s,$ss,$wid) = split /:/, $topic;
        say "pong from $wid";
        $found{ $wid } = 1;
        say("all workers online."), exit 0 if keys %found >= @wids;
    });
    $self->db->publish("queue:$_:ping", '') for @wids;
    for( 1..5 ) {
        $self->queue->wait_for_messages( 1 );
        print '.';
    }
    say '';
    say sprintf "got responses from only %d worker(s), cleanup...", scalar keys %found;
    my @dead = grep { !exists $found{$_} } @wids;
    $self->db->hdel( 'queue:workers', $_ ) for @dead;
    say sprintf "removed %d dead worker(s) from registry queue:workers: %s", scalar @dead, join ',', @dead;
}

sub run_del {
    my ($self,%opts)=@_;
    my $mask = $opts{mask} // '*';
    say ON_RED, "deleting all keys matching mask $mask:", RESET;
    my $k = 0;
    for my $key ( $self->db->keys("queue:$mask") ) {
        say "deleting key $key...";
        $self->db->del( $key );
        $k++;
    }
    say $k ? "deleted $k keys." : 'none available.';
}

sub _format_conf {
    my ($self,$v) = @_;
    $v =~ s/"|\{|\}//g;
    $v =~ s/,/, /g;
    $v;
}

sub _format_conf_yaml {
    my ($self,$v) = @_;
    my $conf = JSON::XS::decode_json($v);
    my $cy = $self->app->yaml( $conf );
    $cy=~ s/\n/\n    /g;
    $cy=~s/---\n//g;
    return $cy;
}
1;

