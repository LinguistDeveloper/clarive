#INFORMACIÓN DEL CONTROL DE VERSIONES
#
#	CAM .............................. SCM
#	Pase ............................. N.PROD0000055425
#	Fecha de pase .................... 2011/12/14 17:20:09
#	Ubicación del elemento ........... /SCM/FICHEROS/UNIX/baseliner/lib/Baseliner/Core/JobInfo.pm
#	Versión del elemento ............. 3
#	Propietario de la version ........ q74612x (Q74612X - RICARDO MARTINEZ HERRERA)

package Baseliner::Core::JobInfo;
use Moose;
use YAML;

has 'job' => (is=>'rw', isa=>'Str');
has 'type' => (is=>'rw', isa=>'Str');
has 'bl' => (is=>'rw', isa=>'Str');
has 'path' => (is=>'rw', isa=>'Str');
has 'projects' => (is=>'rw', isa=>'ArrayRef');
has 'user' => (is=>'rw', isa=>'Str');
has 'has_subprojects' => (is=>'rw', isa=>'Bool', default=>0);
has 'status' => (is=>'rw', isa=>'Str');

sub add_subproject {
	my ($self, %p) = @_;
	
	my $project = $p{project};
	my $data = $p{data};

	push @{$self->{projects}->{$project}}, $data;
	$self->has_subprojects(1);
}


sub add_package {
	my ($self, %p) = @_;
	
	my $project = $p{project};
	my $package = $p{package};

	push @{$self->{projects}->{$project}},$package;	
}

sub write_yaml {
	my ($self, $path) = @_;
	open my $ff, '>', $path;
	print $ff Dump{ %$self };
	close $ff;	
}

sub print_yaml {
	my ($self) = @_;
	print Dump { %$self };
}
1;