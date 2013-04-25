package Clarive::Cmd::broker;

our $CAPTION = 'mojo broker';

sub run {
    use Mojolicious::Lite;
    use DateTime;
    use JSON::XS;
    use Mojo::JSON;
    #use Text::Textile qw(textile);
    #use Baseliner;

    get '/' => 'index';

    my $clients = {};
    my $chats = {};

    websocket '/connect' => sub {
        my $self = shift;

        app->log->debug(sprintf '***** Client connected: %s', $self->tx);
        Mojo::IOLoop->stream($self->tx->connection)->timeout(300);  # 5 minutes
        my $id = sprintf "%s", $self->tx;
        $clients->{$id} = $self->tx;

        $self->on(message =>
            sub {
                my ($self, $msg) = @_;
                #my $json = Mojo::JSON->new;
                my $json = JSON::XS->new;
                my $data = $json->decode( $msg );
                my $dt   = DateTime->now( time_zone => 'Europe/Madrid');

                my $text = $data->{msg};
                app->log->debug( $text );
                $text =~ s{[\n|\r]$}{}s;
                $text =~ s{\n|\r}{<br />}gs;
                $text =~ s{\*(.+)\*}{<strong>$1</strong>}gs;
                #$text = textile( $text );

                app->log->debug( 'text: ' . $text );

                for (keys %$clients) {
                    $clients->{$_}->send(
                        $json->encode({
                            username => $data->{username},
                            hms  => $dt->hms,
                            text => $text,
                        })
                    );
                }
            }
        );

        $self->on(finish =>
            sub {
                app->log->debug('Client disconnected');
                delete $clients->{$id};
            }
        );
    };

    app->start;
}

__DATA__
@@ index.html.ep
<html>
  <head>
    <title>WebSocket Client</title>
    <script
      type="text/javascript"
      src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"
    ></script>
    <!-- script type="text/javascript" src="/js/ws.js"></script -->
    <style type="text/css">
      textarea {
          width: 40em;
          height:10em;
      }
    </style>
  </head>
<body>

<h1>Mojolicious + WebSocket</h1>

<p><input type="text" id="msg" /></p>
<textarea id="log" readonly></textarea>

</body>
<script>
   $(function () {
      $('#msg').focus();

      var log = function (text) {
        $('#log').val( $('#log').val() + text + "\n");
      };

      var ws = new WebSocket('ws://localhost:8787/echo');
      ws.onopen = function () {
        log('Connection opened');
      };

      ws.onmessage = function (msg) {
        var res = JSON.parse(msg.data);
        log('[' + res.hms + '] ' + res.text);
      };

    $('#msg').keydown(function (e) {
        if (e.keyCode == 13 && $('#msg').val()) {
            ws.send($('#msg').val());
            $('#msg').val('');
        }
      });
    });

</script>
</html>

