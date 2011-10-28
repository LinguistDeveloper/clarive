package Baseliner::Model::Messaging;
use Baseliner::Plug;
extends qw/Catalyst::Model/;
no Moose;
use Baseliner::Utils;
use Baseliner::Core::Message;
use Try::Tiny;

register 'action.notify.admin' =>  { name=>'Receive General Admin Messages' };
register 'action.notify.error' =>  { name=>'Receive Error Notifications' };

=head1 DESCRIPTION

By default messages are sent by both email and instant messaging. 

    # notify admins:
    $c->model('Messaging')->notify( subject=>'Internal Error', message=>'Maybe you want to take a look');

    # notify users
    $c->model('Messaging')->notify(
        subject=>'Job Started',
        message=>'Maybe you want to take a look',
		[ template_type => 'mason|text' ],
        type=> ['email', 'instant']
        to_user=> [qw/U1 U2/],
        to_actions=> [{ ns=>'/application/AAA0001', action=>'action.notify.job.end' }]
    );

    ->notify( subject=>'sss', template=>'job_start.templ', vars=>{ job_name=>'N001101' } );

=cut

# creates a message with no queue
sub create {
    my ($self,%p)=@_;

    my $body = $p{body};
	$p{template_engine} ||= 'text';

    _throw "No subject specified" unless $p{subject};

    # catch onto features
    my @features = map {
        [ $_->id => _dir( $_->root )->stringify ]
    } Baseliner->features->list;
    if( my $template = $p{template} ) {
        if( $p{template_engine} eq 'mason' ) {
            try {
                use File::Spec;
                use HTML::Mason::Interp;
                my $comp_root = [ [ root=>"". Baseliner->config->{root} ], @features ];
				my $data_dir = File::Spec->catdir(
					File::Spec->tmpdir, sprintf('Baseliner_%d_mason_data_dir', $<));
				my $m = HTML::Mason::Interp->new(
					comp_root  => $comp_root,
					data_dir   => $data_dir,
					out_method => \$body,
				);
				$m->exec( "/$template", %p, %{ $p{vars} || {} } );
			} catch {
				_log "Error in Mason Email engine: " . shift;
				_log _whereami;
				$body = _dump( $p{vars} );
			};
		} else {
			$template = Baseliner->path_to('root', $p{template} )
				unless -e $template;
			$body = _parse_template( $template, %{ $p{vars} || {} } );
		}
    }

    $p{sender} ||= _loc('internal');

    my $msg = Baseliner->model('Baseliner::BaliMessage')->create(
        {
            subject => $p{subject},
            body    => $body,
            sender  => $p{sender},
            attach  => $p{attach},
        }
    );
    return $msg;
}

sub delete {
    my ( $self, %p ) = @_;

    my $msg = Baseliner->model('Baseliner::BaliMessage')->find({ id=> $p{id} }) if $p{id} ;
    $msg->delete if ref $msg; 
}

sub read {

}

=head2 notify

Creates a message and puts a notification in the queue. 

  subject => 'about...',
  body => 'body',
  sender  =>  'me',
  attach  => (data)

  carriers => ['email', 'instant', ... ],

Then the destination (users):
    to => {
        users => [ 'A', 'B', ... ],
    },
    cc => { 
        users => [ ... ]
    }

Or to destination actions:

    to => {
      actions => [ .. ],
      ns => [ ... ],    # optional, defaults to /
      bl => [ ... ],    # optional, defaults to *
    },
    cc => {
            ...
    },


