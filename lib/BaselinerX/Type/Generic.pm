package BaselinerX::Type::Generic;
use Baseliner::PlugMouse;
with 'Baseliner::Role::Registrable';

has 'config' => (is=>'rw', isa=>'Str', default=>'' );

1;
