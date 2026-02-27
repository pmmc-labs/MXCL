
use v5.42;
use experimental qw[ class ];

class MXCL::Runtime::Prelude {
    field $filename :reader :param = undef;
    field $source   :reader = undef;
    field $artifact :reader = undef;

    method initialize ($context) {
        $filename //= __FILE__ =~ s/\.pm$/\.mxcl/r;
        $source   //= join '' => IO::File->new($filename, '<')->getlines;
        $artifact //= $context->compile_source( $source );
        return $self;
    }
}
