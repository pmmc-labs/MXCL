
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

    sub ctx      { state $CTX //= MXCL::Context->new->initialize }
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

        state $context = MXCL::Context->new->initialize;
        state $runtime = do {
            my $r = $context->runtime;

            $r->primitives->functions->{'Test/ok'} = +{
                kind      => 'applicative',
                signature => [{ name => 'got', coerce => 'boolify' }, { name => 'msg', coerce => 'stringify' }],
                returns   => 'Nil',
                impl      => sub ($got, $msg) { $Tester->ok( $got, $msg ) },
            };

            $r->primitives->functions->{'Test/is'} = +{
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

            $r->primitives->functions->{'Test/done-testing'} = +{
                kind      => 'applicative',
                signature => [],
                returns   => 'Nil',
                impl      => sub () { $Tester->done_testing }
            };

            $r;
        };

        my $test_header = q[
            ;; BEGIN TEST HEADER

            (bind ok (got msg) "Test/ok")
            (bind is (got expected msg) "Test/is")

            (bind done-testing () "Test/done-testing")

            ;; END TEST HEADER
        ];

        my $test = $context->compile_source($test_header.$source);

        try {
            return $context->evaluate( $context->base_scope, $test );
        } catch ($e) {
            #say "TRACE:";
            say "TAPES? ", join "\n" => map $_->pprint, $context->tape->tapes->[-1]->exprs->@*;
            say join "\n" => map $_->pprint, $context->tape->tapes->[-1]->trace->@*;
            die "GOT ERROR! ",$e;
        }
    }

}
