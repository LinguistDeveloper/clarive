package Baseliner::Comm::Email;
use Baseliner::Plug;
use Baseliner::Utils;
use MIME::Lite;
use Try::Tiny;
use Encode qw( encode decode_utf8 encode_utf8 is_utf8 );

with 'Baseliner::Role::Service';

sub daemon {
    my ( $self, $c, $config ) = @_;

    my $frequency = $config->{frequency};
    _log _loc "Email daemon started with frequency %1, timeout %2, max_message_size %3", @{ $config }{ qw/frequency timeout max_message_size/ };
    for( 1..1000 ) {
        $self->process_queue( $c, $config );
        sleep $frequency;
    }
    _log "Email daemon stopping.";
}

# groups the email queue around the same message
sub group_queue {
    my ( $self, $config ) = @_;
    
    my %query;

    $query{where}->{'queue.active'} = '1';
    $query{where}->{'queue.carrier'} = 'email';

    my @queue = Baseliner->model('Messaging')->transform(%query);

    my @q = $self->filter_queue(@queue);

    my %email;
    foreach my $queue_item (@q){
        try {
            local $SIG{ALRM} = sub { die "alarm\n" };
            alarm $config->{timeout} if $config->{timeout};  # 0 turns off timeout
            my $message = $queue_item->{msg};
            my $id = $message->{_id} ;
            my $from = $message->{sender};
            my $msgsiz = length( $message->{body} ) // 0;
            my $body;
            if( $msgsiz > $config->{max_message_size} ) {
                _log _loc "Trimming email message body, size exceeded ( %1 > %2 )", $msgsiz, $config->{max_message_size};
                $body = substr( $message->{body}, 0, $config->{max_message_size} ); 
            } else {
                $body = $message->{body};
            }
            $from = $config->{from} if $from eq 'internal';
            $email{ $id } ||= {};

            my $address = $queue_item->{destination} || $self->resolve_address( $queue_item->{username} );

            my $tocc = $queue_item->{carrier_param} || 'to';
            push @{ $email{ $id }{ $tocc } }, $address; 
            push @{ $email{ $id }{ id_list } }, $queue_item->{id};

            $email{ $id }->{from} ||= $from; # from should be always from the same address
            $email{ $id }->{subject} ||= $message->{subject};
            $email{ $id }->{body} ||= $body;
            $email{ $id }->{attach} ||= {
                data         => $message->{attach},
                content_type => $message->{attach_content_type},
                filename     => $message->{attach_filename}
            };
            alarm 0;
        }
        catch {
            my $err = shift;    
            alarm 0;
            _error _loc "MessageQueue item id %1 could not be prepared: %2", $queue_item->{id}, $err; 
            mdb->message->update(
                {'queue.id' => 0 + $queue_item->{id}},
                {'$set' => {'queue.$.active' => '0'}}
            );
        }
    }
    return %email;
}
    
# send pending emails
sub process_queue {
    my ( $self, $c, $config ) = @_;
    
    my %email = $self->group_queue($config); 

    # no to or cc, just these:
    my $email_override = $c->config->{email_override};
    my @email_override = _unique grep $_,_array( $email_override );
    _debug _loc "ALL EMAILS redirected to '%1' (email_override)",
        join(',',@email_override) if @email_override;

    # add these to the cc array
    my $email_cc = $c->config->{email_cc};
    my @email_cc = _unique grep $_, _array( $email_cc );
    _debug _loc "CC EMAILS added: '%1' (email_cc)",
        join(',',@email_cc) if @email_cc;

    # first group by message 
    for my $msg_id ( keys %email ) {
        my $em = $email{ $msg_id }; 
        _debug "Sending email '$em->{subject}' (id=$msg_id) to " . join( ',',
          _array( $em->{to} ) ) . " and cc " . join( ',', _array( $em->{cc} ) );

        my $result;
        my @to = _array $em->{to};
        my @cc = _array $em->{cc};
        if( @email_override ) {
            @to=@email_override;
            @cc=();
        } 
        if( @email_cc ) {
            push @cc, @email_cc;
        }
        try {
            my $subject = $em->{subject};
            my $body = $em->{body};

            $body = Encode::encode("iso-8859-15", $body);
            # _log $body;
            $body =~ s{Ã\?}{Ñ}g;
            $body =~ s{Ã±}{ñ}g;
            
            utf8::downgrade($body);
            $result = $self->send(
                server=>$config->{server},
                to => join(';',@to),
                cc => join(';',@cc),
                body => $body,
                subject => $subject,
                from => $em->{from},
                attach => [ $em->{attach} ],
            );
            # need to deactivate the message before sending it
            for my $id ( _array $em->{id_list} ) {
                Baseliner->model('Messaging')->delivered( id=>$id, result=>$result );
            }

        } catch {
            my $error = shift;
            for my $id ( _array $em->{id_list} ) {
                Baseliner->model('Messaging')->failed( id=>$id, result=>$error, max_attempts=>$config->{max_attempts} );
            }
        };
    }
}

