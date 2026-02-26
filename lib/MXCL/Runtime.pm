
use v5.42;
use experimental qw[ class switch ];

use MXCL::Runtime::Natives;
use MXCL::Runtime::Prelude;

class MXCL::Runtime {
    field $natives    :reader = MXCL::Runtime::Natives->new;
    field $prelude    :reader = MXCL::Runtime::Prelude->new;
    field $base_scope :reader = undef;

    method initialize ($context) {
        return $base_scope if defined $base_scope;

        $natives->initialize($context);
        $prelude->initialize($context);

        my $terms = $context->terms;
        my $roles = $context->roles;

        $base_scope = $roles->Role(
            $roles->Defined(
                $terms->Sym('bind'),
                $terms->BindNative('bind', $natives->lookup('bind'))
            )
        );

        return $base_scope;
    }

}
