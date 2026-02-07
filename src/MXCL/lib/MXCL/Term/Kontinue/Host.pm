
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Kontinue::Host :isa(MXCL::Term::Kontinue) {
    field $effect :param :reader = undef;
    field $config :param :reader = +{};
}
