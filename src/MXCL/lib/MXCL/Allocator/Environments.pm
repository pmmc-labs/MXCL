
use v5.42;
use experimental qw[ class ];

use MXCL::Arena;

use MXCL::Term::Env;

class MXCL::Allocator::Environments {
    field $arena :param :reader;

    method Env (@args) {
        my $parent;
        if ($args[0] isa MXCL::Term::Env) {
            $parent = shift @args;
        }
        my %bindings = @args;
        $arena->allocate(MXCL::Term::Env::,
            bindings => \%bindings,
            ($parent ? (parent => $parent) : ()),
        );
    }

    ## -------------------------------------------------------------------------
    ## Env Utils
    ## -------------------------------------------------------------------------

    method BindParams ($parent, $params, $args) {
        die "Arity mismatch" if scalar @$params != scalar @$args;
        my %bindings = map { $_->value, shift @$args } @$params;
        return $arena->allocate(MXCL::Term::Env::,
            parent   => $parent,
            bindings => \%bindings,
        );
    }

    method Derive ($parent, %bindings) {
        $arena->allocate(MXCL::Term::Env::,
            parent   => $parent,
            bindings => \%bindings,
        );
    }
}
