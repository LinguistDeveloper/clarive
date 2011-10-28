package Baseliner::Schema::Harvest;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

#__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-02 12:10:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:X5wpWVJTt7A2mNu0mBUqWw


__PACKAGE__->load_namespaces( default_resultset_class => '+Baseliner::Schema::Harvest::Base::ResultSet' );

1;
