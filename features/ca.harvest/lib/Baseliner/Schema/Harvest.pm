package Baseliner::Schema::Harvest;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces( default_resultset_class => '+Baseliner::Schema::Harvest::Base::ResultSet' );


1;
