
use v5.42;
use experimental qw[ class switch ];

class MXCL::Runtime {
    field $context :param :reader;

    field $base_scope = undef;

    # be lazy here
    method base_scope {
        return $base_scope if defined $base_scope;

        my $terms = $context->terms;
        my $roles = $context->roles;
        my $konts = $context->kontinues;

        ## ---------------------------------------------------------------------
        ## Helpers
        ## ---------------------------------------------------------------------

        my sub type_predicate ($name, $klass) {
            return $terms->Applicative(
                name      => $name,
                signature => [{ name => 'term' }],
                returns   => 'Bool',
                impl      => sub ($term) { $term->isa($klass) },
            )
        }

        my sub binary_op ($name, $coercion, $returns, $impl) {
            $coercion = undef if $coercion eq '*';
            return $terms->Applicative(
                name      => $name,
                signature => [ { name => 'lhs', coerce => $coercion },
                               { name => 'rhs', coerce => $coercion } ],
                returns   => $returns,
                impl      => $impl,
            )
        }

        my sub unary_op ($name, $coercion, $returns, $impl) {
            $coercion = undef if $coercion eq '*';
            return $terms->Applicative(
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
        my $is_role   = type_predicate('role?',   'MXCL::Term::Role');

        ## ---------------------------------------------------------------------
        ## basic equality checker
        ## ---------------------------------------------------------------------

        my $eq = binary_op('eq?', '*', 'Bool', sub ($n, $m) { $n->eq($m) });

        ## ---------------------------------------------------------------------
        ## Boolean builtins, these should exist
        ## ---------------------------------------------------------------------

        my $not = unary_op('not', 'boolify', 'Bool', sub ($n) { !$n });

        my $and = $terms->Operative(
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

        my $or = $terms->Operative(
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
        ## Note:
        ## These all wrap themselves inside a Scope::Enter/Leave which will
        ## mean that all changes to the env will get reverted after Leave.
        ## ---------------------------------------------------------------------

        my $do = $terms->Operative(
            name => 'do',
            signature => [{ name => '@' }],
            impl => sub ($env, @exprs) {
                return $konts->Scope( $env, $terms->Nil )->wrap(
                    (reverse map {
                        $konts->Discard($env, $terms->Nil),
                        $konts->EvalExpr($env, $_, $terms->Nil)
                    } @exprs),
                )
            }
        );

        my $if = $terms->Operative(
            name => 'if',
            signature => [
                { name => 'cond'     },
                { name => 'if-true'  },
                { name => 'if-false' },
            ],
            impl => sub ($env, $cond, $if_true, $if_false) {
                return $konts->Scope( $env, $terms->Nil )->wrap(
                    $konts->IfElse( $env, $cond, $if_true, $if_false, $terms->Nil ),
                    $konts->EvalExpr( $env, $cond, $terms->Nil ),
                )
            }
        );

        # TODO - test this, without mutable variables
        # this is not a very useful thing.
        my $while = $terms->Operative(
            name => 'while',
            signature => [
                { name => 'cond' },
                { name => 'body' },
            ],
            impl => sub ($env, $cond, $body) {
                return $konts->Scope( $env, $terms->Nil )->wrap(
                    $konts->DoWhile( $env, $cond, $body, $terms->Nil ),
                    $konts->EvalExpr( $env, $cond, $terms->Nil ),
                )
            }
        );

        ## ---------------------------------------------------------------------
        ## Definitions
        ## ---------------------------------------------------------------------

        my $define = $terms->Operative(
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

        my $role = $terms->Operative(
            name => 'role',
            signature => [{ name => '@' }],
            impl => sub ($env, @args) {
                my ($name, @exprs) = @args;
                return (
                    $konts->Define( $env, $name, $terms->Nil ),
                    $konts->Scope( $env, $terms->Nil )->wrap(
                        $konts->Capture( $env, $terms->Nil ),
                        (reverse map {
                            $konts->Discard($env, $terms->Nil),
                            $konts->EvalExpr($env, $_, $terms->Nil)
                        } @exprs),
                    )
                )
            }
        );

        my $let = $terms->Operative(
            name => 'let',
            signature => [
                { name => 'name' },
                { name => 'value' },
            ],
            impl => sub ($env, $name, $value) {
                return (
                    $konts->Define( $env, $name, $terms->Nil ),
                    $konts->EvalExpr( $env, $value, $terms->Nil )
                );
            }
        );

        ## ---------------------------------------------------------------------
        ## Core Roles
        ## ---------------------------------------------------------------------

        my $EQ = $roles->Role(
            $roles->Required($terms->Sym('==')),
            $roles->Defined(
                $terms->Sym('!='),
                $terms->Operative(
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

        my $ORD = $roles->Union(
            $roles->Role(
                $roles->Required($terms->Sym('==')),
                $roles->Required($terms->Sym('>')),
                $roles->Defined(
                    $terms->Sym('>='),
                    $terms->Operative(
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
                $roles->Defined(
                    $terms->Sym('<'),
                    $terms->Operative(
                        name => '<:ORD', signature => [{ name => 'n' },{ name => 'm' }],
                        impl => sub ($ctx, $n, $m) {
                            $konts->EvalExpr($ctx,
                                # (not ((n > m) || (n == m)))
                                $terms->List(
                                    $terms->Sym('not'),
                                    $terms->List(
                                        $terms->List( $n, $terms->Sym('>'), $m ),
                                        $terms->Sym('||'),
                                        $terms->List( $n, $terms->Sym('=='), $m )
                                    )
                                ),
                                $terms->Nil
                            )
                        }
                    )
                ),
                $roles->Defined(
                    $terms->Sym('<='),
                    $terms->Operative(
                        name => '<=:ORD', signature => [{ name => 'n' },{ name => 'm' }],
                        impl => sub ($ctx, $n, $m) {
                            $konts->EvalExpr($ctx,
                                # (not (n > m))
                                $terms->List($terms->Sym('not'), $terms->List( $n, $terms->Sym('>'), $m )),
                                $terms->Nil
                            )
                        }
                    )
                )
            ),
            $EQ
        );

        ## ---------------------------------------------------------------------
        ## Core Literal Roles
        ## ---------------------------------------------------------------------

        my $Bool = $roles->Union(
            $roles->Role(
                $roles->Defined($terms->Sym('=='), binary_op('==:Bool', 'boolify', 'Bool', sub ($n, $m) { $n == $m })),
                $roles->Defined($terms->Sym('&&'), $and),
                $roles->Defined($terms->Sym('||'), $or),
            ),
            $EQ
        );

        my $Num = $roles->Union(
            $roles->Role(
                $roles->Defined($terms->Sym('=='), binary_op('==:Num', 'numify', 'Bool', sub ($n, $m) { $n == $m })),
                $roles->Defined($terms->Sym('>'),  binary_op('>:Num',  'numify', 'Bool', sub ($n, $m) { $n >  $m })),
                $roles->Defined($terms->Sym('+'),  binary_op('+:Num',  'numify', 'Num',  sub ($n, $m) { $n + $m })),
                $roles->Defined($terms->Sym('-'),  binary_op('-:Num',  'numify', 'Num',  sub ($n, $m) { $n - $m })),
                $roles->Defined($terms->Sym('*'),  binary_op('*:Num',  'numify', 'Num',  sub ($n, $m) { $n * $m })),
                $roles->Defined($terms->Sym('/'),  binary_op('/:Num',  'numify', 'Num',  sub ($n, $m) { $n / $m })),
                $roles->Defined($terms->Sym('%'),  binary_op('%:Num',  'numify', 'Num',  sub ($n, $m) { $n % $m })),
            ),
            $ORD
        );

        my $Str = $roles->Union(
            $roles->Role(
                $roles->Defined($terms->Sym('=='), binary_op('==:Str', 'stringify', 'Bool', sub ($n, $m) { $n eq $m })),
                $roles->Defined($terms->Sym('>'),  binary_op('>:Str',  'stringify', 'Bool', sub ($n, $m) { $n gt $m })),
                $roles->Defined($terms->Sym('~'),  binary_op('~:Str',  'stringify', 'Str',  sub ($n, $m) { $n . $m })),
            ),
            $ORD
        );

        ## ---------------------------------------------------------------------
        ## Core Datatypes
        ## ---------------------------------------------------------------------

        my $lambda = $terms->Operative(
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

        # ...

        my $make_role = $terms->Operative(
            name => 'make-role',
            signature => [{ name => '@' }],
            impl => sub ($env, @exprs) {
                return $konts->Scope( $env, $terms->Nil )->wrap(
                    $konts->Capture( $env, $terms->Nil ),
                    (reverse map {
                        $konts->Discard($env, $terms->Nil),
                        $konts->EvalExpr($env, $_, $terms->Nil)
                    } @exprs),
                )
            }
        );

        my $Role = $roles->Union(
            $roles->Role(
                $roles->Defined($terms->Sym('=='), $eq),
                $roles->Defined($terms->Sym('+'),
                    $terms->Applicative(
                        name      => '+:Role',
                        signature => [ { name => 'r1' }, { name => 'r2' } ],
                        impl      => sub ($r1, $r2) { $roles->Union( $r1, $r2 ) }
                    )
                ),
            ),
            $EQ
        );

        # ...

        my $make_opaque = $terms->Applicative(
            name      => 'make-opaque',
            signature => [ { name => 'role' } ],
            impl      => sub ($role) {
                $terms->Opaque($role)
            }
        );

        # ...

        my $make_array = $terms->Applicative(
            name      => 'make-array',
            signature => [ { name => '@' } ],
            impl      => sub (@elements) {
                $terms->Array(@elements)
            }
        );

        my $Array = $roles->Role(
            $roles->Defined($terms->Sym('length'),
                $terms->Applicative(
                     name      => 'length:Array',
                     signature => [ { name => 'array' } ],
                     impl      => sub ($array) { $terms->Num( $array->length ) }
                )
            ),
            $roles->Defined($terms->Sym('at'),
                $terms->Applicative(
                     name      => 'at:Array',
                     signature => [ { name => 'array' }, { name => 'index', coerce => 'numify' } ],
                     impl      => sub ($array, $index) { $array->at( $index ) }
                )
            )
        );

        # ...

        my $make_hash = $terms->Applicative(
            name      => 'make-hash',
            signature => [ { name => '@' } ],
            impl      => sub (@elements) {
                my %elements;
                foreach my ($k, $v) (@elements) {
                    $elements{ $k->value } = $v;
                }
                return $terms->Hash(%elements);
            }
        );

        my $Hash = $roles->Role(
            $roles->Defined($terms->Sym('length'),
                $terms->Applicative(
                     name      => 'length:Hash',
                     signature => [ { name => 'hash' } ],
                     impl      => sub ($hash) { $terms->Num( $hash->length ) }
                )
            ),
            $roles->Defined($terms->Sym('at'),
                $terms->Applicative(
                     name      => 'at:Hash',
                     signature => [ { name => 'hash' }, { name => 'index', coerce => 'stringify' } ],
                     impl      => sub ($hash, $index) { $hash->at( $index ) }
                )
            )
        );

        # ...

        my $make_ref = $terms->Applicative(
             name      => 'make-ref',
             signature => [ { name => 'value' } ],
             impl      => sub ($value) {
                $terms->Ref($value)
             }
        );

        my $Ref = $roles->Role(
            $roles->Defined($terms->Sym('get'),
                $terms->Applicative(
                     name      => 'deref',
                     signature => [ { name => 'ref' } ],
                     impl      => sub ($ref) { $terms->Deref($ref) }
                )
            ),
            $roles->Defined($terms->Sym('set!'),
                $terms->Applicative(
                     name      => 'setref',
                     signature => [ { name => 'ref' }, { name => 'value' } ],
                     impl      => sub ($ref, $value) { $terms->SetRef($ref, $value) }
                )
            )
        );

        ## ---------------------------------------------------------------------
        ## Base Scope ...
        ## ---------------------------------------------------------------------

        $base_scope = $roles->Role(
            $roles->Defined($terms->Sym('define'),            $define),
            $roles->Defined($terms->Sym('let'),               $let),
            $roles->Defined($terms->Sym('lambda'),            $lambda),
            $roles->Defined($terms->Sym('role'),              $role),
            $roles->Defined($terms->Sym('if'),                $if),
            $roles->Defined($terms->Sym('do'),                $do),
            $roles->Defined($terms->Sym('while'),             $while),
            $roles->Defined($terms->Sym('eq?'),               $eq),
            $roles->Defined($terms->Sym('not'),               $not),
            $roles->Defined($terms->Sym('and'),               $and),
            $roles->Defined($terms->Sym('or'),                $or),
            $roles->Defined($terms->Sym('nil?'),              $is_nil),
            $roles->Defined($terms->Sym('bool?'),             $is_bool),
            $roles->Defined($terms->Sym('num?'),              $is_num),
            $roles->Defined($terms->Sym('str?'),              $is_str),
            $roles->Defined($terms->Sym('sym?'),              $is_sym),
            $roles->Defined($terms->Sym('lambda?'),           $is_lambda),
            $roles->Defined($terms->Sym('array?'),            $is_array),
            $roles->Defined($terms->Sym('ref?'),              $is_ref),
            $roles->Defined($terms->Sym('opaque?'),           $is_opaque),
            $roles->Defined($terms->Sym('role?'),             $is_role),
            $roles->Defined($terms->Sym('make-opaque'),       $make_opaque),
            $roles->Defined($terms->Sym('make-role'),         $make_role),
            $roles->Defined($terms->Sym('make-array'),        $make_array),
            $roles->Defined($terms->Sym('make-hash'),         $make_hash),
            $roles->Defined($terms->Sym('make-ref'),          $make_ref),
            $roles->Defined($terms->Sym('MXCL::Term::Bool'),  $Bool),
            $roles->Defined($terms->Sym('MXCL::Term::Num'),   $Num),
            $roles->Defined($terms->Sym('MXCL::Term::Str'),   $Str),
            $roles->Defined($terms->Sym('MXCL::Term::Ref'),   $Ref),
            $roles->Defined($terms->Sym('MXCL::Term::Array'), $Array),
            $roles->Defined($terms->Sym('MXCL::Term::Hash'),  $Hash),
            $roles->Defined($terms->Sym('MXCL::Term::Role'),  $Role),
            $roles->Defined($terms->Sym('<EQ>'),              $EQ),
            $roles->Defined($terms->Sym('<ORD>'),             $ORD),
        );
    }

}
