#!perl

use v5.42;

use Test::More;
use MXCL::Context;

my $source = q[
    (diag "lambda produces a Lambda term")
    (ok (lambda? (lambda (x) x))         "... anonymous lambda is a lambda term")
    (ok (lambda? (lambda (x y) (x + y))) "... two-arg lambda is a lambda term")

    (diag "let + lambda: let evaluates its value, so the name is bound to the Lambda")
    (let id (lambda (x) x))
    (ok (lambda? id) "... let-bound lambda is a lambda term")
    (is (id 42) 42   "... identity lambda returns its argument")

    (diag "basic lambda application")
    (let double (lambda (x) (x + x)))
    (is (double 0)  0  "... double 0 = 0")
    (is (double 5) 10  "... double 5 = 10")
    (is (double 7) 14  "... double 7 = 14")

    (diag "applicative semantics: arguments are evaluated before the body runs")
    (let double2 (lambda (x) (x + x)))
    (is (double2 (2 + 3))  10 "... arg (2+3) evaluated to 5 before call; double 5 = 10")
    (is (double2 (10 - 4)) 12 "... arg (10-4) evaluated to 6 before call; double 6 = 12")

    (diag "multi-arg lambda")
    (let add (lambda (x y) (x + y)))
    (is (add 3 4)   7  "... add 3 4 = 7")
    (is (add 0 99) 99  "... add 0 99 = 99")
    (is (add 10 10) 20 "... add 10 10 = 20")

    (diag "closure: lambda captures its defining environment")
    (let base 100)
    (let add-base (lambda (x) (x + base)))

    (is (add-base 5)   105 "... closure captures base = 100; add-base 5 = 105")
    (is (add-base 42)  142 "... same closure, different arg; add-base 42 = 142")
    (is (add-base 0)   100 "... add-base 0 = 100")

    (diag "lambda as a value: can be passed to another lambda")
    (let apply-twice (lambda (f x) (f (f x))))
    (let inc (lambda (n) (n + 1)))

    (is (apply-twice inc 0) 2  "... apply-twice inc 0 = 2")
    (is (apply-twice inc 5) 7  "... apply-twice inc 5 = 7")

    (diag "lambda? confirms both paths at the MXCL level")
    (ok (lambda? (lambda (x) x))         "... lambda expression produces a Lambda term")
    (ok (lambda? (lambda (x y) (x + y))) "... multi-arg lambda is also a Lambda term")
    (let h (lambda (x) x))
    (ok (lambda? h) "... let-bound lambda is a Lambda term")
    (ok (not (lambda? 42)) "... number is not lambda")

    (diag "closures: make-adder returns a lambda that closes over n")
    (define make-adder (n)
        (lambda (x) (x + n)))
    (let add-5  (make-adder 5))
    (let add-10 (make-adder 10))
    (is (add-5  3) 8  "... closure captures n=5")
    (is (add-10 3) 13 "... closure captures n=10")

    (diag "define with do body")
    (define complex (x)
        (do
            (let doubled (x * 2))
            (doubled + 1)))
    (is (complex 5) 11 "... define with do block body")

    (diag "applicative: the arg expression is evaluated before the body sees it")
    (define square (x) (x * x))
    (is (square (2 + 3)) 25 "... applicative: arg (2+3) evaluated to 5 before call")

    (diag "operative: the dead branch is never evaluated")
    (ok (if true  true  (1 / 0)) "... operative if: false-branch (1/0) never evaluated")
    (ok (if false (1 / 0) true)  "... operative if: true-branch  (1/0) never evaluated")

    (diag "operative short-circuit: and and or also skip evaluation")
    (ok      (and true  true)       "... and true  true  => true")
    (ok (not (and false (1 / 0)))   "... operative and: rhs (1/0) not evaluated when lhs is false")
    (ok      (or  true  (1 / 0))    "... operative or:  rhs (1/0) not evaluated when lhs is true")

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
