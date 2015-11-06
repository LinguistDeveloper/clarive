package Baseliner::Types;

use Class::Date;
use Time::Local ();
use Baseliner::Utils;
use Moose::Util::TypeConstraints;
use Clarive::ci;

subtype BoolCheckbox => as 'Bool';
subtype Date         => as 'Class::Date';
subtype HashJSON     => as 'HashRef';
subtype TS           => as 'Str';
subtype DT           => as 'DateTime';
subtype BL           => as 'Maybe[Str]';

subtype 'PositiveInt', as 'Int', where { $_ >= 0 };

subtype 'SortDirection', as 'Str', where { lc($_) eq 'asc' || lc($_) eq 'desc' };

subtype 'DateStr', as 'Str', where {
    return unless /^(\d\d\d\d)-(\d\d)-(\d\d)$/;

    return eval { Time::Local::timelocal( 0, 0, 0, $3, $2 - 1, $1 ); 1; };
};

subtype 'TimeStr', as 'Str', where {
    return unless /^(\d\d):(\d\d)(?::(\d\d))?$/;

    return unless $1 >= 0 && $1 <= 23 && $2 >= 0 && $2 <= 59;

    if ($3) {
        return unless $3 >= 0 && $3 <= 59;
    }

    return 1;
};

subtype 'ID', as 'Str';

subtype 'GitBranch', as 'Str', where { m/^[[:alnum:]\-_#\.]+$/ };
subtype 'GitTag',    as 'Str', where { m/^[[:alnum:]\-_#\.]+$/ };
subtype 'GitCommit', as 'Str', where { m/^[a-h0-9]+$/ };
subtype 'GitFolder', as 'Str', where { m/^[[:alnum:]\-_\.\/]+$/ };

subtype 'ExistingCI', as 'Object';

coerce 'Date' =>
  from 'Str' => via { Class::Date->new($_) },
  from 'Num'        => via { Class::Date->new($_) },
  from 'Undef' => via { Class::Date->now };

coerce 'BL' =>
  from 'ArrayRef'   => via { join ',', @$_ },
  from 'Undef' => via { '*' };

coerce 'TS' =>
  from 'DT' => via { Class::Date->new( $_->set_time_zone( Util->_tz ) )->string },
  from 'Class::Date' => via { $_->string },
  from 'Num' => via { Class::Date->new($_)->string },
  from 'Undef' => via { Class::Date->now->string },
  from 'Any' => via { Class::Date->now->string };

coerce 'BoolCheckbox' => from 'Str' => via { $_ eq 'on' ? 1 : 0 };

coerce 'HashJSON' => from
  'Str'        => via { Util->_from_json($_) },
  from 'Undef' => via { +{} };

coerce 'ExistingCI' => from 'Str', via { eval { ci->new($_) } };

1;
