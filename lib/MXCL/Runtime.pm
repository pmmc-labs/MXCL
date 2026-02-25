
use v5.42;
use experimental qw[ class switch ];

use MXCL::Runtime::Natives;
use MXCL::Runtime::Prelude;

class MXCL::Runtime {
    field $base_scope :reader = undef;
    field $natives    :reader = undef;
    field $prelude    :reader = undef;

    # be lazy here
    method initialize ($context) {
        return $base_scope if defined $base_scope;

        $natives = MXCL::Runtime::Natives->new->initialize($context);
        $prelude = MXCL::Runtime::Prelude->new;

        my $terms = $context->terms;
        my $roles = $context->roles;

        $base_scope = $roles->Role(
            $roles->Defined(
                $terms->Sym('bind'),
                $terms->BindNative('bind', $natives->lookup('bind'))
            )
        );

        return $base_scope;

#
#        ## ---------------------------------------------------------------------
#        ## Core Roles
#        ## ---------------------------------------------------------------------
#
#        my $EQ = $roles->Role(
#            $roles->Required($terms->Sym('==')),
#            $roles->Defined(
#                $terms->Sym('!='),
#                $terms->Operative(
#                    name => '!=:EQ', signature => [{ name => 'n' },{ name => 'm' }],
#                    impl => sub ($ctx, $n, $m) {
#                        $konts->EvalExpr($ctx,
#                            # (not (n == m))
#                            $terms->List($terms->Sym('not'), $terms->List( $n, $terms->Sym('=='), $m )),
#                            $terms->Nil
#                        )
#                    }
#                )
#            )
#        );
#
#        my $ORD = $roles->Union(
#            $roles->Role(
#                $roles->Required($terms->Sym('==')),
#                $roles->Required($terms->Sym('>')),
#                $roles->Defined(
#                    $terms->Sym('>='),
#                    $terms->Operative(
#                        name => '>=:ORD', signature => [{ name => 'n' },{ name => 'm' }],
#                        impl => sub ($ctx, $n, $m) {
#                            $konts->EvalExpr($ctx,
#                                # ((n > m) || (n == m))
#                                $terms->List(
#                                    $terms->List( $n, $terms->Sym('>'), $m ),
#                                    $terms->Sym('||'),
#                                    $terms->List( $n, $terms->Sym('=='), $m )
#                                ),
#                                $terms->Nil
#                            )
#                        }
#                    )
#                ),
#                $roles->Defined(
#                    $terms->Sym('<'),
#                    $terms->Operative(
#                        name => '<:ORD', signature => [{ name => 'n' },{ name => 'm' }],
#                        impl => sub ($ctx, $n, $m) {
#                            $konts->EvalExpr($ctx,
#                                # (not ((n > m) || (n == m)))
#                                $terms->List(
#                                    $terms->Sym('not'),
#                                    $terms->List(
#                                        $terms->List( $n, $terms->Sym('>'), $m ),
#                                        $terms->Sym('||'),
#                                        $terms->List( $n, $terms->Sym('=='), $m )
#                                    )
#                                ),
#                                $terms->Nil
#                            )
#                        }
#                    )
#                ),
#                $roles->Defined(
#                    $terms->Sym('<='),
#                    $terms->Operative(
#                        name => '<=:ORD', signature => [{ name => 'n' },{ name => 'm' }],
#                        impl => sub ($ctx, $n, $m) {
#                            $konts->EvalExpr($ctx,
#                                # (not (n > m))
#                                $terms->List($terms->Sym('not'), $terms->List( $n, $terms->Sym('>'), $m )),
#                                $terms->Nil
#                            )
#                        }
#                    )
#                )
#            ),
#            $EQ
#        );
#
#        ## ---------------------------------------------------------------------
#        ## Core Literal Roles
#        ## ---------------------------------------------------------------------
#
#        my $Bool = $roles->Union(
#            $roles->Role(
#                $roles->Defined($terms->Sym('=='), binary_op('==:Bool', 'boolify', 'Bool', sub ($n, $m) { $n == $m })),
#                $roles->Defined($terms->Sym('&&'), $and),
#                $roles->Defined($terms->Sym('||'), $or),
#            ),
#            $EQ
#        );
#
#        my $Num = $roles->Union(
#            $roles->Role(
#                $roles->Defined($terms->Sym('=='), binary_op('==:Num', 'numify', 'Bool', sub ($n, $m) { $n == $m })),
#                $roles->Defined($terms->Sym('>'),  binary_op('>:Num',  'numify', 'Bool', sub ($n, $m) { $n >  $m })),
#                $roles->Defined($terms->Sym('+'),  binary_op('+:Num',  'numify', 'Num',  sub ($n, $m) { $n + $m })),
#                $roles->Defined($terms->Sym('-'),  binary_op('-:Num',  'numify', 'Num',  sub ($n, $m) { $n - $m })),
#                $roles->Defined($terms->Sym('*'),  binary_op('*:Num',  'numify', 'Num',  sub ($n, $m) { $n * $m })),
#                $roles->Defined($terms->Sym('/'),  binary_op('/:Num',  'numify', 'Num',  sub ($n, $m) { $n / $m })),
#                $roles->Defined($terms->Sym('%'),  binary_op('%:Num',  'numify', 'Num',  sub ($n, $m) { $n % $m })),
#            ),
#            $ORD
#        );
#
#        my $Str = $roles->Union(
#            $roles->Role(
#                $roles->Defined($terms->Sym('=='), binary_op('==:Str', 'stringify', 'Bool', sub ($n, $m) { $n eq $m })),
#                $roles->Defined($terms->Sym('>'),  binary_op('>:Str',  'stringify', 'Bool', sub ($n, $m) { $n gt $m })),
#                $roles->Defined($terms->Sym('~'),  binary_op('~:Str',  'stringify', 'Str',  sub ($n, $m) { $n . $m })),
#            ),
#            $ORD
#        );
#
#        ## ---------------------------------------------------------------------
#        ## Core Datatypes
#        ## ---------------------------------------------------------------------
#
#
#        my $Role = $roles->Union(
#            $roles->Role(
#                $roles->Defined($terms->Sym('=='), $eq),
#                $roles->Defined($terms->Sym('+'),
#                    $terms->Applicative(
#                        name      => '+:Role',
#                        signature => [ { name => 'r1' }, { name => 'r2' } ],
#                        impl      => sub ($r1, $r2) { $roles->Union( $r1, $r2 ) }
#                    )
#                ),
#            ),
#            $EQ
#        );
#
#
#        my $Array = $roles->Role(
#            $roles->Defined($terms->Sym('length'),
#                $terms->Applicative(
#                     name      => 'length:Array',
#                     signature => [ { name => 'array' } ],
#                     impl      => sub ($array) { $terms->Num( $array->length ) }
#                )
#            ),
#            $roles->Defined($terms->Sym('at'),
#                $terms->Applicative(
#                     name      => 'at:Array',
#                     signature => [ { name => 'array' }, { name => 'index', coerce => 'numify' } ],
#                     impl      => sub ($array, $index) { $array->at( $index ) }
#                )
#            )
#        );
#
#        # ...
#
#
#        my $Hash = $roles->Role(
#            $roles->Defined($terms->Sym('length'),
#                $terms->Applicative(
#                     name      => 'length:Hash',
#                     signature => [ { name => 'hash' } ],
#                     impl      => sub ($hash) { $terms->Num( $hash->length ) }
#                )
#            ),
#            $roles->Defined($terms->Sym('at'),
#                $terms->Applicative(
#                    name      => 'at:Hash',
#                    signature => [ { name => 'hash' }, { name => 'index', coerce => 'stringify' } ],
#                    impl      => sub ($hash, $index) { $hash->at( $index ) }
#                )
#            )
#        );
#
#        # ...
#
#        my $Ref = $roles->Role(
#            $roles->Defined($terms->Sym('get'),
#                $terms->Applicative(
#                     name      => 'get:Ref',
#                     signature => [ { name => 'ref' } ],
#                     impl      => sub ($ref) { $terms->Deref($ref) }
#                )
#            ),
#            $roles->Defined($terms->Sym('set!'),
#                $terms->Applicative(
#                    name      => 'set:Ref',
#                    signature => [ { name => 'ref' }, { name => 'value' } ],
#                    impl      => sub ($ref, $value) { $terms->SetRef($ref, $value) }
#                )
#            )
#        );
#
#        ## ---------------------------------------------------------------------
#        ## Base Scope ...
#        ## ---------------------------------------------------------------------
#
#        $base_scope = $roles->Role(
#            $roles->Defined($terms->Sym('bind'),              $bind),
#            $roles->Defined($terms->Sym('define'),            $define),
#            $roles->Defined($terms->Sym('let'),               $let),
#            $roles->Defined($terms->Sym('lambda'),            $lambda),
#            $roles->Defined($terms->Sym('role'),              $role),
#            $roles->Defined($terms->Sym('if'),                $if),
#            $roles->Defined($terms->Sym('do'),                $do),
#            $roles->Defined($terms->Sym('while'),             $while),
#            $roles->Defined($terms->Sym('eq?'),               $eq),
#            $roles->Defined($terms->Sym('not'),               $not),
#            $roles->Defined($terms->Sym('and'),               $and),
#            $roles->Defined($terms->Sym('or'),                $or),
#            $roles->Defined($terms->Sym('nil?'),              $is_nil),
#            $roles->Defined($terms->Sym('bool?'),             $is_bool),
#            $roles->Defined($terms->Sym('num?'),              $is_num),
#            $roles->Defined($terms->Sym('str?'),              $is_str),
#            $roles->Defined($terms->Sym('sym?'),              $is_sym),
#            $roles->Defined($terms->Sym('lambda?'),           $is_lambda),
#            $roles->Defined($terms->Sym('array?'),            $is_array),
#            $roles->Defined($terms->Sym('ref?'),              $is_ref),
#            $roles->Defined($terms->Sym('opaque?'),           $is_opaque),
#            $roles->Defined($terms->Sym('role?'),             $is_role),
#            $roles->Defined($terms->Sym('make-opaque'),       $make_opaque),
#            $roles->Defined($terms->Sym('make-role'),         $make_role),
#            $roles->Defined($terms->Sym('make-array'),        $make_array),
#            $roles->Defined($terms->Sym('make-hash'),         $make_hash),
#            $roles->Defined($terms->Sym('make-ref'),          $make_ref),
#            # TODO - define these in the prelude
#            $roles->Defined($terms->Sym('MXCL::Term::Bool'),  $Bool),
#            $roles->Defined($terms->Sym('MXCL::Term::Num'),   $Num),
#            $roles->Defined($terms->Sym('MXCL::Term::Str'),   $Str),
#            $roles->Defined($terms->Sym('MXCL::Term::Ref'),   $Ref),
#            $roles->Defined($terms->Sym('MXCL::Term::Array'), $Array),
#            $roles->Defined($terms->Sym('MXCL::Term::Hash'),  $Hash),
#            $roles->Defined($terms->Sym('MXCL::Term::Role'),  $Role),
#            $roles->Defined($terms->Sym('<EQ>'),              $EQ),
#            $roles->Defined($terms->Sym('<ORD>'),             $ORD),
#        );
    }

}
