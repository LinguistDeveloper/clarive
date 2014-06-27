package Baseliner::View::Mason;
use strict;
use warnings;
use base 'CatalystX::Features::View::Mason';

__PACKAGE__->config(use_match => 0);

# put something more than the UID ($<) in the folder. 
#   the parentpid is usually given by the shell

if( Clarive->debug ) {
my $ppid = getppid;
$ppid < 2 and $ppid = $$;

__PACKAGE__->config( data_dir =>
        File::Spec->catdir( $ENV{BASELINER_TEMP},'mason', sprintf('%s_%d_%d_mason_data_dir', 'Baseliner', $<, $ppid ) )
    );
}

=head1 NAME

Baseliner::View::Mason - Mason View Component

=head1 SYNOPSIS

    Very simple to use

=head1 DESCRIPTION

Very nice component.

=head1 AUTHOR

Clever guy

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
