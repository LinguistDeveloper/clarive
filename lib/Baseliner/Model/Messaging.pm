package Baseliner::Model::Messaging;
use Baseliner::Plug;
extends qw/Catalyst::Model/;
no Moose;
use Baseliner::Utils;
use Baseliner::Sugar;
use Baseliner::Core::Message;
use Try::Tiny;

with 'Baseliner::Role::Service';

register 'action.notify.admin' =>  { name=>'Receive General Admin Messages' };
register 'action.notify.error' =>  { name=>'Receive Error Notifications' };

#     my $to = [ _unique(@users) ];

#     Baseliner->model('Messaging')->notify(
#         to              => { users => $to },
#         subject         => _("SQA Package analysis finished"),
#         sender            => $config->{from},
#         carrier         => 'email',
#         template        => 'email/pkg_analysis_finished.html',
#         template_engine => 'mason',
#         vars            => {
#             subject => "An&aacute;lisis de calidad de paquetes finalizado",
#             message =>
# "Finalizado An&aacute;lisis de calidad de $project solicitado por el usuario $username",
#             project  => $project,
#             username => $username,
#             packages => $packages,
#             links    => $links,
#             url      => $url,
#             to       => $to
#         }
#     );

register 'service.notify.create' => {
    name => 'Send a Notification',
    form => '/forms/notify_create.js',
    #migrar 
    handler=>sub{
        my ($self, $c, $config) = @_;

        my $to = $config->{to};
        my $cc = $config->{cc};

        my $template = config_get('config.comm.email')->{default_template};
#        $config->{url} = config_get('config.comm.email')->{baseliner_url};

        my @users;

        for ( _array $to ) {
            if ( $_ =~ /role\/(.*)/ ) {
                push @users,  map { $_->{username} } ci->user->find({ "project_security.$1"=>{'$exists'=>1 } })->all;
            } elsif ( $_ =~ /user\/(.*)/ ) {
                my $user = ci->new($1);
                push @users, $user->{username};
            } else {
                push @users, $_;
            }
        }

        my $final_to = [ _unique(@users) ];

        @users = ();
        for ( _array $cc ) {
            if ( $_ =~ /role\/(.*)/ ) {
                push @users,  map { $_->{username} } ci->user->find({ "project_security.$1"=>{'$exists'=>1 } })->all;
            } elsif ( $_ =~ /user\/(.*)/ ) {
                my $user = ci->new($1);
                push @users, $user->{username};
            } else {
                push @users, $_;
            }
        }

        my $final_cc = [ _unique(@users) ];

        Baseliner->model('Messaging')->notify( 
            to => { users => $final_to },
            cc => { users => $final_cc },
            template        => $template,
            template_engine => 'mason',            
            subject => $config->{subject},
            carrier => 'email',
            vars => {
                msg => $config->{body},
                subject => $config->{subject},
                to => $final_to,
                cc => $final_cc
            }
        );
        return { msg_id => 999, config=>$config }; 
    }
};

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
    my $vars = $p{vars} ? $p{vars} : {};
    # merge vars and %p
    my %final_vars = %p;
    delete $final_vars{vars};
    %final_vars = ( %final_vars, %$vars );
    # parse subject
    my $subject = parse_vars( $p{subject}, \%final_vars ); 
    $final_vars{subject} = $subject;

    if( my $template = $p{template} ) {
        $template = "/$template";
        if( $p{template_engine} eq 'mason' ) {
            try {
                $body = Util->_mason( $template, %final_vars );
            } catch {
                my $err = shift;
                _log "Error in Mason Email engine: $err";
                _log _whereami;
                $body = _loc('Email error. Email contents: <pre>%1</pre>', _dump($p{vars}) );
                _fail _loc 'Error in message mason template %1: %2', $template, $err
                    if $p{_fail_on_error}; 
            };
        } else {
            $template = Baseliner->path_to('root', $p{template} )
                unless -e $template;
            $body = _parse_template( $template, %final_vars );
        }
    }
    
    $p{sender} ||= _loc('internal');
    my $msg = mdb->message->insert(
        {
            subject => $subject,
            active => '1',
            created => mdb->ts,
            body    => $body,
            sender  => $p{sender},
            attach  => $p{attach},
            schedule_time => $p{schedule_time}
        }
    );
    return $msg;
}

