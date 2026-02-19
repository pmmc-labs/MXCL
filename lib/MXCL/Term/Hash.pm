
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Hash :isa(MXCL::Term) {
    field $elements :param :reader;

    method length { scalar keys %$elements }

    method get ($key) { $elements->{$key} }

    method keys   {   keys %$elements }
    method values { values %$elements }

    method stringify {
        sprintf '+{%s}' =>
            join ', ' =>
                map {
                    sprintf ':%s => %s' => $_, $elements->{$_}->stringify
                } keys %$elements
    }

    method pprint {
        sprintf '+{%s}' =>
            join ', ' =>
                map {
                    sprintf ':%s %s' => $_, $elements->{$_}->pprint
                } keys %$elements
    }
}
