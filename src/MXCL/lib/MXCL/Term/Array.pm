
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Array :isa(MXCL::Term) {
    field $elements :param :reader;

    method length { scalar @$elements }

    method at ($index) { $elements->[$index] }

    method to_string {
        sprintf '[%s]' => join ', ' => map $_->to_string, @$elements
    }
}
