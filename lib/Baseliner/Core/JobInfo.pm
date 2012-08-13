package Baseliner::Core::JobInfo;
use Moose;
use YAML;

has 'job' => (is=>'rw', isa=>'Str');
has 'type' => (is=>'rw', isa=>'Str');
has 'bl' => (is=>'rw', isa=>'Str');
has 'path' => (is=>'rw', isa=>'Str');
has 'projects' => (is=>'rw', isa=>'ArrayRef');
has 'user' => (is=>'rw', isa=>'Str');

sub add_subproject {
    my ($self, %p) = @_;
    
    my $project = $p{project};
    my $data = $p{data};

    push @{$self->{projects}->{$project}}, $data;
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