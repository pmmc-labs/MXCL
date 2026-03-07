#!perl

use v5.42;
use utf8;
use open ':std', ':encoding(UTF-8)';
use experimental qw[ class switch ];

use Caroline;
use MXCL::Context;

sub scope_changes ($context, $base_scope, $scope) {
    my @scopes = $context->scope_stack;

    return $context->roles->Difference(
        $context->roles->AsymmetricDifference( $base_scope, $scope ),
        $base_scope,
    );
}

my $context = MXCL::Context->new->initialize;

my %options = (
    visualize  => false,
    show_scope => false,
);

my $base_scope = $context->current_scope;
my $scope      = $base_scope;

my $c = Caroline->new;

while (defined(my $line = $c->readline('> '))) {
    if ($line =~ /\S/) {

        $options{show_scope} = true  if $line eq ':show-scope';
        $options{show_scope} = false if $line eq ':hide-scope';

        $options{visualize} = true  if $line eq ':show-viz';
        $options{visualize} = false if $line eq ':hide-viz';

        try {
            my $program = $context->compile_source( $line );
            my $result = $context->evaluate( $scope, $program );

            $scope = $result->env;

            if ($options{show_scope}) {
                if ($options{visualize}) {
                    say '─' x MXCL::Debugger::TERMINAL_WIDTH;
                    say "SCOPE:";
                    say '─' x MXCL::Debugger::TERMINAL_WIDTH;
                    MXCL::Debugger->visualize_term(
                        $context,
                        scope_changes( $context, $base_scope, $scope )
                    );
                    say '─' x MXCL::Debugger::TERMINAL_WIDTH;
                } else {
                    say scope_changes( $context, $base_scope, $scope )->pprint;
                }
            }

            if ($options{visualize}) {
                say '─' x MXCL::Debugger::TERMINAL_WIDTH;
                say "RESULT:";
                say '─' x MXCL::Debugger::TERMINAL_WIDTH;
                MXCL::Debugger->visualize_term( $context, $result->stack );
                say '─' x MXCL::Debugger::TERMINAL_WIDTH;
            } else {
                if ($result->stack isa MXCL::Term::Nil) {
                    say '#nil'
                } else {
                    say join ' ' => map $_->pprint, $result->stack->uncons;
                }
            }

        } catch ($e) {
            say "GOT ERROR! ",$e;
        }
    }
}
