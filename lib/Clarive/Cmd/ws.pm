package Clarive::Cmd::ws;
use v5.10;
use Mouse;
extends 'Clarive::Cmd';

our $CAPTION = 'webservices toolchain';

has classname => qw(is ro default *);

with 'Clarive::Role::Baseliner';  # yes, I run baseliner stuff

sub run { goto &run_list }

sub run_list {
    my ($self,%opts) = @_;
    my $r = $self->app->home;
    my $classname = $self->classname;
    
    require Moose;
    require Baseliner::Core::Registry;
    require Baseliner::CI;
    require Baseliner::Role::CI;
    eval "use lib '$_';" for <$r/features/*/lib>; #/
   
    if( $opts{mid} ) {
        require Baseliner;
        $classname = ref Baseliner::CI->new( $opts{mid} ); 
        $classname = ( split /::/, $classname )[-1];
        say "mid classname=$classname";
    }

    for my $f ( <$r/lib/BaselinerX/CI/$classname.pm $r/features/*/lib/BaselinerX/CI/$classname.pm> ) {
        next unless -e $f;
        my $name = [ split '/', $f  ]->[-1];
        $name=~ s/\.pm//g; 
        my $pkg="BaselinerX::CI::$name";
        say "/ci/$name/:";
        require Class::Inspector;
        require $f unless Class::Inspector->loaded( $pkg );
        eval "package $pkg; use namespace::autoclean;";
        #$pkg->meta->get_method_map;
        my @methods = 
            sort 
            grep !/^(super|meta|new|does|has|with)$/,
            grep !/^[A-Z]+$/,
            @{ Class::Inspector->methods( $pkg, 'public' ) || [] };
        say join ", ", @methods;
        say scalar(@methods). " methods found.\n";
    } 
}
1;

=head1 Clarive REST tools

options:
    
    --mid <mid>             list methods available for a given CI
    --classname             list methods for a given CI class

=head1 subcommands:

=head2 list

lists all rest methods available

=cut
