package BaselinerX::Type::Event;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Model::Rules;
with 'Baseliner::Role::Registrable';

register_class 'event' => __PACKAGE__;

has 'id' => ( is => 'rw', isa => 'Str', default => '' );
has 'name' => ( is => 'rw', isa => 'Str', default => sub { shift->key } );
has 'type' => ( is => 'rw', isa => 'Str', default => 'trigger' );
has 'description' => ( is => 'rw', isa => 'Str', default => 'An Event' );
has 'notify' => ( is => 'rw', isa => 'HashRef' ), default =>sub{ {} };
has 'use_semaphore' => ( is => 'rw', isa => 'Bool', default => 1 );
has 'text' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        sprintf "Event %s occurred", $self->key;
    }
);
has 'vars' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] }, lazy => 1 );
has 'filter' => ( is => 'rw', isa => 'CodeRef' );
has level => ( is=>'rw', isa => 'Num', default=>0 );

sub event_text {
    my ($self, $data ) = @_;
    my %data = ref $data ? %$data : ();
    my @vars = @data{ @{ $self->vars } };  # get my keys from vars
    my @all = ( $self->text, @vars ); # prepare them to send to filter
    if( $self->filter ) {
        @all = $self->filter->( @all );
    }
    _loc( @all );
}

sub _hooks {
    my $self = shift;
    my $type = shift or _throw 'Missing hook type';
    my $key = sprintf '%s._hooks', $self->key;
    if( my $hooks = Baseliner::Core::Registry->get_node( $key ) ) {
        return _array $hooks->param->{ $type };
    }
    return ();
}
sub before_hooks { $_[0]->_hooks( 'before' ) }
sub after_hooks { $_[0]->_hooks( 'after' ) }

sub run_rules {
    my ($self, $when, $stash) = @_;

    return Baseliner::Model::Rules->run_rules(
        event         => $self->key,
        when          => $when,
        stash         => $stash,
        rule_type     => 'event',
        simple_error  => 1,
        use_semaphore => $self->use_semaphore
    );
}
sub rules_pre_online { $_[0]->run_rules( 'pre-online', $_[1] ) }
sub rules_post_online { $_[0]->run_rules( 'post-online', $_[1] ) }

no Moose;
__PACKAGE__->meta->make_immutable;

1;
