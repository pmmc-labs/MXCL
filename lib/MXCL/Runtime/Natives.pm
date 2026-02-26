

use v5.42;
use experimental qw[ class ];

class MXCL::Runtime::Natives {
    field $functions :reader = +{};
    field $types     :reader = +{};

    method lookup        ($name)        { $functions->{ $name } }
    method lookup_method ($type, $name) { $types->{ $type }->{ $name } }

    method initialize ($context) {
        my $terms = $context->terms;
        my $roles = $context->roles;
        my $konts = $context->kontinues;

        my sub type_predicate ($klass) {
            return +{
                kind      => 'applicative',
                signature => [{ name => 'term' }],
                returns   => 'Bool',
                impl      => sub ($term) { $term->isa($klass) },
            }
        }

        my sub binary_op ($coercion, $returns, $impl) {
            $coercion = undef if $coercion eq '*';
            return +{
                kind      => 'applicative',
                signature => [ { name => 'lhs', coerce => $coercion },
                               { name => 'rhs', coerce => $coercion } ],
                returns   => $returns,
                impl      => $impl,
            }
        }

        my sub unary_op ($coercion, $returns, $impl) {
            $coercion = undef if $coercion eq '*';
            return +{
                kind      => 'applicative',
                signature => [ { name => 'lhs', coerce => $coercion } ],
                returns   => $returns,
                impl      => $impl,
            }
        }

        $functions = +{
            'bind'    => +{
                kind      => 'operative',
                signature => [
                    { name => 'name' },
                    { name => 'params' },
                    { name => 'binding' },
                ],
                impl => sub ($env, $name, $params, $binding) {
                    my $ident = $binding->value;

                    my $spec;
                    if ($ident =~ /\:\:/) {
                        $spec = $self->lookup_method( split /\:\:/ => $ident );
                    }
                    else {
                        $spec = $self->lookup( $ident );
                    }

                    my $native = $terms->BindNative( $binding->value, $spec );
                    # TODO:
                    # Should confirm that these $params
                    # match the params in the $native
                    return $konts->Define( $env, $name, $terms->List($native) );
                }
            },
            # ....
            'eq?'     => binary_op('*', 'Bool', sub ($n, $m) { $n->eq($m) }),
            'nil?'    => type_predicate('MXCL::Term::Nil'),
            'bool?'   => type_predicate('MXCL::Term::Bool'),
            'num?'    => type_predicate('MXCL::Term::Num'),
            'str?'    => type_predicate('MXCL::Term::Str'),
            'sym?'    => type_predicate('MXCL::Term::Sym'),
            'lambda?' => type_predicate('MXCL::Term::Lambda'),
            'array?'  => type_predicate('MXCL::Term::Array'),
            'ref?'    => type_predicate('MXCL::Term::Ref'),
            'opaque?' => type_predicate('MXCL::Term::Opaque'),
            'role?'   => type_predicate('MXCL::Term::Role'),
            'not'     => unary_op('boolify', 'Bool', sub ($n) { !$n }),
            'and'     => +{
                kind      => 'operative',
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
            },
            'or'      => +{
                kind      => 'operative',
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
            },
            # CONTROL
            'do'    => +{
                kind      => 'operative',
                signature => [{ name => '@' }],
                impl => sub ($env, @exprs) {
                    return $konts->Scope( $env, $terms->Nil )->wrap(
                        (reverse map {
                            $konts->Discard($env, $terms->Nil),
                            $konts->EvalExpr($env, $_, $terms->Nil)
                        } @exprs),
                    )
                }
            },
            'if'    => +{
                kind      => 'operative',
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
            },
            'while' => +{
                kind      => 'operative',
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
            },
            # DECLARE
            'let'    => +{
                kind      => 'operative',
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
            },
            'define' => +{
                kind      => 'operative',
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
            },
            'require' => +{
                kind      => 'operative',
                signature => [{ name => 'name' }],
                impl => sub ($env, $name) {
                    #say "REQUIRE: ",$name->pprint;
                    return $konts->Define(
                        $env,
                        $name,
                        $terms->List($roles->Required( $name ))
                    );
                }
            },
            'with' => +{ # TODO - this should be an applicative
                kind      => 'operative',
                signature => [{ name => '@' }],
                impl => sub ($env, $lhs, $rhs) {
                    ($lhs, $rhs) = map {
                        $_ isa MXCL::Term::Sym
                            ? $env->lookup( $_->value )->value
                            : $_
                    } ($lhs, $rhs);
                    return $konts->Return(
                        $env,
                        $terms->List( $roles->Union( $lhs, $rhs ) )
                    );
                }
            },
            'role'   => +{
                kind      => 'operative',
                signature => [{ name => '@' }],
                impl => sub ($env, @args) {
                    my ($name, $with, @exprs) = @args;
                    #say "WITH: ".$with->pprint;
                    return (
                        $konts->Define( $env, $name, $terms->Nil ),
                        $konts->Scope( $env, $terms->Nil )->wrap(
                            ($with isa MXCL::Term::Nil ? () : $konts->ApplyStack( $env, $with )),
                            $konts->Capture( $env, $terms->Nil ),
                            (reverse map {
                                $konts->Discard($env, $terms->Nil),
                                $konts->EvalExpr($env, $_, $terms->Nil)
                            } @exprs),
                        )
                    )
                }
            },
            # CONSTRUCT
            'lambda'      => +{
                kind      => 'operative',
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
            },
            'make-opaque' => +{
                kind      => 'applicative',
                signature => [ { name => 'role' } ],
                impl      => sub ($role) { $terms->Opaque($role) }
            },
            'make-ref'    => +{
                kind      => 'applicative',
                signature => [ { name => 'value' } ],
                impl      => sub ($value) { $terms->Ref($value) }
            },
            'make-role'   => +{
                kind      => 'operative',
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
            },
            'make-array'  => +{
                kind      => 'applicative',
                signature => [ { name => '@' } ],
                impl      => sub (@elements) { $terms->Array(@elements) }
            },
            'make-hash'   => +{
                kind      => 'applicative',
                signature => [ { name => '@' } ],
                impl      => sub (@elements) {
                    my %elements;
                    foreach my ($k, $v) (@elements) {
                        $elements{ $k->value } = $v;
                    }
                    return $terms->Hash(%elements);
                }
            },
        };

        $types = +{
            'Bool' => +{
                '==' => binary_op('boolify', 'Bool', sub ($n, $m) { $n == $m }),
            },
            'Num' => +{
                '==' => binary_op('numify', 'Bool', sub ($n, $m) { $n == $m }),
                '>'  => binary_op('numify', 'Bool', sub ($n, $m) { $n >  $m }),
                '+'  => binary_op('numify', 'Num',  sub ($n, $m) { $n + $m }),
                '-'  => binary_op('numify', 'Num',  sub ($n, $m) { $n - $m }),
                '*'  => binary_op('numify', 'Num',  sub ($n, $m) { $n * $m }),
                '/'  => binary_op('numify', 'Num',  sub ($n, $m) { $n / $m }),
                '%'  => binary_op('numify', 'Num',  sub ($n, $m) { $n % $m }),
            },
            'Str' => +{
                '==' => binary_op('stringify', 'Bool', sub ($n, $m) { $n eq $m }),
                '>'  => binary_op('stringify', 'Bool', sub ($n, $m) { $n gt $m }),
                '~'  => binary_op('stringify', 'Str',  sub ($n, $m) { $n . $m }),
            },
            'Ref' => +{
                'get' => +{
                    kind      => 'applicative',
                    signature => [ { name => 'ref' } ],
                    impl      => sub ($ref) { $terms->Deref($ref) }
                },
                'set' => +{
                    kind      => 'applicative',
                    signature => [ { name => 'ref' }, { name => 'value' } ],
                    impl      => sub ($ref, $value) { $terms->SetRef($ref, $value) }
                },
            },
            'Array' => +{
                'length' => +{
                    kind      => 'applicative',
                    signature => [ { name => 'array' } ],
                    impl      => sub ($array) { $terms->Num( $array->length ) },
                },
                'at'     => +{
                    kind      => 'applicative',
                    signature => [ { name => 'array' }, { name => 'index', coerce => 'numify' } ],
                    impl      => sub ($array, $index) { $array->at( $index ) },
                },
            },
            'Hash' => +{
                'length' => +{
                    kind      => 'applicative',
                    signature => [ { name => 'hash' } ],
                    impl      => sub ($hash) { $terms->Num( $hash->length ) },
                },
                'at' => +{
                    kind      => 'applicative',
                    signature => [ { name => 'hash' }, { name => 'index', coerce => 'stringify' } ],
                    impl      => sub ($hash, $index) { $hash->at( $index ) },
                },
            },
            'Role' => +{
                'compose' => +{
                    kind      => 'applicative',
                    signature => [ { name => 'r1' }, { name => 'r2' } ],
                    impl      => sub ($r1, $r2) { $roles->Union( $r1, $r2 ) }
                },
            }
        };

        $self;
    }

}