sub delete {
    my ( $self, %p ) = @_;
    my $msg = mdb->message->update(
        {_id => mdb->oid($p{id_message})},
        {'$pull' => 
            {
                queue => {id => 0+$p{id_queue}}
            }
        }
    );
    
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

    if ( $p{sender} ) {
        $p{sender} .='@'.config_get('config.comm.email')->{domain} unless $p{sender} =~ m{@};
    } else {
        $p{sender} = config_get('config.comm.email')->{from};
    }
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
    my $schedule = $p{schedule_time};
    # create the queue entries
    for my $carrier ( @carriers ) {
        for my $param ( qw/to cc bcc/ ) {
            for my $username ( _array $users{$param} ) {
                _log "Creating message for username=$username, carrier=$carrier";
                my $sent;
                if(!$schedule || ($schedule eq '') ){
                    $sent = mdb->ts;
                }
                mdb->message->update(
                    {_id => $msg},
                    {'$push' => 
                        {queue => {
                        	id =>  0 + mdb->seq('message_queue'),
                            username=>$username, 
                            carrier=>$carrier, 
                            carrier_param=>$param, 
                            active => '1',
                            attempts => '0',
                            swreaded => '0',
                            sent => $sent
                        }}
                    }
                );
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

    my %q;
    
    $p{dir} ||= 'DESC';

   	if ($p{sort}){
        if($p{sort} eq 'id' or $p{sort} eq 'sent') {
            $p{sort} = 'queue.'.$p{sort};
        } 

   		if ($p{dir} eq 'DESC') {
   			$q{sort} = {$p{sort} => -1}; 
   		}else{
   			$q{sort} = {$p{sort} => 1};
   		}
   	} else{
   		if ($p{dir} eq 'DESC') {
            $q{sort} = {'queue.id' => -1}; 
        }else{
            $q{sort} = {'queue.id' => 1};
        }
   	}
    
    if( defined $p{start} && defined $p{limit} ) {
		$q{skip} = $p{start};
		$q{limit} = $p{limit} || 30;
	}

    $q{where}->{'queue.active'} = '1' unless $p{all};
    
    exists $p{username} and $q{where}->{'queue.username'} = $p{username} if $p{username};
    exists $p{carrier} and $q{where}->{'queue.carrier'} = delete $p{carrier};

    if($p{query_id}){
        $p{query_id} and $q{where}{_id} = mdb->oid($p{query_id});
    } else {
        $p{query} and $q{where} = mdb->query_build(query => $p{query}, where => $q{where}, fields=>[qw(sender body subject )]);
    }

	my @queue = $self->transform(%q);
	
    my @q;

	foreach my $r (@queue){
    	if($r->{username} eq $p{username}){
    		push @q, $r;
		}
  	}

	foreach my $r (@q){
		my $message = { %{ delete $r->{msg} }, %$r, swreaded => $r->{swreaded}  }; 

        push @messages, $message;

        if( $p{deliver_now} ) {
            mdb->message->update(
    			{'queue.id' => 0 + $r->{id}},
    			{'$set' =>
    				{
    					'queue.$.received' => mdb->ts,
    					'queue.$.active' => '0'
    				}
    			}
    		);
        }
	}
	@messages = map { $_->{_id} .=''; $_ } @messages;

    my $total = $q{limit} ? $q{limit} : scalar @messages;
    return { data=>\@messages, total=>$total };
}

sub delivered {
    my ($self,%p)=@_;

    _fail _loc('Missing id') unless length $p{id};

    $p{where} ={'queue.id' => 0 + $p{id}};
#    my @queue = $self->transform(%p);

    my $act = '0';
    mdb->message->update(
		{'queue.id' => 0 + $p{id}},
		{'$set' =>
			{
				'queue.$.result' => $p{result},
				'queue.$.received' => mdb->ts,
				'queue.$.active' => $act
			}
		},
        { multiple=>1 }
	);
}

sub failed {
    my ($self,%p)=@_;
    
    my $max_attempts = $p{max_attempts} || 10;  #TODO to config
    
    _fail _loc('Missing id') unless length $p{id};

    $p{where} ={'queue.id' => 0 + $p{id}};
    my @queue = $self->transform(%p);
	
	my $r;

	for my $entry (@queue){
	    if ($entry->{id} eq $p{id}){
	         $r = $entry;
	         last;
	    }
	}

	my $act;
	if( $r->{attempts} < $max_attempts ) {
        $act = '1' ;
    } else {
        $act = '0' ;
    }

    my $n_attempts = $r->{attempts} + 1;
    mdb->message->update(
    	{'queue.id' => 0 + $p{id}},
    	{'$set' =>
    		{
    			'queue.$.result' => $p{result}, 
    			'queue.$.active' => $act, 
    			'queue.$.attempts' => ''.$n_attempts
    		}
    	});
}

sub get {
    my ($self,%p)=@_;
    $p{where} ={'queue.id' => 0 + $p{id}}; 
    my @queue = $self->transform(%p);
    my ($row) = @queue;
    my $merged = { %{ delete $row->{msg} }, %$row }; 
    $merged->{_id} .='';
    return $merged if ref $row;
}

sub has_unread_messages {
    my ( $self, %p ) = @_;

    my %search;
    $search{where}->{'queue.active'} = '1' unless $p{all};
    exists $p{username} and $search{where}->{'queue.username'} = delete $p{username} if $p{username};
    exists $p{carrier} and $search{where}->{'queue.carrier'} = delete $p{carrier};

    my @queue = Baseliner->model('Messaging')->transform(%search);

    my @q;
    foreach my $r (@queue){
	if (!$p{all}){
    	if($r->{active} eq '1'){
    		push (@q, $r);
		}
    }else{
    	push (@q, $r);
    }
}

    return scalar @q;
}

sub send_schedule_mail {
    my ( $self, %p ) = @_;
    mdb->message->update(
        {
            _id => $p{msg}->{_id}, 
            'queue.id' => $p{id}
        },
        {'$set' => {'queue.$.sent' => mdb->ts}}
    );
}

sub transform {
	my ($self, %p) = @_;
	my @queue =
	    map {
	        my $msg = $_;
	    	map {
	           $_->{msg} = $msg; 
	           $_
	        } 
	        _array(delete $msg->{queue}) 
	    } 
	   _array($self->mdb_message_query(%p));
    return @queue;
}

sub mdb_message_query {
	my ($self, %p) = @_;
	my $rs = mdb->message->find( $p{where} );
	$rs->sort( $p{sort} ) if $p{sort};
	$rs->skip( $p{skip} ) if $p{skip};
	$rs->limit( $p{limit} ) if $p{limit};
	return $rs->all;
}

1;
