package BaselinerX::Model::LCModel;
use Moose;
BEGIN { extends 'Catalyst::Model' }

has lc =>  qw/is rw isa BaselinerX::Lc/ , default=>sub{  BaselinerX::Lc->new };

# DONT put anything here 

1;

