
use v5.42;
use utf8;
use open ':std', ':encoding(UTF-8)';
use experimental qw[ class switch ];

use P5::TUI::Table;

class MXCL::Debugger {
    field $machine :param :reader;

    method DEBUG_STEP ($k, $final=false) {
        my @rows = map {
            [
                $_,
                $k->env->bindings->{$_}->stringify
            ]
        } sort { $a cmp $b }
          keys $k->env->bindings->%*;

        my $env_table = P5::TUI::Table->new(
            column_spec => [
                {
                    name  => $k->env->hash,
                    width => 32,
                    align => -1,     # right-aligned
                    color => { fg => 'cyan', bg => undef }
                },
                {
                    name  => $k->env->name->stringify,
                    width => '100%',  # Percentage of available space
                    align => 1,      # Left-aligned
                    color => { fg => 'white', bg => undef }
                },
            ],
            rows => \@rows
        );

        my $lines = $env_table->draw( width => '80%', height => (2 * scalar @rows) );

        say '-' x 120;
        if ($final) {
            say sprintf "DONE[%03d]" => $machine->steps;
        } else {
            say sprintf "STEP[%03d]" => $machine->steps;
        }
        say " -> ", $k->pprint;
        if ($machine->queue->@*) {
            say "  - ", join "\n  - " => map blessed $_ ? $_->pprint : $_, reverse $machine->queue->@*;
        }
        say for $lines->@*;
    }

}
