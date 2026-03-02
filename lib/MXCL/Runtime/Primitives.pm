

use v5.42;
use experimental qw[ class ];

class MXCL::Runtime::Primitives {
    field $functions :reader = undef;
    field $types     :reader = undef;

    method lookup        ($name)        { $functions->{ $name } }
    method lookup_method ($type, $name) { $types->{ $type }->{ $name } }

    method initialize ($context) {
        $self->initialize_functions($context);
        $self->initialize_types($context);
        return $self;
    }

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

    method initialize_functions ($context) {
        my $terms     = $context->terms;
        my $roles     = $context->roles;
        my $konts     = $context->kontinues;
        my $generator = $context->generator;

        $functions //= +{
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

                    #use Data::Dumper qw[ Dumper ];
                    #say Dumper [ $binding->value, $spec ];

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
            'fexpr?'  => type_predicate('MXCL::Term::FExpr'),
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
                    return $generator->AndShortCircuit( $env, $lhs, $rhs )
                }
            },
            'or'      => +{
                kind      => 'operative',
                signature => [
                    { name => 'lhs' },
                    { name => 'rhs' },
                ],
                impl => sub ($env, $lhs, $rhs) {
                    return $generator->OrShortCircuit( $env, $lhs, $rhs )
                }
            },
            # CONTROL
            'do'    => +{
                kind      => 'operative',
                signature => [{ name => '@' }],
                impl => sub ($env, @exprs) {
                    return $generator->EvalStatementsInScope( $env, \@exprs )
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
                    return $generator->InScope( $env,
                        $generator->Conditional( $env, $cond, $if_true, $if_false )
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
                    return $generator->InScope( $env,
                        $generator->LoopWhile( $env, $cond, $body ),
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
                    $generator->DeclareVariable( $env, $name, $value );
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
                    $generator->DefineFunction($env, $name, $params, $body);
                }
            },
            'lambda'      => +{
                kind      => 'operative',
                signature => [
                    { name => 'params' },
                    { name => 'body'   },
                ],
                impl => sub ($env, $params, $body) {
                    $generator->ReturnValues(
                        $env,
                        $terms->Lambda( $params, $body, $env )
                    )
                }
            },
            'defexpr' => +{
                kind      => 'operative',
                signature => [
                    { name => 'name' },
                    { name => 'params' },
                    { name => 'body'   },
                ],
                impl => sub ($env, $name, $params, $body) {
                    $generator->DefineFExpr($env, $name, $params, $body);
                }
            },
            'fexpr' => +{
                kind      => 'operative',
                signature => [
                    { name => 'params' },
                    { name => 'body'   },
                ],
                impl => sub ($env, $params, $body) {
                    $generator->ReturnValues(
                        $env,
                        $terms->FExpr( $params, $body, $env )
                    )
                }
            },
            'require' => +{
                kind      => 'operative',
                signature => [{ name => 'name' }],
                impl => sub ($env, $name) {
                    $generator->DeclareRequirement( $env, $name )
                }
            },
            'with' => +{ # TODO - this should be an applicative
                kind      => 'operative',
                signature => [{ name => '@' }],
                impl => sub ($env, $lhs, $rhs) {
                    $generator->ComposeRoles ($env, $lhs, $rhs);
                }
            },
            'role'   => +{
                kind      => 'operative',
                signature => [{ name => '@' }],
                impl => sub ($env, $name, $with, @exprs) {
                    $generator->DefineRole( $env, $name, $with, \@exprs ),
                }
            },
            # CONSTRUCT
            'cons' => +{
                kind      => 'applicative',
                signature => [ { name => 'head' }, { name => 'tail' } ],
                impl      => sub ($head, $tail) {
                    $terms->Cons( $head, $tail )
                }
            },
            'head' => +{
                kind      => 'applicative',
                signature => [ { name => 'cons' } ],
                impl      => sub ($cons) { $cons->head }
            },
            'tail' => +{
                kind      => 'applicative',
                signature => [ { name => 'cons' } ],
                impl      => sub ($cons) { $cons->tail }
            },
            'join' => +{
                kind      => 'applicative',
                signature => [
                    { name => 'sep', coerce => 'stringify' },
                    { name => 'cons' },
                ],
                returns => 'Str',
                impl    => sub ($sep, $list) {
                    if ($list isa MXCL::Term::Nil) {
                        return "";
                    }
                    elsif ($list isa MXCL::Term::Cons) {
                        return join $sep, map $_->stringify, $list->uncons;
                    }
                    elsif ($list isa MXCL::Term::Array) {
                        return join $sep, map $_->stringify, $list->elements->@*;
                    }
                    # XXX - should we handle Hash??
                    else {
                        return $list->stringify;
                    }
                }
            },
            'split' => +{
                kind      => 'applicative',
                signature => [
                    { name => 'pattern', coerce => 'stringify' },
                    { name => 'string', coerce => 'stringify' },
                ],
                impl => sub ($pattern, $string) {
                    $terms->List( map $terms->Str($_), split $pattern, $string )
                }
            },
            'eval' => +{
                kind      => 'operative',
                signature => [ { name => 'expr' } ],
                impl      => sub ($env, $expr) {
                    return (
                        $konts->EvalTOS( $env, $terms->Nil ),
                        $konts->EvalExpr( $env, $expr, $terms->Nil )
                    )
                }
            },
            'quote' => +{
                kind      => 'operative',
                signature => [ { name => 'value' } ],
                impl      => sub ($env, $value) {
                    $generator->ReturnValues( $env, $value );
                }
            },
            'list'  => +{
                kind      => 'applicative',
                signature => [ { name => '@' } ],
                impl      => sub (@elements) { $terms->List(@elements) }
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
            'make-channel'=> +{
                kind      => 'applicative',
                signature => [],
                impl      => sub () { $terms->Channel }
            },
            'make-role'   => +{
                kind      => 'operative',
                signature => [{ name => '@' }],
                impl => sub ($env, @exprs) {
                    # HMMM:
                    # think about allowing the first arg
                    # to optionally by a with list?
                    $generator->ConstructRole( $env, $terms->Nil, \@exprs )
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
    }

    method initialize_types ($context) {
        my $terms     = $context->terms;
        my $roles     = $context->roles;
        my $konts     = $context->kontinues;
        my $generator = $context->generator;

        $types //= +{
            'Bool' => +{
                '=='  => binary_op('boolify', 'Bool', sub ($n, $m) { $n == $m }),
            },
            'Num' => +{
                '==' => binary_op('numify', 'Bool', sub ($n, $m) { $n == $m }),
                '>'  => binary_op('numify', 'Bool', sub ($n, $m) { $n >  $m }),
                '+'  => binary_op('numify', 'Num',  sub ($n, $m) { $n + $m }),
                '-'  => binary_op('numify', 'Num',  sub ($n, $m) { $n - $m }),
                '*'  => binary_op('numify', 'Num',  sub ($n, $m) { $n * $m }),
                '/'  => binary_op('numify', 'Num',  sub ($n, $m) { $n / $m }),
                '%'  => binary_op('numify', 'Num',  sub ($n, $m) { $n % $m }),

                'abs' => unary_op('numify', 'Num', sub ($n) { abs($n) }),
                'cos' => unary_op('numify', 'Num', sub ($n) { cos($n) }),
                'sin' => unary_op('numify', 'Num', sub ($n) { sin($n) }),
                'int' => unary_op('numify', 'Num', sub ($n) { int($n) }),

                'sqrt' => unary_op('numify', 'Num', sub ($n) { sqrt($n) }),
                'rand' => unary_op('numify', 'Num', sub ($n) { rand($n) }),

                'chr' => unary_op('numify', 'Str', sub ($n) { chr($n) }),
            },
            'Str' => +{
                '==' => binary_op('stringify', 'Bool', sub ($n, $m) { $n eq $m }),
                '>'  => binary_op('stringify', 'Bool', sub ($n, $m) { $n gt $m }),
                '~'  => binary_op('stringify', 'Str',  sub ($n, $m) { $n . $m }),

                'uc' => unary_op('stringify', 'Str', sub ($n) { uc($n) }),
                'lc' => unary_op('stringify', 'Str', sub ($n) { lc($n) }),
                'fc' => unary_op('stringify', 'Str', sub ($n) { fc($n) }),

                'ucfirst' => unary_op('stringify', 'Str', sub ($n) { ucfirst($n) }),
                'lcfirst' => unary_op('stringify', 'Str', sub ($n) { lcfirst($n) }),

                'hex' => unary_op('stringify', 'Num', sub ($n) { hex($n) }),
                'oct' => unary_op('stringify', 'Num', sub ($n) { oct($n) }),

                'chomp'   => unary_op('stringify', 'Str', sub ($n) { chomp($n); $n }),
                'length'  => unary_op('stringify', 'Num', sub ($n) { length($n); }),

                'index'  => binary_op('stringify', 'Num',  sub ($n, $m) { index($n, $m)  }),
                'rindex' => binary_op('stringify', 'Num',  sub ($n, $m) { rindex($n, $m) }),
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
            'Channel' => +{
                'read' => +{
                    kind      => 'applicative',
                    signature => [ { name => 'ch' } ],
                    impl      => sub ($ch) { $ch->read }
                },
                'write' => +{
                    kind      => 'applicative',
                    signature => [ { name => '@' } ],
                    impl      => sub ($ch, @data) {
                        $ch->write( @data );
                        return $terms->Nil;
                    }
                },
            },
            'Array' => +{
                'length' => +{
                    kind      => 'applicative',
                    signature => [ { name => 'array' } ],
                    impl      => sub ($array) { $terms->Num( $array->length ) },
                },
                'at' => +{
                    kind      => 'applicative',
                    signature => [ { name => 'array' }, { name => 'index', coerce => 'numify' } ],
                    impl      => sub ($array, $index) { $array->at( $index ) },
                },
                'reverse' => +{
                    kind      => 'applicative',
                    signature => [ { name => 'array' } ],
                    impl      => sub ($array) { $terms->ArrayReverse( $array ) },
                },
                'push' => +{
                    kind      => 'applicative',
                    signature => [ { name => 'array' }, { name => 'item' } ],
                    impl      => sub ($array, $item) { $terms->ArrayPush( $array, $item ) },
                },
                'unshift'  => +{
                    kind      => 'applicative',
                    signature => [ { name => 'array' }, { name => 'item' } ],
                    impl      => sub ($array, $item) { $terms->ArrayUnshift( $array, $item ) },
                },
                'splice' => +{
                    kind      => 'applicative',
                    signature => [
                        { name => 'array' },
                        { name => 'offset', coerce => 'numify' },
                        { name => 'length', coerce => 'numify' },
                    ],
                    impl => sub ($array, $offset, $length) { $terms->ArraySplice( $array, $offset, $length )},
                },
                'foreach' => +{
                    kind      => 'operative',
                    signature => [
                        { name => 'array' },
                        { name => 'f' },
                    ],
                    impl => sub ($env, $array, $f) {
                        return $konts->EvalExpr(
                            $env,
                            $terms->List(
                                $terms->Sym('do'),
                                map {
                                    $terms->List( $f, $_ )
                                } $array->elements->@*
                            ),
                            $terms->Nil
                        )
                    },
                },
                'map' => +{
                    kind      => 'operative',
                    signature => [
                        { name => 'array' },
                        { name => 'f' },
                    ],
                    impl => sub ($env, $array, $f) {
                        return $konts->EvalExpr(
                            $env,
                            $terms->List(
                                $terms->Sym('make-array'),
                                map {
                                    $terms->List( $f, $_ )
                                } $array->elements->@*
                            ),
                            $terms->Nil
                        )
                    },
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
                    signature => [ { name => 'hash' }, { name => 'key', coerce => 'stringify' } ],
                    impl      => sub ($hash, $key) { $hash->get( $key ) },
                },
                'delete' => +{
                    kind      => 'applicative',
                    signature => [ { name => 'hash' }, { name => 'key', coerce => 'stringify' } ],
                    impl      => sub ($hash, $key) {
                        my %hash = $hash->elements->%*;
                        delete $hash{ $key };
                        $terms->Hash( %hash );
                    },
                },
                'add' => +{
                    kind      => 'applicative',
                    signature => [
                        { name => 'hash' },
                        { name => 'key', coerce => 'stringify' },
                        { name => 'value' },
                    ],
                    impl      => sub ($hash, $key, $value) {
                        my %hash = $hash->elements->%*;
                        $hash{ $key } = $value;
                        $terms->Hash( %hash );
                    },
                },
                'keys' => +{
                    kind      => 'applicative',
                    signature => [ { name => 'hash' } ],
                    impl      => sub ($hash) {
                        $terms->List( map $terms->Str($_), keys $hash->elements->%* )
                    },
                },
                'values' => +{
                    kind      => 'applicative',
                    signature => [ { name => 'hash' } ],
                    impl      => sub ($hash) {
                        $terms->List( values $hash->elements->%* )
                    },
                },
            },
            'Role' => +{
                'compose' => +{
                    kind      => 'applicative',
                    signature => [ { name => 'r1' }, { name => 'r2' } ],
                    impl      => sub ($r1, $r2) { $roles->Union( $r1, $r2 ) }
                },
                'lookup' => +{
                    kind      => 'applicative',
                    signature => [ { name => 'role' }, { name => 'symbol' } ],
                    impl      => sub ($role, $sym) {
                        my $slot = $role->lookup( $sym->value );
                        if ($slot isa MXCL::Term::Role::Slot::Defined) {
                            return $slot->value;
                        }
                        return $terms->Nil;
                    }
                },
            },
            'ContextRef' => +{
                'compile' => +{
                    kind      => 'applicative',
                    signature => [ { name => 'ctx' }, { name => 'source' } ],
                    impl      => sub ($ctx, $source) {
                        $terms->List( $ctx->context->compile_source( $source->value )->@* );
                    }
                },
                'current-scope' => +{
                    kind      => 'applicative',
                    signature => [ { name => 'ctx' } ],
                    impl      => sub ($ctx) {
                        $ctx->context->current_scope
                    }
                },
            },
        };
    }

}
