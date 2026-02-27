
use v5.42;

package XCL {
    use v5.42;
    use experimental qw[ switch ];

    use MXCL::Context;

    sub import (@) {
        no strict 'refs';
        *{"main::run"}      = \&run;
        *{"main::execute"}  = \&execute;
        *{"main::evaluate"} = \&evaluate;
    }

    sub run {
        my ($file) = @ARGV;
        return execute($file)
    }

    sub execute ($file) {
        my $source = join '' => IO::File->new($file, '<')->getlines;
        return evaluate( $source );
    }

    sub evaluate ($source) {
        my $context = MXCL::Context->new->initialize;
        return $context->evaluate(
            $context->base_scope,
            $context->compile_source( $source )
        );
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
