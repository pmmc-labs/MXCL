
use v5.42;
use experimental qw[ class switch ];

class MXCL::Runtime {
    field $context :param :reader;

    field $base_scope :reader;

    ADJUST {
        my $terms    = $context->terms;
        my $refs     = $context->refs;
        my $traits   = $context->traits;
        my $natives  = $context->natives;
        my $konts    = $context->kontinues;

        ## ---------------------------------------------------------------------
        ## Helpers
        ## ---------------------------------------------------------------------

        my sub type_predicate ($name, $klass) {
            return $natives->Applicative(
                name      => $name,
                signature => [{ name => 'term' }],
                returns   => 'Bool',
                impl      => sub ($term) { $term->isa($klass) },
            )
        }

        my sub binary_op ($name, $coercion, $returns, $impl) {
            $coercion = undef if $coercion eq '*';
            return $natives->Applicative(
                name      => $name,
                signature => [ { name => 'lhs', coerce => $coercion },
                               { name => 'rhs', coerce => $coercion } ],
                returns   => $returns,
                impl      => $impl,
            )
        }

        my sub unary_op ($name, $coercion, $returns, $impl) {
            $coercion = undef if $coercion eq '*';
            return $natives->Applicative(
                name      => $name,
                signature => [ { name => 'lhs', coerce => $coercion } ],
                returns   => $returns,
                impl      => $impl,
            )
        }

        ## ---------------------------------------------------------------------
        ## Type Predicates
        ## ---------------------------------------------------------------------

        my $is_nil    = type_predicate('nil?',    'MXCL::Term::Nil');
        my $is_bool   = type_predicate('bool?',   'MXCL::Term::Bool');
        my $is_num    = type_predicate('num?',    'MXCL::Term::Num');
        my $is_str    = type_predicate('str?',    'MXCL::Term::Str');
        my $is_sym    = type_predicate('sym?',    'MXCL::Term::Sym');
        my $is_lambda = type_predicate('lambda?', 'MXCL::Term::Lambda');
        my $is_array  = type_predicate('array?',  'MXCL::Term::Array');
        my $is_ref    = type_predicate('ref?',    'MXCL::Term::Ref');
        my $is_opaque = type_predicate('opaque?', 'MXCL::Term::Opaque');
        my $is_trait  = type_predicate('trait?',  'MXCL::Term::Trait');

        ## ---------------------------------------------------------------------
        ## basic equality checker
        ## ---------------------------------------------------------------------

        my $eq = binary_op('eq?', '*', 'Bool', sub ($n, $m) { $n->eq($m) });

        ## ---------------------------------------------------------------------
        ## Some basic builtins, might remove these, but meh, they work
        ## ---------------------------------------------------------------------

        my $add = binary_op('add', 'numify', 'Num', sub ($n, $m) { $n + $m });
        my $sub = binary_op('sub', 'numify', 'Num', sub ($n, $m) { $n - $m });
        my $mul = binary_op('mul', 'numify', 'Num', sub ($n, $m) { $n * $m });
        my $div = binary_op('div', 'numify', 'Num', sub ($n, $m) { $n / $m });
        my $mod = binary_op('mod', 'numify', 'Num', sub ($n, $m) { $n % $m });

        my $concat = binary_op('concat', 'stringify', 'Str', sub ($n, $m) { $n . $m });

        ## ---------------------------------------------------------------------
        ## Boolean builtins, these should exist
        ## ---------------------------------------------------------------------

        my $not = unary_op('not', 'boolify', 'Bool', sub ($n) { !$n });

        my $and = $natives->Operative(
            name => 'and',
            signature => [
                { name => 'lhs' },
                { name => 'rhs' },
            ],
            impl => sub ($ctx, $lhs, $rhs) {
                return (
                    $konts->IfElse( $ctx, $lhs, $rhs, $lhs, $terms->Nil ),
                    $konts->EvalExpr( $ctx, $lhs, $terms->Nil ),
                )
            }
        );

        my $or = $natives->Operative(
            name => 'or',
            signature => [
                { name => 'lhs' },
                { name => 'rhs' },
            ],
            impl => sub ($ctx, $lhs, $rhs) {
                return (
                    $konts->IfElse( $ctx, $lhs, $lhs, $rhs, $terms->Nil ),
                    $konts->EvalExpr( $ctx, $lhs, $terms->Nil ),
                )
            }
        );

        ## ---------------------------------------------------------------------
        ## Control structures
        ## ---------------------------------------------------------------------

        my $if = $natives->Operative(
            name => 'if',
            signature => [
                { name => 'cond'     },
                { name => 'if-true'  },
                { name => 'if-false' },
            ],
            impl => sub ($ctx, $cond, $if_true, $if_false) {
                return (
                    $konts->IfElse( $ctx, $cond, $if_true, $if_false, $terms->Nil ),
                    $konts->EvalExpr( $ctx, $cond, $terms->Nil ),
                )
            }
        );

        ## ---------------------------------------------------------------------
        ## Constructors
        ## ---------------------------------------------------------------------

        my $lambda = $natives->Operative(
            name => 'lambda',
            signature => [
                { name => 'params' },
                { name => 'body'   },
            ],
            impl => sub ($ctx, $params, $body) {
                return $konts->Return(
                    $ctx,
                    $terms->List( $terms->Lambda( $params, $body, $ctx ) )
                );
            }
        );

        ## ---------------------------------------------------------------------
        ## Base Scope ...
        ## ---------------------------------------------------------------------

        $base_scope = $traits->Trait(
            $terms->Sym('::'),
            'lambda'   => $traits->Defined($lambda),
            'if'       => $traits->Defined($if),

            'eq?'      => $traits->Defined($eq),
            'not'      => $traits->Defined($not),
            'and'      => $traits->Defined($and),
            'or'       => $traits->Defined($or),

            'nil?'     => $traits->Defined($is_nil),
            'bool?'    => $traits->Defined($is_bool),
            'num?'     => $traits->Defined($is_num),
            'str?'     => $traits->Defined($is_str),
            'sym?'     => $traits->Defined($is_sym),
            'lambda?'  => $traits->Defined($is_lambda),
            'array?'   => $traits->Defined($is_array),
            'ref?'     => $traits->Defined($is_ref),
            'opaque?'  => $traits->Defined($is_opaque),
            'trait?'   => $traits->Defined($is_trait),

            'add'      => $traits->Defined($add),
            'sub'      => $traits->Defined($sub),
            'mul'      => $traits->Defined($mul),
            'div'      => $traits->Defined($div),
            'mod'      => $traits->Defined($mod),

            'concat'   => $traits->Defined($concat),
        );
    }

}
