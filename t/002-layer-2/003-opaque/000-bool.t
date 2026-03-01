#!perl

use v5.42;

use Test::More;
use MXCL::Context;

# Autoboxed dispatch on Bool: (bool-term method ...args)
# The machine looks up MXCL::Term::Bool in the env to find the Bool role,
# then dispatches the named method with `self` as the first argument.

my $source = q[
    (diag "equality")
    (ok (true  == true)   "... true  == true")
    (ok (false == false)  "... false == false")

    (ok (not (true  == false)) "... not true  == false")
    (ok (not (false == true))  "... not false == true")

    (diag "inequality (derived from EQ role via !=)")
    (ok (true  != false)  "... true  != false")
    (ok (false != true)   "... false != true")

    (ok (not (true  != true))  "... not true  != true")
    (ok (not (false != false)) "... not false != false")

    (diag "conjunction (&&)")
    (ok      (true  && true)   "... true  && true  => true")
    (ok (not (true  && false)) "... true  && false => false")
    (ok (not (false && true))  "... false && true  => false")
    (ok (not (false && false)) "... false && false => false")

    (diag "disjunction (||)")
    (ok      (true  || true)   "... true  || true  => true")
    (ok      (true  || false)  "... true  || false => true")
    (ok      (false || true)   "... false || true  => true")
    (ok (not (false || false)) "... false || false => false")

    (done-testing)
];

my $context = MXCL::Context->new->initialize;
try {
    my $result = $context->evaluate(
        $context->base_scope,
        $context->compile_source($source)
    );
} catch ($e) {
    BAIL_OUT($e);
}
