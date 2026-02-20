
use v5.42;

package Test::MXCL {
    use v5.42;
    use experimental qw[ class ];

    use Test::Builder ();

    use MXCL::Context;
    use MXCL::Runtime;

    # --------------------------------------------------------------------------

    sub import ($, @) {
        my $from = caller;

        no strict 'refs';
        *{"${from}::${_}"} = \&{"Test::MXCL::${_}"} foreach qw[
            ctx
            arena
            terms
            roles
            compiler
            parser
            runtime

            test_mxcl
        ];
    }

    # --------------------------------------------------------------------------

    sub ctx      { state $CTX //= MXCL::Context->new }
    sub arena    { ctx->arena }
    sub terms    { ctx->terms }
    sub roles    { ctx->roles }
    sub compiler { ctx->compiler }
    sub parser   { ctx->parser }
    sub runtime  { ctx->runtime }

    # --------------------------------------------------------------------------

    sub test_mxcl ($source) {
        state $Tester = Test::Builder->new;

        local $Test::Builder::Level = $Test::Builder::Level + 6;

        state $context = ctx;
        state $runtime = $context->runtime;
        state $terms   = $context->terms;
        state $roles   = $context->roles;

        my sub wrap_slot ($name, $args, $body) {
            $roles->Defined(
                $terms->Sym( $name ),
                $terms->Applicative(
                    name      => $name,
                    signature => $args,
                    returns   => 'Nil',
                    impl      => $body,
                )
            )
        }

        state $testing_scope = $roles->Union(
            $roles->Role(
                wrap_slot('ok', [{ name => 'got', coerce => 'boolify' }, { name => 'msg', coerce => 'stringify' }],
                    sub ($got, $msg) { $Tester->ok( $got, $msg ) }
                ),
                wrap_slot('is', [{ name => 'got' }, { name => 'expected' }, { name => 'msg', coerce => 'stringify' }],
                    sub ($got, $expected, $msg) {
                        if ($got->eq($expected)) {
                            $Tester->ok(true, $msg);
                        } else {
                            $Tester->ok(false, $msg);
                            $Tester->diag("       got: ".$got->pprint);
                            $Tester->diag("  expected: ".$expected->pprint);
                        }
                    }
                ),
                wrap_slot('done-testing', [], sub () { $Tester->done_testing }),
            ),
            $context->base_scope
        );

        my $test = $context->compile_source($source);

        return $context->evaluate( $testing_scope, $test );
    }

}
