
use v5.42;
use experimental qw[ class switch ];

use MXCL::Runtime::Primitives;
use MXCL::Runtime::Prelude;

class MXCL::Runtime {
    field $primitives :reader = MXCL::Runtime::Primitives->new;
    field $prelude    :reader = MXCL::Runtime::Prelude->new;
    field $base_scope :reader = undef;

    method initialize ($context) {
        #return $base_scope if defined $base_scope;

        $primitives->initialize($context);
        $prelude->initialize($context);

        my $terms = $context->terms;
        my $roles = $context->roles;

        $base_scope = $roles->Role(
            $roles->Defined(
                $terms->Sym('bind'),
                $terms->BindNative('bind', $primitives->lookup('bind'))
            )
        );

        return $base_scope;
    }

}
