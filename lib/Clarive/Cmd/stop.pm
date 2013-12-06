package Clarive::Cmd::stop;
use Mouse;
use Try::Tiny;

extends 'Clarive::Cmd::web';
our $CAPTION = 'stop all server tasks';

sub run {
	my ($self,%opts) = @_;

	print "Stopping mongo server\n";
	system('killall mongod');
	if ( $? ) {
		print "Error stopping mongo server\n";
		exit 1;
	}
	print "Mongo server stopped\n";

	if ( !$opts{no_redis} ) {
		print "Stopping Redis server\n";
		system('killall redis-server');
		if ( $? ) {
			print "Error stopping Redis server\n";
			exit 1;
		}
		print "Redis server stopped\n";
	}

	if ( !$opts{no_nginx} ) {
		print "Stopping nginx server\n";
		system('nginx -s stop');
		if ( $? ) {
			print "Error stopping nginx server\n";
			exit 1;
		}
		print "Nginx server stopped\n";
	}	

	#Stop Clarive web interface
	try {
		print "Stopping Clarive web server\n";
		my $app_web = Clarive::App->new( %opts );
		$app_web->do_cmd( cmd=>'web-stop' );
		print "Clarive web server stopped\n";
	} catch {
		print "Error stopping Clarive web server\n";
	};

	#Stop Clarive dispatcher
	try {
		print "Stopping Clarive dispatcher\n";
		my $app_disp = Clarive::App->new( %opts );
		$app_disp->do_cmd( cmd=>'disp-stop' );
		print "Clarive dispatcher stopped\n";
	} catch {
		print "Error stopping Clarive dispatcher\n";
	};

}

1;
