package BaselinerX::Type::Dashboard;
use Baseliner::Plug;
use Baseliner::Utils;

with 'Baseliner::Core::Registrable';

register_class 'dashboard' => __PACKAGE__;

has 'id'     => ( is => 'rw', isa => 'Str', default => '' );
has 'url'    => ( is => 'rw', isa => 'Str', required=>1);
has 'html'    => ( is => 'rw', isa => 'Str', required=>1 );
has 'order'  => ( is => 'rw', isa => 'Int', default => 0 );

has 'name'   => ( is => 'rw', isa => 'Str' );
has 'column' => ( is => 'rw', isa => 'Int', default => 0 );
has 'active' => ( is => 'rw', isa => 'Bool', default => 1 );

1;


