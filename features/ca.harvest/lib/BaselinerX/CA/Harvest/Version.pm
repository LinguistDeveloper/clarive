package BaselinerX::CA::Harvest::Version;
use Moose;
use Moose::Util::TypeConstraints;
use Baseliner::Utils;
use Baseliner::Core::DBI;

with 'BaselinerX::Job::Element';

use DateTime;
use DateTime::Format::Strptime;
use Compress::Zlib;

has 'tag' => ( is=>'rw', isa=>'Str' );
has 'data_size' => ( is=>'rw', isa=>'Int' );
has 'package' => ( is=>'rw', isa=>'Str' );
has 'creator' => ( is=>'rw', isa=>'Any' );
has 'modifier' => ( is=>'rw', isa=>'Str' );

has 'modified_file' => ( is=>'rw', isa=>'Any' );
has 'modified_on' => ( is=>'rw', isa=>'Any');
has 'created_on' => ( is=>'rw', isa=>'Any');

has 'versiondataobjid' => ( is=>'rw', isa=>'Any');
has 'compressed' => ( is=>'rw', isa=>'Bool');
has 'fullpath' => ( is=>'rw', isa=>'Any');
has 'is_dir' => ( is=>'rw', isa=>'Bool');
has 'extension' => ( is=>'rw', isa=>'Any');
has 'action' => ( is=>'rw', isa=>'Any');

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %args = @_ == 1 && ref $_[0] ? %{ $_[0] } : @_;
    my $key_map = {
        modifiedtime  => 'modified_on',
        modifytime    => 'modified_file',
        mappedversion => 'version',
        itemname      => 'name',
        username      => 'creator',
        versionstatus => 'tag',
        datasize      => 'data_size',
        packagename   => 'package',
    };
    %args = map {
        my $key = $_;
        my $value = $args{ $key };
        my $new_key = $key_map->{ $key } || $key; 
        $new_key => $value;
    } grep { defined } keys %args;
    $args{ mask } = '/application/nature/project'; #TODO from a config 'harvest.repo.mask'
    $args{ created_on } = $args{ modified_on };
    $args{ modifier } = $args{ creator };
    $args{ compressed } = $args{ compressed } =~ /Y/i ? 1 : 0;
    $args{ is_dir } = not $args{ itemtype };
    return $class->$orig( \%args );
};

sub date {
    my $self = shift;
	my $datename = shift;
	$datename or _throw 'Missing datename parameter: modified_on, modified_file, created_on';
	my $parser = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d %H:%M', time_zone =>  Baseliner->config->{time_zone} );
	return $parser->parse_datetime( $self->{ $datename } );
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

sub checkout {
use utf8;

    my $self = shift;
    my %p = @_;
    #_log _dump %p;
    my $db = Baseliner::Core::DBI->new( model=>'Harvest' );
    my $ret = {};
    # retrieve file contents
    my $data = $db->value(q{select versiondata from harversiondata where versiondataobjid = ?}, $self->versiondataobjid );
    my $final_path = Path::Class::dir( $p{path}, $self->path );
    my $file_path = Path::Class::file( $p{path}, $self->fullpath );

    Encode::from_to( $final_path, 'iso8859-1', 'utf8' );
    Encode::from_to( $final_path, 'utf8', 'iso8859-1' );
    Encode::from_to( $final_path, 'utf8', 'iso8859-1' );

    Encode::from_to( $file_path, 'iso8859-1', 'utf8' );
    Encode::from_to( $file_path, 'utf8', 'iso8859-1' );
    Encode::from_to( $file_path, 'utf8', 'iso8859-1' );

    _mkpath $final_path;
    #warn "P ==> " . $final_path . " (is_dir=" . $self->is_dir . ")";
    return if $self->is_dir;
    _debug "F ==> " . $file_path . " (is_dir=" . $self->is_dir . ")";
    # write file
    open my $ff, '>', $file_path or _throw _loc("Could not open file '%1' for writing", $file_path);
    if( $self->compressed ) {
        $data = uncompress($data);
    }
    if( $p{sed} ) {
        $ret->{sed_found} = eval q{$data=~} . $p{sed};
    }
    print $ff $data;
    close $ff;
    # set file time
    my $mtime = $self->date( 'modified_file' );
    if( $mtime ) {
        $mtime = $mtime->epoch;
        utime $mtime, $mtime, $file_path; 
    }
    return $ret;
}

1;

