
use v5.42;
use utf8;
use open ':std', ':encoding(UTF-8)';
use experimental qw[ class switch ];

use P5::TUI::Table;

# FIXME:
# remove the P5::TUI::Table dependency

class MXCL::Debugger {
    field $machine :param :reader;

    method DEBUG_STEP ($k, $final=false) {
        my @rows = map {
            [
                (sprintf '%03d' => $k->env->bindings->{$_}->gen),
                $_,
                $k->env->bindings->{$_}->stringify,
                $k->env->bindings->{$_}->hash
            ]
        } sort { $k->env->bindings->{$b}->gen <=> $k->env->bindings->{$a}->gen }
          keys $k->env->bindings->%*;

        my $env_table = P5::TUI::Table->new(
            column_spec => [
                {
                    name  => (sprintf '%03d' => $k->env->gen),
                    width => 3,
                    align => 1,
                    color => { fg => 'green', bg => undef }
                },
                {
                    name  => '',
                    width => '20%',
                    align => 1,
                    color => { fg => 'cyan', bg => undef }
                },
                {
                    name  => $k->env->name->stringify,
                    width => '80%',
                    align => 1,
                    color => { fg => 'white', bg => undef }
                },
                {
                    name  => $k->env->hash,
                    width => '32',
                    align => 1,
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
