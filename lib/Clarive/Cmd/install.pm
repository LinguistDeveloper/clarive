package Clarive::Cmd::install;
use Mouse;
extends 'Clarive::Cmd';
use v5.10;
use Path::Class;

our $CAPTION = 'config file generator';

with 'Clarive::Role::EnvRequired';

sub run {
    my ($self, %opts)=@_;
    
    say "Clarive installation procedure.";
    $self->run_conf( %opts ) if $self->_ask_me( msg=>'Do you want to install a custom config file for your environment? (highly recommended)', yn=>1 );
    $self->run_profile( %opts ) if $self->_ask_me( msg=>'Do you want to install a clarive-profile file?', yn=>1 );
}

sub run_conf {
    my ($self, %opts)=@_;
    my $f = file( $opts{template} // (  $self->home, 'config', 'clarive.yml.template' ) );
    -e $f or die "ERROR: template file not found: $f";
    my $dest_file = file( $self->home, '/config', $f->basename );
    $dest_file =~ s{\.template}{}g;
    my $env = $self->env;
    $dest_file =~ s{clarive\.yml}{$env\.yml}g;
    $self->install_from_template( $f, $dest_file );
}

sub run_profile {
    my ($self, %opts)=@_;
    my $f = file( $opts{template} // $self->home, 'config', 'clarive-profile.template' );
    -e $f or die "ERROR: template file not found: $f";
    my $dest_dir = dir( $self->home, '..' )->resolve;
    my $dest_file = file( $dest_dir, $f->basename );
    $dest_file =~ s{\.template}{}g;
    $self->install_from_template( $f, $dest_file );
    say "
To load this file into your evnironment at startup, try putting the following 
line in your .profile or .bashrc:

        source $dest_dir/clarive-profile

    ";
}

sub install_from_template {
    my ($self, $f, $dest_file )=@_;
    say "Installing $f to $dest_file\nHit <ENTER> to accept default answers.";
    my $d = $f->slurp;
    my @vars = $d =~ m/\[\[(.*?)\]\]/gs;
    my @var_names = map { [ split /:/, $_ ]->[0] } @vars;
    my %vars;
    for( @vars ) {
        my ($var,$default,$desc, $valid, $transform ) = split /:/, $_;
        $vars{$var} = { default => $default, desc => $desc, valid => $valid, transform => $transform }
            unless exists $vars{$var};
    }
    for my $var ( @var_names ) {
        my $vv = $vars{ $var };
        next if exists $vv->{value};

        TOP:
        my $desc = $vv->{desc};
        $desc = length $desc ? "\n--------------| $var |--------------\n".eval("\"$desc\"")."\n" : '';
        
        my $default = length $vv->{default} ? eval( $vv->{default}  ) : '';
        my $default_msg = length $default ? " [$default]" : '';
        my $v = $self->_ask_me( msg=> "$desc$var$default_msg: " ); 
        # trim
        $v =~ s/^\s+//g;
        $v =~ s/\s+$//g;
        # validate
        $vv->{valid} and ( $v =~ $v->{valid} or say "*** Invalid value. Try again.", goto TOP );
        # transform
        $vv->{transform} and do{ $v = eval( $vv->{transform} ) };
        
        $vv->{value} = length $v ? $v : $default;
    }
    
    # now replace
    for my $var ( keys %vars ) {
        my $value = $vars{$var}{value};
        $value='' unless defined $value;
        $d =~ s{\[\[$var:?(.*?)\]\]}{$value}sg;
    }
    
    say $d;
    
    if( -e $dest_file ) {
        my $yn = $self->_ask_me( msg=>"Destination file already exists. Overwrite?", yn=>1 );
        exit 1 unless $yn;
    }

    open my $ff, '>:encoding(utf-8)', $dest_file or die $!;
    print $ff $d;
    close $ff;
    say "file $dest_file written successfully.";
}

sub _ask_me {
    my ($self, %p) = @_;

    require Term::ReadKey;
    # flush keystrokes
    while( defined( my $key = Term::ReadKey::ReadKey(-1) ) ) {}

    if( $p{yn} ) {
        print $p{msg};
        print " [y/N/q]: ";
        #print "*** Are you sure? [y/N/q]: ";
        unless( (my $yn = <STDIN>) =~ /^y/i ) {
            exit 1 if $yn =~ /q/i; # quit
            return 0;
        }
        return 1;
    } else {
        print $p{msg};
        my $v = <STDIN>;
        chomp $v;
        return $v;
    }
}

1;

=head1 Clarive Installer

Tools for installing clarive in your server.

=head2 install-conf

Installs the conf file.

    cla install-conf --env <env>

=head2 install-profile

Install a UNIX profile.

    cla install-conf --env <env>

=head2 install

Runs all install commands. Roughly equivalent to:

    cla install-conf
    cla install-profile

=cut


