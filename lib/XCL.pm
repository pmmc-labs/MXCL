
use v5.42;

package XCL {
    use v5.42;
    use utf8;
    use open ':std', ':encoding(UTF-8)';
    use experimental qw[ switch ];

    $|++;

    use MXCL::Context;
    use MXCL::Debugger;

    sub import (@) {
        no strict 'refs';
        *{"main::run"}      = \&run;
        *{"main::execute"}  = \&execute;
        *{"main::evaluate"} = \&evaluate;
    }

    sub run (%options) {
        my ($file) = @ARGV;
        return execute( $file, %options )
    }

    sub execute ($file, %options) {
        my $source = join '' => IO::File->new($file, '<')->getlines;
        return evaluate( $source, %options );
    }

    sub evaluate ($source, %options) {
        my $context = MXCL::Context->new->initialize;
        my $program = $context->compile_source( $source );

        if ($options{show_program}) {
            say "PROGRAM:";
            say '─' x MXCL::Debugger::TERMINAL_WIDTH;
            MXCL::Debugger->visualize_term( $context, $_ )
                foreach @$program;
        }

        try {
            my $result = $context->evaluate( $context->base_scope, $program );

            if ($options{show_result}) {
                say "RESULT:";
                say '─' x MXCL::Debugger::TERMINAL_WIDTH;
                MXCL::Debugger->visualize_term( $context, $result->stack );
            }

            return $result;
        } catch ($e) {
            die "GOT ERROR! ",$e;
        }
    }
}


=pod

=head SYNOPSIS

    > perl -I lib -MXCL -E 'evaluate(q[ (print ("Hello World" ~ "\n")) ])'
    Hello World

    > echo '(print ("Hello World" ~ "\\n"))' > test.mxcl
    > perl -I lib -MXCL -E "execute('test.mxcl')"
    Hello World

    > perl -I lib -MXCL -E run test.mxcl
    Hello World

=cut
