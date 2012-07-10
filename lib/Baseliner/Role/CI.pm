package Baseliner::Role::CI;
use Moose::Role;

use Moose::Util::TypeConstraints;

subtype CI => as 'Baseliner::Role::CI';
coerce 'CI' =>
  from 'Num' => via { Baseliner::CI->new( $_ ) }; 

has mid => qw(is rw isa Num);

sub icon_class { '/static/images/ci/class.gif' }
requires 'icon';
requires 'collection';

has job     => qw(is rw isa Baseliner::Role::JobRunner),
    lazy    => 1,
    default => sub {
        require Baseliner::Core::JobRunner;
        Baseliner::Core::JobRunner->new;
    };

# from Node
has uri      => qw(is rw isa Str);   # maybe a URI someday...
has resource => qw(is rw isa Baseliner::CI::URI), 
                handles => qr/.*/;

has debug => qw(is rw isa Bool), default=>sub { $ENV{BASELINER_DEBUG} };


1;