=cut
sub notify {
    my ($self,%p)=@_;

    my @carriers = _array( $p{carriers} , $p{carrier} );
	_throw 'Missing carrier' unless @carriers;

    my %users;

    for my $param ( qw/to cc bcc/ ) {
        my $dest = $p{$param};
        next unless ref $dest eq 'HASH';

        _throw 'notify can take either "actions" or "users" but not both'
          if defined $dest->{users} && defined $dest->{actions};

        push @{ $users{$param} }, _array( $dest->{users}, $dest->{user} );

        my @actions = _array( $dest->{actions}, $dest->{action} ); 
        for my $action ( @actions ) {
			_log "Looking for users for action $action";
            my @users = Baseliner->model('Permissions')->list(
                action => $action,
                bl     => ( $dest->{bl} || 'any' ),
                ns     => ( $dest->{ns} || 'any' )
            );
			_log "Found: " . join',',@users;
            push @{ $users{$param} }, @users; 
        }
    }

	# create the message
    my $msg = $self->create(%p);

	# create the queue entries
    for my $carrier ( @carriers ) {
        for my $param ( qw/to cc bcc/ ) {
            for my $username ( _array $users{$param} ) {
				_log "Creating message for username=$username, carrier=$carrier";
                $msg->bali_message_queues->create({ username=>$username, carrier=>$carrier, carrier_param=>$param });
				#TODO make TO fields have the full TO list, so users can see who else was notified
            }
        }
    }
    return $msg;
}

sub notify_admin {
    my ($self,%p)=@_;
	my $type = $p{to} ? 'cc' : 'to' ;
	$p{$type} = { action => 'action.notify.admin' };
	$self->notify( %p );
}

=head2 inbox

List all available messages for a given username. 
    
    username => 'me',

By default, only lists active (unread) messages. 

If you are a queue carrier, to list all, set:
    
    all => 1

=cut
sub inbox {
    my ($self,%p)=@_;
    my @messages;

    my $search = {};
    my $opts = $p{sort} ? { order_by => "$p{sort} $p{dir}" } : { order_by => 'id desc' };
    if( defined $p{start} && defined $p{limit} ) {
        $opts->{page} = to_pages( start=>$p{start}, limit=>$p{limit} );
		$opts->{rows} = $p{limit} || 30;
    }

    $search->{active} = 1 unless $p{all};

    exists $p{username} and $search->{username} = delete $p{username} if $p{username};
    exists $p{carrier} and $search->{carrier} = delete $p{carrier};

    $p{query} and $search->{"lower(sender||body||subject)"} = { -like => '%'.lc($p{query}).'%' };
    $opts->{prefetch} = ['id_message']; 
    my $rs = Baseliner->model('Baseliner::BaliMessageQueue')->search($search, $opts );

    while( my $r = $rs->next ) {
        my $message = new Baseliner::Core::Message(
            {
                $r->id_message->get_columns, $r->get_columns,
                id_message => $r->id_message->id
            }
        );
        push @messages, $message;

        if( $p{deliver_now} ) {
            $r->deliver_now;
        }
    }
	my $total = $rs->is_paged ? $rs->pager->total_entries : scalar @messages;
    return { data=>\@messages, total=>$total };
}

sub delivered {
    my ($self,%p)=@_;
    
    my $search = {};
    $p{id} and $search->{id} = $p{id}; 

    my $rs = Baseliner->model('Baseliner::BaliMessageQueue')->search($search);
    while( my $r = $rs->next )  {
        $r->deliver_now;
        $r->update;
    }
}

sub failed {
    my ($self,%p)=@_;
    
    my $search = {};
    my $max_attempts = $p{max_attempts} || 10;  #TODO to config
    $p{id} and $search->{id} = $p{id}; 
    my $rs = Baseliner->model('Baseliner::BaliMessageQueue')->search($search);
    while( my $r = $rs->next )  {
        if( $r->attempts < $max_attempts ) {
            $r->active( 1 );
        } else {
            $r->active( 0 );
        }
        $r->result( $p{result} );
        $r->attempts(  $r->attempts + 1 );
        $r->update;
    }
}

sub get {
    my ($self,%p)=@_;
    my $r = Baseliner->model('Baseliner::BaliMessageQueue')->find({ id=>$p{id} });
    #my $message = new Baseliner::Core::Message({ $r->get_columns, $r->id_message->get_columns });
    return { $r->get_columns, $r->id_message->get_columns } if ref $r;
}

sub has_unread_messages {
    my ( $self, %p ) = @_;

    my $search = {};
    $search->{active} = 1 unless $p{all};
    exists $p{username} and $search->{username} = delete $p{username} if $p{username};
    exists $p{carrier} and $search->{carrier} = delete $p{carrier};

    return Baseliner->model('Baseliner::BaliMessageQueue')->search($search)->count;
}


1;
