package BaselinerX::CA::Harvest::CLI::Version;
use Moose;
use Moose::Util::TypeConstraints;
use Baseliner::Utils;

with 'BaselinerX::Job::Element';

use DateTime;
use DateTime::Format::Strptime;

#subtype 'Harvest::CLI::Type::DateTime' => as class_type('Str'); # used to be DateTime
#coerce 'Harvest::CLI::Type::DateTime'
        #=> from 'Str'
        #=> via { 
            #my $parser = DateTime::Format::Strptime->new( pattern => '%m-%d-%Y;%H:%M:%S' );
            #return "".$parser->parse_datetime( $_ ); # stringify
        #};
has 'tag' => ( is=>'rw', isa=>'Str' );
has 'data_size' => ( is=>'rw', isa=>'Any' );
has 'package' => ( is=>'rw', isa=>'Str' );
has 'creator' => ( is=>'rw', isa=>'Str' );
has 'modifier' => ( is=>'rw', isa=>'Str' );

has 'modified_file' => ( is=>'rw', isa=>'Str' );
has 'modified_on' => ( is=>'rw', isa=>'Str' );
has 'created_on' => ( is=>'rw', isa=>'Str' );

sub date {
    my $self = shift;
	my $datename = shift;
	$datename or _throw 'Missing datename parameter: modified_on, modified_file, created_on';
	my $parser = DateTime::Format::Strptime->new( pattern => '%m-%d-%Y;%H:%M:%S' );
	return $parser->parse_datetime( $datename );
}

sub item {
    my $self = shift;
    return File::Spec::Unix->catfile( $self->path, $self->name );
}

sub subapplication {
    my $self = shift;
    my $sa = $self->path_part('project');
    if( $sa ne uc($sa) ) { ## ignore uppercase projects
        #$sa =~s{_*[A-Z|_]+$}{};
        $sa =~s{\.\w+$}{};
    }
    return $sa;
}

sub renamed_from {
    my $self = shift;
	my $hardb = BaselinerX::CA::Harvest::DB->new;
	$hardb->renamed_from( path=>$self->path, version=>$self->version ); 
}

1;
