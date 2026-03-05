
use v5.42;
use utf8;
use open ':std', ':encoding(UTF-8)';
use experimental qw[ class ];

use MXCL::Debugger::Tape;
use MXCL::Debugger::Term;
use MXCL::Debugger::Scope;
use MXCL::Debugger::Arena;

class MXCL::Debugger {
    use constant DEBUG       => !!$ENV{DEBUG};
    use constant DEBUG_SCOPE => !!$ENV{DEBUG_SCOPE};

    our %KONTINUE_COLORS;
    our (
        $TAPE_DEBUGGER,
        $TERM_DEBUGGER,
        $SCOPE_DEBUGGER,
        $ARENA_DEBUGGER,
    );
    BEGIN {
        %KONTINUE_COLORS = (
            Host    => [   1, 2 ],    # ??
            Return  => [ 159, 30 ],   # GREEN
            Discard => [ 159, 30 ],   # GREEN
            Capture => [ 159, 30 ],   # GREEN
            Define  => [  17, 45 ],   # LIGHTBLUE
            IfElse  => [  45, 19 ],   # BLUE
            DoWhile => [  45, 19 ],   # BLUE
            Eval    => [ 210, 52 ],   # RED
            Apply   => [ 130, 214 ],  # ORANGE
            Scope   => [  59, 230  ], # WHITE
        );

        $TAPE_DEBUGGER = MXCL::Debugger::Tape->new(
            options => +{
                filter_kontinue_types  => exists $ENV{DEBUG_FILTER} ? qr/$ENV{DEBUG_FILTER}/ : undef,
                expand_kontinue_fields => exists $ENV{DEBUG_FIELDS} ? !!$ENV{DEBUG_FIELDS}   : true,
                expand_kontinue_stack  => exists $ENV{DEBUG_STACK}  ? !!$ENV{DEBUG_STACK}    : true,
                show_arena_stats       => exists $ENV{DEBUG_ARENA}  ? !!$ENV{DEBUG_ARENA}    : true,

            }
        );

        $TERM_DEBUGGER  = MXCL::Debugger::Term->new;
        $SCOPE_DEBUGGER = MXCL::Debugger::Scope->new;
        $ARENA_DEBUGGER = MXCL::Debugger::Arena->new;
    }

    sub monitor_tape_advance ($, $ctx, $tape, $k, $next) {
        $TAPE_DEBUGGER->monitor_tape_advance($ctx, $tape, $k, $next)
    }

    sub visualize_term ($, $ctx, $term, %options) {
        $TERM_DEBUGGER->visualize_term($ctx, $term, %options)
    }

    sub visualize_scope ($, $ctx, %options) {
        $SCOPE_DEBUGGER->visualize_scope($ctx, %options)
    }

    sub visualize_arena ($, $ctx, %options) {
        $ARENA_DEBUGGER->visualize_arena($ctx, %options)
    }
}

