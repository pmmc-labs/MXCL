
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Kontinue::Host :isa(MXCL::Term::Kontinue) {
    field $effect :param :reader = undef;
    field $config :param :reader = +{};

    # TODO: effect and config are not proper Term fields yet, so they are
    # excluded from DECOMPOSE and the inherited COMPOSE only hashes env+stack.
}
