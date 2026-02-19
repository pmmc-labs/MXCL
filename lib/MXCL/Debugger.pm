
use v5.42;
use utf8;
use open ':std', ':encoding(UTF-8)';
use experimental qw[ class ];


class MXCL::Debugger {
    use Time::HiRes qw[ sleep ];

    field $machine :param :reader;

    method DEBUG_STEP ($k, $last=false) {
        return;

        my sub clear_screen { "\e[2J" }
        my sub home_cursor  { "\e[H" }

        my sub format_reset               { "\e[0m" }
        my sub format_bg_color ($color)   { sprintf "\e[48;2;%d;%d;%d;m" => @$color }
        my sub format_fg_color ($color)   { sprintf "\e[38;2;%d;%d;%d;m" => @$color }
        my sub format_color    ($fg, $bg) { sprintf "\e[38;2;%d;%d;%d;48;2;%d;%d;%d;m"  => @$fg, @$bg }

        my sub take_n ($n, @args) {
            return @args unless scalar @args > $n;
            return @args[ 0 .. $n ];
        }

        say(clear_screen, home_cursor);
        say(
            format_fg_color([255, 0, 0]),
            (join "\n" => map { '^^ '.$_->pprint } $machine->queue->@*),
            format_fg_color([0, 255, 0]),
            (sprintf "\n@@ %s\n" => $k->pprint),
            format_fg_color([0, 0, 255]),
            (join "\n" => map { '__ '.$_->pprint } take_n( 20, reverse $machine->trace->@*)),
            "\n...",
            format_reset()
        );

        #my $x = <>;
        sleep(0.3);
    }

    method DUMP_TERM ($term, %opts) {}

}

__END__

# Debugging Step

Prints the following information:

- current Kontinue ($k)
- uses $machine reference to show:
    - remaining queue
    - trace

# Dumping Terms

Prints a table with the following columns:

- cons tree or leaf term
- term type
- term hash
- term generation

```
┌───────────────┬──────────┬──────────┬─────┐
│ > lambda      │ Lambda   │ 0b1e0e1e │ 001 │
│    > name     │ Sym      │ 7564b7e3 │ 001 │
│    > params   │ Cons     │ 1edc5815 │ 001 │
│        > x    │ Sym      │ 0818ff85 │ 001 │
│        > y    │ Sym      │ bcac42de │ 001 │
│    > body     │ Cons     │ 12acd310 │ 001 │
│        > x    │ Sym      │ 991d224d │ 001 │
│        > +    │ Sym      │ 01ae4300 │ 001 │
│        > y    │ Sym      │ 236d0f7c │ 001 │
└───────────────┴──────────┴──────────┴─────┘
```
