package BaselinerX::CI::UserGroup;
use Baseliner::Moose;

with 'Baseliner::Role::CI::Internal';
with 'Baseliner::Role::CI::Group';

use Baseliner::Utils qw(_array _fail _unique _loc);

has project_security => qw(is rw isa Any), default => sub { +{} };
has groupname => qw(is rw isa Any);

before save => sub {
    my ( $self, $master_row, $data ) = @_;

    $self->groupname( $self->name );
};

sub icon {
    return '/static/images/icons/users.svg';
}

sub set_users {
    my $self = shift;
    my (@users) = @_;

    my @current_users = $self->users();

    for my $user (@users) {
        if ( ref($user) ne 'BaselinerX::CI::User' ) {
            $user = ci->new($user) or _fail( _loc( 'User %1 does not exist', $user ) );
        }

        my @groups = _array( $user->groups );

        push @groups, $self;

        $user->groups( \@groups );
        $user->save;

        @current_users = grep { $_->mid ne $user->mid } @current_users;
    }

    for my $user (@current_users) {
        my @groups = _array( $user->groups );

        @groups = grep { $_->mid ne $self->mid } @groups;

        $user->groups( \@groups );
        $user->save;
    }

    return @current_users;
}

sub gen_project_security {
    my $self = shift;
    my ( $projects, $roles ) = @_;

    if ( ref $self ) {
        my @colls = map { Baseliner::Utils::to_base_class($_) }
          Baseliner::Utils::packages_that_do('Baseliner::Role::CI::Project');

        my $security = {};

        for my $role ( Baseliner::Utils::_array($roles) ) {
            for ( Baseliner::Utils::_array($projects) ) {
                if ( $_ eq 'todos' ) {
                    foreach my $col (@colls) {
                        my @tmp = map { $_->{mid} } ci->$col->search_cis;

                        push @{ $security->{$role}->{$col} }, @tmp;
                    }
                    last;
                }
                my $ci  = ci->new($_);
                my $col = Baseliner::Utils::to_base_class( ref $ci );

                push @{ $security->{$role}->{$col} }, $_;
            }
        }
        my $old_project_security = $self->{project_security};

        foreach my $r ( Baseliner::Utils::_array $roles) {
            foreach my $c ( keys %{ $security->{$r} } ) {
                foreach my $p ( _array $security->{$r}->{$c} ) {
                    push @{ $old_project_security->{$r}->{$c} }, $p;
                }

                @{ $old_project_security->{$r}->{$c} } =
                  _unique @{ $old_project_security->{$r}->{$c} };
            }
        }
        $self->project_security($old_project_security);
    }

    return $self;
}

sub users {
    my $self = shift;

    return $self->children( where => { collection => 'user' } );
}

1;
