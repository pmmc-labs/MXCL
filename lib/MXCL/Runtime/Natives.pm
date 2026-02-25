

use v5.42;
use experimental qw[ class ];

class MXCL::Runtime::Natives {
    field $functions :reader = +{
        'bind'    => undef,
        'eq?'     => undef,
        'nil?'    => undef,
        'bool?'   => undef,
        'num?'    => undef,
        'str?'    => undef,
        'sym?'    => undef,
        'lambda?' => undef,
        'array?'  => undef,
        'ref?'    => undef,
        'opaque?' => undef,
        'role?'   => undef,
        'not'     => undef,
        'and'     => undef,
        'or'      => undef,
        # CONTROL
        'do'    => undef,
        'if'    => undef,
        'while' => undef,
        # DECLARE
        'let'    => undef,
        'define' => undef,
        'role'   => undef,
        # CONSTRUCT
        'lambda'      => undef,
        'make-opaque' => undef,
        'make-ref'    => undef,
        'make-role'   => undef,
        'make-array'  => undef,
        'make-hash'   => undef,
    };

    field $types :reader = +{
        'Bool' => +{
            '==' => undef,
        },
        'Num' => +{
            '==' => undef,
            '>'  => undef,
            '+'  => undef,
            '-'  => undef,
            '*'  => undef,
            '/'  => undef,
            '%'  => undef,
        },
        'Str' => +{
            '==' => undef,
            '>'  => undef,
            '~'  => undef,
        },
        'Ref' => +{
            'get' => undef,
            'set' => undef,
        },
        'Array' => +{
            'length' => undef,
            'at'     => undef,
        },
        'Hash' => +{
            'length' => undef,
            'at'     => undef,
        },
        'Role' => +{
            'compose' => undef,
        }
    };

    method register ($name, $native) {
        exists $functions->{ $name }  || die "Uknown function ($name)";
        defined $functions->{ $name } && die "Function ($name) is already bound";
        $functions->{ $name } = $native;
        return $native;
    }

    method register_method ($type, $name, $native) {
        exists $types->{ $type }             || die "Uknown type ($type)";
        exists $types->{ $type }->{ $name }  || die "Uknown method ($name) for $type";
        defined $types->{ $type }->{ $name } && die "Method ($name) for $type is already bound";
        $types->{ $type }->{ $name } = $native;
        return $native;
    }

    method lookup        ($name)        { $functions->{ $name } }
    method lookup_method ($type, $name) { $types->{ $type }->{ $name } }

}
