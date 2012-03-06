package Baseliner::Controller::Message;
use Baseliner::Plug;
use Baseliner::Utils;
BEGIN {  extends 'Catalyst::Controller' }

sub detail : Local {
    my ($self,$c) = @_;
	my $p = $c->request->parameters;
    my $message = $c->model('Messaging')->get( id=>$p->{id} );
		    
	my $r = $c->model('Baseliner::BaliMessageQueue')->find({ id=>$p->{id}, username=> $c->username });
	$r->swreaded( '1' );
	$r->update();		
	
	$c->stash->{json} = { data => [ $message ] };		
	$c->forward('View::JSON');
}

sub body : Local {
    my ($self,$c, $id) = @_;
    my $message = $c->model('Baseliner::BaliMessage')->find( $id );
	my $body = $message->body;
	$body =~ s{\<html\>}{}g;
	$body =~ s{\</html\>}{}g;
	$body =~ s{\<body\>}{}g;
	$body =~ s{\</body\>}{}g;
	$c->response->body( $message->body );
}

# only for im, with read after check
sub im_json : Local {
    my ($self,$c) = @_;
	my $p = $c->request->parameters;
    return unless $c->user;
    $c->stash->{messages} = $c->model('Messaging')->inbox(username=>$c->username || $c->user->id, carrier=>'instant', deliver_now=>1 );
    $c->forward('/message/json');
}

# all messages for the user
sub inbox_json : Local {
    my ($self,$c) = @_;
	my $p = $c->request->parameters;
    my ($start, $limit, $query, $query_id, $dir, $sort, $cnt ) = ( @{$p}{qw/start limit query query_id dir sort/}, 0 );
	
    $sort ||= 'sent';
    $dir ||='desc';
    return unless $c->user;
    $c->stash->{messages} = $c->model('Messaging')->inbox(
            all      => 1,
            username => $p->{username} || $c->username || $c->user->id,
            query    => $query,
            sort     => $sort,
            dir      => $dir,
            start    => $start,
            limit    => $limit,
			query_id => $query_id || undef
    );
    $c->forward('/message/json');
}

sub json : Local {
    my ($self,$c) = @_;
	my $p = $c->request->parameters;
    my @rows;
	my $cnt = 1;
	foreach my $message ( _array( $c->stash->{messages}->{data} ) ) {
        # produce the grid
        push @rows,
             {
                 id         => $message->id ,
                 id_message => $message->id_message,
                 sender     => $message->sender,
                 subject    => $message->subject,
                 received    => $message->received,
                 body    => substr( $message->body, 0, 100 ),
                 sent       => $message->sent,
				 swreaded	=> $message->swreaded
             }
    }
	$c->stash->{json} = { totalCount=>$c->stash->{messages}->{total}, data => \@rows };
	$c->forward('View::JSON');
}

sub delete : Local {
    my ( $self, $c ) = @_;
	my $p = $c->req->params;
	eval {
        $c->model('Messaging')->delete( id=>$p->{id_message} );
    };
	if( $@ ) {
        warn $@;
		$c->stash->{json} = { success => \0, msg => _loc("Error deleting the message ").$@  };
	} else { 
		$c->stash->{json} = { success => \1, msg => _loc("Message '%1' deleted", $p->{name} ) };
	}
	$c->forward('View::JSON');	
}

sub inbox : Local {
    my ( $self, $c ) = @_;
	my $p = $c->req->params;
	$c->stash->{username} = $c->username;
	$c->stash->{query_id} = $p->{query};	
 	$c->stash->{template} = '/comp/message_grid.mas';
	
}


1;

