=head1 NAME

BaselinerX::Type::Event

=head1 DESCRIPTION

This is the registry type for system-wide events.

Use C<Baseliner::Sugar> to get the event functions into your package.

Usage:

    use Baseliner::Sugar;

    register 'event.topic.delete' => {
        text => 'user %1 delete my topic %2',
        vars => ['username', 'topic_name']
    };

    event_new 'event.topic.delete' => {
        mid => $mid,                # required: master id of the affected master object
        username => $c->username,   # not required, but useful
        topic_name => 'etc etc',    # this will store anything 
    };

    # now search for events:
    for my $event ( events_by_mid $mid ) {
        say $event->{text} ;   # the full translated event text
        say $event->{topic_name};   # and vars too
    }

=head1 FILTERS

You may define filters to change data before translation:

    register 'event.topic.delete' => {
        text => 'user %1 delete my topic %2',
        vars => ['username', 'topic_name'],
        filter => sub {
            my ($text, @vars ) =@_;
            @vars = map { uc $_ } @vars; # uppercase all vars
            return ( $text, @vars );
        }
    };

=cut
package BaselinerX::Type::Event;
use Baseliner::Plug;
use Baseliner::Utils;
with 'Baseliner::Core::Registrable';

register_class 'event' => __PACKAGE__;

has 'id'=> (is=>'rw', isa=>'Str', default=>'');
has 'text' => ( is=> 'rw', isa=> 'Str', required=>1 );
has 'vars' => ( is=> 'rw', isa=> 'ArrayRef', default=>sub{[]}, lazy=>1 );
has 'filter' => ( is=> 'rw', isa=> 'CodeRef' );
has 'pre' => ( is=> 'rw', isa=> 'CodeRef' );
has 'post' => ( is=> 'rw', isa=> 'CodeRef' );

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

1;

