package BaselinerX::Type::Service::Container::Job;
use Baseliner::Moose;

has job_dir => qw(is rw isa Str lazy 1), default => sub { Util->_tmp_dir() };
has job_stash => qw(is rw isa HashRef required 1 weak_ref 1);
has exec      => qw(is rw isa Num default 1);
has bl        => qw(is rw isa Str default TEST);
has step      => qw(is rw isa Str default RUN);
has job_type  => qw(is rw isa Str default promote);
has
  backup_dir => qw(is rw isa Any lazy 1),
  default    => sub {
    my ($self) = @_;
    return '' . Util->_file($self->job_dir, '_backups');
  };

sub logger       { 'BaselinerX::Type::Service::Container::Job::Logger' }
sub back_to_core { }

our $AUTOLOAD;

sub AUTOLOAD {
    shift;
    my $name = $AUTOLOAD;
    Util->_warn("Ignored NoOp Method $name called in Job container.");
}

1;
