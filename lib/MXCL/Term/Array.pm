
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Array :isa(MXCL::Term) {
    field $elements :param :reader;

    method length { scalar @$elements }

    method at ($index) { $elements->[$index] }

    method stringify {
        sprintf '+[%s]' => join ', ' => map $_->stringify, @$elements
    }

    method pprint {
        sprintf '+[%s]' => join ', ' => map $_->stringify, @$elements
    }
}
