package Baseliner::Auth::CAS;
use Moose;

use Try::Tiny;
use Authen::CAS::Client;
use Baseliner::Util qw(_error);

has config => qw(is ro isa HashRef required 1);
has cas => is => 'ro', isa => 'Object', builder => '_build_cas', lazy => 1;

sub authenticate {
    my $self = shift;
    my ($ticket) = @_;

    return unless $ticket;

    return try {
        local $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = $self->config->{verify_key} // 1;

        my $r = $self->cas->service_validate( $self->config->{service}, $ticket );

        return $r->user if $r->is_success;

        return;
    } catch {
        my $e = shift;

        _error "Authen::CAS::Client internal error: $e";
    };
}

sub _build_cas {
    my $self = shift;

    return Authen::CAS::Client->new( $self->config->{uri}, fatal => 0 );
}

1;
