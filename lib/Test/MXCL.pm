
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
        my $Tester = Test::Builder->new;

        local $Test::Builder::Level = $Test::Builder::Level + 6;

        my $context = MXCL::Context->new;
        my $runtime = $context->runtime;

        $runtime->natives->functions->{'Test/ok'} = +{
            kind      => 'applicative',
            signature => [{ name => 'got', coerce => 'boolify' }, { name => 'msg', coerce => 'stringify' }],
            returns   => 'Nil',
            impl      => sub ($got, $msg) { $Tester->ok( $got, $msg ) },
        };

        $runtime->natives->functions->{'Test/is'} = +{
            kind      => 'applicative',
            signature => [{ name => 'got' }, { name => 'expected' }, { name => 'msg', coerce => 'stringify' }],
            returns   => 'Nil',
            impl      => sub ($got, $expected, $msg) {
                if ($got->eq($expected)) {
                    $Tester->ok(true, $msg);
                } else {
                    $Tester->ok(false, $msg);
                    $Tester->diag("       got: ".$got->pprint);
                    $Tester->diag("  expected: ".$expected->pprint);
                }
            }
        };

        $runtime->natives->functions->{'Test/done-testing'} = +{
            kind      => 'applicative',
            signature => [],
            returns   => 'Nil',
            impl      => sub () { $Tester->done_testing }
        };

        my $test_header = q[
            ;; BEGIN TEST HEADER

            (bind ok (got msg) "Test/ok")
            (bind is (got expected msg) "Test/is")

            (bind done-testing () "Test/done-testing")

            ;; END TEST HEADER
        ];

        my $test = $context->compile_source($test_header.$source);

        return $context->evaluate( $context->base_scope, $test );
    }

}
