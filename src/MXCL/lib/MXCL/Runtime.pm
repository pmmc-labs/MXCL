
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
        ## TODO:
        ## - add predicates for Native::* and Kontinue::* perhaps?
        ## - ponder an `type-of?`
        ##      - should it accept a Sym/Tag and I check against it?
        ##      - or should I register "types" in the base scope which resolve
        ##        to some kind of singleton Term we can check against?
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
        ## Boolean builtins, these should exist
        ## ---------------------------------------------------------------------

        my $not = unary_op('not', 'boolify', 'Bool', sub ($n) { !$n });

        my $and = $natives->Operative(
            name => 'and',
            signature => [
                { name => 'lhs' },
                { name => 'rhs' },
            ],
            impl => sub ($env, $lhs, $rhs) {
                return (
                    $konts->IfElse( $env, $lhs, $rhs, $lhs, $terms->Nil ),
                    $konts->EvalExpr( $env, $lhs, $terms->Nil ),
                )
            }
        );

        my $or = $natives->Operative(
            name => 'or',
            signature => [
                { name => 'lhs' },
                { name => 'rhs' },
            ],
            impl => sub ($env, $lhs, $rhs) {
                return (
                    $konts->IfElse( $env, $lhs, $lhs, $rhs, $terms->Nil ),
                    $konts->EvalExpr( $env, $lhs, $terms->Nil ),
                )
            }
        );

        ## ---------------------------------------------------------------------
        ## Control structures
        ## ---------------------------------------------------------------------

        my $do = $natives->Operative(
            name => 'do',
            signature => [{ name => '@' }],
            impl => sub ($env, @exprs) {
                return reverse map {
                    # FIXME:
                    # We need to add a Drop-Stack/End-Statement kontinue
                    # here to prevent the last value of the expression
                    # from going on the stack of the next one.
                    #
                    # But make sure the last value is preserved
                    # so that we can return it.
                    $context->kontinues->EvalExpr($env, $_, $context->terms->Nil)
                } @exprs
            }
        );

        my $if = $natives->Operative(
            name => 'if',
            signature => [
                { name => 'cond'     },
                { name => 'if-true'  },
                { name => 'if-false' },
            ],
            impl => sub ($env, $cond, $if_true, $if_false) {
                return (
                    $konts->IfElse( $env, $cond, $if_true, $if_false, $terms->Nil ),
                    $konts->EvalExpr( $env, $cond, $terms->Nil ),
                )
            }
        );

        # TODO - test this, without mutable variables
        # this is not a very useful thing.
        my $while = $natives->Operative(
            name => 'while',
            signature => [
                { name => 'cond' },
                { name => 'body' },
            ],
            impl => sub ($env, $cond, $body) {
                return (
                    $konts->DoWhile( $env, $cond, $body, $terms->Nil ),
                    $konts->EvalExpr( $env, $cond, $terms->Nil ),
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
            impl => sub ($env, $params, $body) {
                return $konts->Return(
                    $env,
                    $terms->List( $terms->Lambda( $params, $body, $env ) )
                );
            }
        );

        my $define = $natives->Operative(
            name => 'define',
            signature => [
                { name => 'name' },
                { name => 'params' },
                { name => 'body'   },
            ],
            impl => sub ($env, $name, $params, $body) {
                return $konts->Define(
                    $env,
                    $name,
                    $terms->List( $terms->Lambda( $params, $body, $env, $name ) )
                );
            }
        );

        ## ---------------------------------------------------------------------
        ## Core Traits
        ## ---------------------------------------------------------------------

        my $EQ = $traits->Trait(
            $terms->Sym('EQ'),
            '==' => $traits->Required,
            '!=' => $traits->Defined(
                $natives->Operative(
                    name => '!=:EQ', signature => [{ name => 'n' },{ name => 'm' }],
                    impl => sub ($ctx, $n, $m) {
                        $konts->EvalExpr($ctx,
                            # (not (n == m))
                            $terms->List($terms->Sym('not'), $terms->List( $n, $terms->Sym('=='), $m )),
                            $terms->Nil
                        )
                    }
                )
            )
        );

        my $ORD = $traits->Trait(
            $terms->Sym('ORD'),
            '==' => $traits->Required,
            '>'  => $traits->Required,
            '>=' => $traits->Defined(
                $natives->Operative(
                    name => '>=:ORD', signature => [{ name => 'n' },{ name => 'm' }],
                    impl => sub ($ctx, $n, $m) {
                        $konts->EvalExpr($ctx,
                            # ((n > m) || (n == m))
                            $terms->List(
                                $terms->List( $n, $terms->Sym('>'), $m ),
                                $terms->Sym('||'),
                                $terms->List( $n, $terms->Sym('=='), $m )
                            ),
                            $terms->Nil
                        )
                    }
                )
            ),
            '<' => $traits->Defined(
                $natives->Operative(
                    name => '<:ORD', signature => [{ name => 'n' },{ name => 'm' }],
                    impl => sub ($ctx, $n, $m) {
                        $konts->EvalExpr($ctx,
                            # (not (n > m))
                            $terms->List($terms->Sym('not'), $terms->List( $n, $terms->Sym('>'), $m )),
                            $terms->Nil
                        )
                    }
                )
            ),
            '<=' => $traits->Defined(
                $natives->Operative(
                    name => '<=:ORD', signature => [{ name => 'n' },{ name => 'm' }],
                    impl => sub ($ctx, $n, $m) {
                        $konts->EvalExpr($ctx,
                            # ((n < m) || (n == m))
                            $terms->List(
                                $terms->List( $n, $terms->Sym('<'), $m ),
                                $terms->Sym('||'),
                                $terms->List( $n, $terms->Sym('=='), $m )
                            ),
                            $terms->Nil
                        )
                    }
                )
            )
        );

        ## ---------------------------------------------------------------------
        ## Core Literal Traits
        ## ---------------------------------------------------------------------

        my $Bool = $traits->Compose(
            $terms->Sym('Bool:EQ'),
            $EQ,
            $traits->Trait(
                $terms->Sym('Bool'),
                '==' => $traits->Defined(binary_op('==:Bool', 'boolify', 'Bool', sub ($n, $m) { $n == $m })),
                '&&' => $traits->Defined($and),
                '||' => $traits->Defined($or),
            )
        );

        my $Num = $traits->Compose(
            $terms->Sym('Num:EQ::ORD'),
            $ORD,
            $traits->Compose(
                $terms->Sym('Num:EQ'),
                $EQ,
                $traits->Trait(
                    $terms->Sym('Num'),
                    '==' => $traits->Defined(binary_op('==:Num', 'numify', 'Bool', sub ($n, $m) { $n == $m })),
                    '>'  => $traits->Defined(binary_op('>:Num',  'numify', 'Bool', sub ($n, $m) { $n >  $m })),

                    '+'  => $traits->Defined(binary_op('+:Num',  'numify', 'Num',  sub ($n, $m) { $n + $m })),
                    '-'  => $traits->Defined(binary_op('-:Num',  'numify', 'Num',  sub ($n, $m) { $n - $m })),
                    '*'  => $traits->Defined(binary_op('*:Num',  'numify', 'Num',  sub ($n, $m) { $n * $m })),
                    '/'  => $traits->Defined(binary_op('/:Num',  'numify', 'Num',  sub ($n, $m) { $n / $m })),
                    '%'  => $traits->Defined(binary_op('%:Num',  'numify', 'Num',  sub ($n, $m) { $n % $m })),
                )
            )
        );

        my $Str = $traits->Compose(
            $terms->Sym('Str:EQ::ORD'),
            $ORD,
            $traits->Compose(
                $terms->Sym('Str:EQ'),
                $EQ,
                $traits->Trait(
                    $terms->Sym('Str'),
                    '==' => $traits->Defined(binary_op('==:Str', 'stringify', 'Bool', sub ($n, $m) { $n eq $m })),
                    '>'  => $traits->Defined(binary_op('>:Str',  'stringify', 'Bool', sub ($n, $m) { $n gt $m })),

                    '~'  => $traits->Defined(binary_op('~:Str',  'stringify', 'Str',  sub ($n, $m) { $n . $m })),
                )
            )
        );

        ## ---------------------------------------------------------------------
        ## Base Scope ...
        ## ---------------------------------------------------------------------

        $base_scope = $traits->Trait(
            $terms->Sym('::'),
            'define'   => $traits->Defined($define),
            'lambda'   => $traits->Defined($lambda),
            'if'       => $traits->Defined($if),
            'do'       => $traits->Defined($do),
            'while'    => $traits->Defined($while), # UNTESTED

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

            # core types ...
            'MXCL::Term::Bool' => $traits->Defined($Bool),
            'MXCL::Term::Num'  => $traits->Defined($Num),
            'MXCL::Term::Str'  => $traits->Defined($Str),
        );
    }

}