sub resolve_address {
    my ( $self, $username ) = @_;

    my $row= DB->BaliUser->search( {username => $username} )->first;
    my $email="";
    if ( $row )  {
      $email = $row->email;
    }

    if ( $email ) {
        return $email;
    } else {
        if ( $username =~ /\@/ ) {
            return $username;
        } else {        
            my $config = Baseliner->model('ConfigStore')->get( 'config.comm.email' );
            my $domain = $config->{domain};
            return "$username\@$domain";        
        }
    }
}

sub send {
    my ( $self, %p ) = @_;

    my $from = $p{from};
    my $subject = $p{subject};
    my @to = _array $p{to} ;
    my @cc = _array $p{cc} ;
    my $body = $p{body};
    my $content_type = $p{content_type};
    my @attach = _array $p{attach};

    # take out accents
    #use Text::Unaccent::PurePerl qw/unac_string/;
    #$subject = unac_string( $subject );
    $subject = '=?ISO-8859-1?Q?' . MIME::Lite::encode_qp($subject,''); # Building fa=?ISO-8859-1?Q?=E7ade?=
    $subject = substr( $subject, 0, length( $subject ) ) . '?=';
    
    my $server=$p{server} || "localhost";
    
    require Net::SMTP;
    Net::SMTP->new($server) or _throw "Error al intentar conectarse al servidor SMTP '$server': $!\n";	

    MIME::Lite->send('smtp', $server, Timeout=>60);  ## a veces hay que comentar esta línea

    if( !(@to>0 or @cc>0) ) { ### nadie va a recibir este correo
        _throw "No he podido enviar el correo '$subject'. No hay recipientes en la lista TO o CC.\n";
    }

    # _debug " - Enviando correo (server=$server) '$subject'\nFROM: $p{from}\nTO: @to\nCC: @cc\n";

    my $msg = MIME::Lite->new(
        To        => "@to",
        Cc        => "@cc",
        From      => $from,
        Subject   => $subject,
        Datestamp => 0,
        Type      => 'multipart/mixed'
    );
    
    $msg->attach(
        Data     => $body,
        Type     => 'text/html',
        Encoding => 'base64'
    );

    require Compress::Zlib;
    foreach my $attach (@attach) {
        _throw "Error: attachment is not a hash but a $attach" unless ref $attach eq 'HASH';
        next unless $attach->{data} && length($attach->{data}) > 0;
        unless( $attach->{content_type} ) {
            $attach->{content_type} = 'application/x-gzip';
            $attach->{data} = Compress::Zlib::compress( $attach->{data} );
        }
        $msg->attach(
            Data     => $attach->{data},
            Type     => $attach->{content_type},
            Filename => $attach->{filename},
            Encoding => 'base64'
        );
    }
    
    $msg->send('smtp');  ## put smtp otherwise it uses sendmail
}	

sub filter_queue {
    my ($self, @queue) = @_;
    
    require Time::Piece;
    my $dateformat = "%Y-%m-%d %H:%M:%S";

    my $now = Time::Piece->strptime(mdb->ts, $dateformat);
    my @q;
    foreach my $r (@queue){
        if($r->{active} eq '1' ){
            if(!$r->{msg}->{schedule_time} || ($r->{msg}->{schedule_time} eq '') ){
                push (@q, $r);
            }else{
                my $schedule_time = Time::Piece->strptime($r->{msg}->{schedule_time}, $dateformat);    
                if ($schedule_time lt $now) {
                    Baseliner->model('Messaging')->send_schedule_mail(%$r);
                    push (@q, $r);
                }
            }
        }
    }

    return @q;
}

1;

