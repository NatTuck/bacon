package Bacon::BigNum;

use Moose::Util::TypeConstraints;
use Math::BigInt;
use Math::BigFloat;

use Scalar::Util qw(blessed);
use Bacon::Utils qw(embiggen);

subtype 'BigNum',
    as 'Object',
    where { blessed($_) && 
            ($_->isa('Math::BigInt') || $_->isa('Math::BigFloat')) };

coerce 'BigNum',
    from 'Num',
    via { embiggen($_) };

no Moose::Util::TypeConstraints;
1;
