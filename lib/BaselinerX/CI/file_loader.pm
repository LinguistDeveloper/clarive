package BaselinerX::CI::file_loader;
use Baseliner::Moose;
use Path::Class;
use namespace::clean;

has exclude        => qw(is rw isa Any);
has include        => qw(is rw isa Any);
has dirs           => qw(is rw isa Any);
#has dirs       => qw(is ro isa ArrayRef[Str] required 1);
has_cis components => 'Baseliner::Role::CI::Component';
#has include    => qw(is ro isa ArrayRef), default => sub { [] };
#has exclude    => qw(is ro isa ArrayRef), default => sub { [] };
has is_loaded  => qw(is rw isa Bool default 0);

with 'Baseliner::Role::CI::CCMDB';
with 'Baseliner::Role::CI::Loader';

sub has_bl { 0 }
sub run_load {
    my $self    = shift;
    my $include = $self->include;
    my $exclude = $self->exclude;
    my @components;

    for my $dir ( @{ $self->dirs } ) {
        dir($dir)->recurse(
            callback => sub {
                my $f = shift;
                return if $f->is_dir;
                return if @$include && !grep { $f =~ $_ } @$include;
                return if @$exclude && grep { $f =~ $_ } @$exclude;
                push @components, BaselinerX::CI::Component::File->new( name => $f->basename, path => "$f" );
            }
        );
    }
    $self->components( \@components );
    $self->is_loaded( 1 );
}


1;

