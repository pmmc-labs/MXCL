
use v5.42;
use experimental qw[ class switch ];

use MXCL::Runtime::Primitives;
use MXCL::Runtime::Prelude;

class MXCL::Runtime {
    field $primitives :reader = MXCL::Runtime::Primitives->new;
    field $prelude    :reader = MXCL::Runtime::Prelude->new;
    field $base_scope :reader = undef;

    method initialize ($context) {
        $base_scope //= do {
            $primitives->initialize($context);
            $prelude->initialize($context);

            $context->roles->Role(
                $context->roles->Defined(
                    $context->terms->Sym('bind'),
                    $context->terms->BindNative('bind',
                        $primitives->lookup('bind')
                    )
                )
            );
        };

        return $self;
    }

}
