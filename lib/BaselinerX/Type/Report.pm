package BaselinerX::Type::Report;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;

with 'Baseliner::Role::Registrable';

register_class 'report' => __PACKAGE__;
sub service_noun { 'report' }

has id             => ( is => 'rw', isa => 'Str', default => '' );
has name           => ( is => 'rw', isa => 'Str' );
has meta_handler   => ( is => 'rw', isa => 'CodeRef', required=>1 );
has data_handler   => ( is => 'rw', isa => 'CodeRef', required=>1 );
has security_handler   => ( is => 'rw', isa => 'CodeRef' );
has type           => ( is => 'rw', isa => 'Str', default => 'topic' );
has url            => ( is => 'rw', isa => 'Str', default => '' );

has data           => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has form           => ( is => 'rw', isa => 'Str', default => '' );
has icon           => ( is => 'rw', isa => 'Str', default=>'/static/images/icons/report_default.png');

1;

