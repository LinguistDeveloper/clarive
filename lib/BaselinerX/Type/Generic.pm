package BaselinerX::Type::Generic;
use Baseliner::Plug;
with 'Baseliner::Role::Registrable';

has 'config' => (is=>'rw', isa=>'Str', default=>'' );

1;