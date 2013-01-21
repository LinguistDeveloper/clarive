package BaselinerX::Comm::Email;
use Baseliner::Plug;
use Baseliner::Utils;
use Text::Template;
use MIME::Lite;
use Net::SMTP;
use Try::Tiny;
use Compress::Zlib;
use Encode;

with 'Baseliner::Role::Service';

register 'config.comm.email' => {
    name => 'Email configuration',
    metadata => [
        { id=>'frequency', name=>'Email daemon frequency', default=>10 },
        { id=>'server', name=>'Email server', default=>'smtp.example.com' },
        { id=>'from', name=>'Email default sender', default=>'user <user@mailserver>' },
        { id=>'overwrite_from', name=>'Email default sender', default=> 0 },
        { id=>'domain', name=>'Email domain', default=>'exchange.local' },
        { id=>'max_attempts', name=>'Max attempts', default=>10 },
        { id=>'baseliner_url', name=>'Base URL to access baseliner', default=>'http://localhost:3000' },
    ]
};

register 'service.daemon.email' => {
    name => 'Email Daemon',
    config => 'config.comm.email',
    handler => \&daemon,
};

register 'service.email.flush' => {
    name => 'Email Flush Queue Once',
    config => 'config.comm.email',
    handler => \&process_queue,
};

sub daemon {
    my ( $self, $c, $config ) = @_;

    my $frequency = $config->{frequency};
    for( 1..1000 ) {
        $self->process_queue( $c, $config );
        sleep $frequency;
    }
    _log "Email daemon stopping.";
}

# groups the email queue around the same message
sub group_queue {
    my ( $self, $config ) = @_;
    my $rs_queue = Baseliner->model('Baseliner::BaliMessageQueue')->search({ carrier=>'email', active=>1 });
    my %email;
    while( my $queue_item = $rs_queue->next ) {
        my $message = $queue_item->id_message;
        my $id = $message->id ;
        my $from = $message->sender;
        $from = $config->{from} if $from =~ m{^internal} || $config->{overwrite_form};
        $email{ $id } ||= {};

        my $address = $queue_item->destination
            || $self->resolve_address( $queue_item->username );

        my $tocc = $queue_item->carrier_param || 'to';
        push @{ $email{ $id }{ $tocc } }, $address; 
        push @{ $email{ $id }{ id_list } }, $queue_item->id;

        $email{ $id }->{from} ||= $from; # from should be always from the same address
        $email{ $id }->{subject} ||= $message->subject;
        $email{ $id }->{body} ||= $message->body;
        $email{ $id }->{attach} ||= {
            data         => $message->attach,
            content_type => $message->attach_content_type,
            filename     => $message->attach_filename
        };
    }
    return %email;
}
    
# send pending emails
sub process_queue {
use Encode qw( decode_utf8 encode_utf8 is_utf8 );
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
        my $override_message='</body>';
        my @to = _array $em->{to};
        my @cc = _array $em->{cc};
        my $from = $config->{overwrite_from} ? $config->{from} : $em->{from};
        if( @email_override ) {
            my $override_edited=join("<LI>",@email_override);
            my $original_edited=join("<LI>",_array $em->{to});

            $override_message = '<TABLE cellpadding="0" cellspacing="0" width="100%"><TR><TH ALIGN="LEFT" COLSPAN=2 class="backGroundFilaDatos">'._loc('Email override').'</TH></TR><TD class="backGroundFilaDatos">'._loc('Email redirected to').'</TD><TD><UL><LI>'.$override_edited.'</UL></TD></TR><TR><TD class="backGroundFilaDatos">'._loc('Original distribution list').'</TD><TD><UL><LI>'.$original_edited.'</UL></TD></TR></TABLE></body>';

            @to=@email_override;
            @cc=();
        } 
        if( @email_cc ) {
            push @cc, @email_cc;
        }
        try {
            my $subject = $em->{subject};
            my $body = $em->{body};

            $body = encode("iso-8859-15", $body);
            $body =~ s{Ã\?}{Ñ}g;
            $body =~ s{Ã±}{ñ}g;

            $body=~s{</body>}{$override_message}ig; 

            utf8::downgrade($body);

             #_log $body;

            $result = $self->send(
                server=>$config->{server},
                to => join(';',@to),
                cc => join(';',@cc),
                body => $body,
                subject => $subject,
                from => $from, 
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
    my $config = Baseliner->model('ConfigStore')->get( 'config.comm.email' );
    my $domain = $config->{domain};

    if ($username =~ m{.*<.*>$} ) {
        my $mail=$username;
        $mail=~s{>}{\@$domain>};
    } else {
        return "$username\@$domain";
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
    $subject = '=?ISO-8859-1?Q?' . MIME::Lite::encode_qp( $subject ) ; # Building fa=?ISO-8859-1?Q?=E7ade?=
    $subject = substr( $subject, 0, length( $subject ) -2 ) . '?=';
    
    my $server=$p{server} || "localhost";
    
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

    foreach my $attach (@attach) {
        _throw "Error: attachment is not a hash but a $attach" unless ref $attach eq 'HASH';
        next unless $attach->{data} && length($attach->{data}) > 0;
        unless( $attach->{content_type} ) {
            $attach->{content_type} = 'application/x-gzip';
            $attach->{data} = compress( $attach->{data} );
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

1;

