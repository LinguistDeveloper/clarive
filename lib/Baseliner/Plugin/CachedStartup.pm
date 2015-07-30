package Baseliner::Plugin::CachedStartup;
use Moose;

around 'locate_components' => sub {
      my $orig = shift;
      my $self = shift;
      use File::Slurp;
      if( -e 'components.dmp' ) {
        print "Loading Components from file...\n";
        my $f = read_file( 'components.dmp' );
        return @{ YAML::Syck::Load($f) || []  };
      }
      my @comps =  $self->$orig(@_);
      write_file( 'components.dmp', YAML::Syck::Dump(\@comps) );
      return @comps;
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
