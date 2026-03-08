#!perl

use v5.42;
use utf8;
use open ':std', ':encoding(UTF-8)';
use experimental qw[ class switch ];

use Caroline;
use MXCL::Context;

my $banner = q[


];

sub scope_changes ($context, $base_scope, $scope) {
    my @scopes = $context->scope_stack;

    return $context->roles->Difference(
        $context->roles->AsymmetricDifference( $base_scope, $scope ),
        $base_scope,
    );
}

my $history_file = '.repl-history';

my $running = true;

$SIG{INT} = sub { $running = false };

my $context = MXCL::Context->new->initialize;

my %options = (
    visualize  => false,
    show_scope => false,
);

my $base_scope = $context->current_scope;
my $scope      = $base_scope;

my $c = Caroline->new;

$c->read_history_file( $history_file ) if -e $history_file;

while ($running && defined(my $line = $c->readline('> '))) {
    if ($line =~ /\S/) {

        $c->history_add($line);

        given ($line) {
            when(':show-scope') { $options{show_scope} = true  }
            when(':hide-scope') { $options{show_scope} = false }
            when(':show-viz')   { $options{visualize}  = true  }
            when(':hide-viz')   { $options{visualize}  = false }
            # ...
            when([qw[ :quit :q ]]) { $running = false }
            when([qw[ :help :h ]]) {
                say "── help ", '─' x (MXCL::Debugger::TERMINAL_WIDTH - 8);
                say join "\n" => (
                    '  > $expression - enter an expression and print the results',
                    '    :show-scope - print the current scope after each expression',
                    '    :hide-scope - turns off the current scope printing',
                    '    :show-viz   - more colorful output',
                    '    :hide-viz   - more boring output',
                    '    :help :h    - this screen',
                    '    :quit :q    - exit the loop',
                )
            }
            default {
                try {
                    my $program = $context->compile_source( $line );
                    my $result = $context->evaluate( $scope, $program );

                    $scope = $result->env;

                    if ($options{show_scope}) {
                        if ($options{visualize}) {
                            say "── scope ", '─' x (MXCL::Debugger::TERMINAL_WIDTH - 9);
                            MXCL::Debugger->visualize_term(
                                $context,
                                scope_changes( $context, $base_scope, $scope )
                            );
                        } else {
                            say scope_changes( $context, $base_scope, $scope )->pprint;
                        }
                    }

                    if ($options{visualize}) {
                        say "── result ", '─' x (MXCL::Debugger::TERMINAL_WIDTH - 10);
                        MXCL::Debugger->visualize_term( $context, $result->stack );
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
        say '─' x MXCL::Debugger::TERMINAL_WIDTH
    }
}

$c->write_history_file( $history_file ) if $history_file;

exit();
