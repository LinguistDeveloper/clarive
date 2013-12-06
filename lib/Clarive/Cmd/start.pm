package Clarive::Cmd::start;
use Mouse;
use Try::Tiny;

extends 'Clarive::Cmd::web';
our $CAPTION = 'start all server tasks';

sub run {
	my ($self,%opts) = @_;

	print "Starting mongo server\n";
	system('mongod -f '.$self->app->base.'/config/mongod.conf');
	if ( $? ) {
		print "Error starting mongo server\n";
		exit 1;
	}
	print "Mongo server started\n";

	if ( !$opts{no_redis} ) {	
		print "Starting Redis server\n";
		system('redis-server',$self->app->base.'/config/redis.conf');
		if ( $? ) {
			print "Error starting Redis server\n";
			exit 1;
		}
		print "Redis server started\n";
	}

	if ( !$opts{no_nginx} ) {
		print "Starting nginx server\n";
		system('nginx');
		if ( $? ) {
			print "Error starting nginx server\n";
			exit 1;
		}
		print "Nginx server started\n";
	}
	
	#Start Clarive web interface
	try {
		print "Starting Clarive web server\n";
		my $app_web = Clarive::App->new( daemon=>1, %opts );
		$app_web->do_cmd( cmd=>'web-start' );
		print "Clarive web server started\n";
	} catch {
		print "Error starting Clarive web server\n";
	};

	#Start Clarive dispatcher
	try {
		print "Starting Clarive dispatcher\n";
		my $app_disp = Clarive::App->new( daemon=>1, %opts );
		$app_disp->do_cmd( cmd=>'disp-start' );
		print "Clarive dispatcher started\n";
	} catch {
		print "Error starting Clarive dispatcher\n";
	};

}

1;
