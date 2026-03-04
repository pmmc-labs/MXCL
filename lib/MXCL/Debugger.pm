
use v5.42;
use utf8;
use open ':std', ':encoding(UTF-8)';
use experimental qw[ class ];

use MXCL::Debugger::Tape;

class MXCL::Debugger {
    use constant DEBUG => !!$ENV{DEBUG};

    our %KONTINUE_COLORS;
    our $TAPE_DEBUGGER;
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
    }

    sub monitor_tape_advance ($, $ctx, $tape, $k, $next) {
        return unless DEBUG;
        $TAPE_DEBUGGER->monitor_tape_advance($ctx, $tape, $k, $next)
    }
}

__END__
    use Time::HiRes   qw[ sleep ];
    use Term::ReadKey qw[ GetTerminalSize ];
    use List::Util    qw[ min max ];
    use Data::Dumper  qw[ Dumper ];

    use constant BLACK   => { normal => [ 30, 40 ], bright => [ 90, 100 ] };
    use constant RED     => { normal => [ 31, 41 ], bright => [ 91, 101 ] };
    use constant GREEN   => { normal => [ 32, 42 ], bright => [ 92, 102 ] };
    use constant YELLOW  => { normal => [ 33, 43 ], bright => [ 93, 103 ] };
    use constant BLUE    => { normal => [ 34, 44 ], bright => [ 94, 104 ] };
    use constant MAGENTA => { normal => [ 35, 45 ], bright => [ 95, 105 ] };
    use constant CYAN    => { normal => [ 36, 46 ], bright => [ 96, 106 ] };
    use constant WHITE   => { normal => [ 37, 47 ], bright => [ 97, 107 ] };

    my sub clamp ($min, $max, $value) { max( $min, min( $max, int($value) )) }

    my sub clear_screen { "\e[2J" }
    my sub home_cursor  { "\e[H"  }
    my sub reset_style  { "\e[0m" }

    my sub core_bg_color ($color) { sprintf "\e[%dm" => $color->[0] }
    my sub core_fg_color ($color) { sprintf "\e[%dm" => $color->[1] }
    my sub core_color    ($color) { sprintf "\e[%d;%dm"  => @$color }

    my sub c256_bg_color ($color)   { sprintf "\e[48;5;%dm" => $color }
    my sub c256_fg_color ($color)   { sprintf "\e[38;5;%dm" => $color }
    my sub c256_color    ($fg, $bg) { sprintf "\e[38;5;%d;48;5;%dm" => $fg, $bg }

    #   0-7   : standard colors (as in ESC [ 30–37 m)
    #   8–15  : high intensity colors (as in ESC [ 90–97 m)
    #  16-231 : 6 × 6 × 6 cube (216 colors)
    # 232-255 : grayscale from dark to light in 24 steps.

    my sub cube216 ($color)   { clamp( 0, 216, $color ) + 16  }
    my sub greyscale ($scale) { clamp( 0,  24, $scale ) + 232 }

    my sub rgb_bg_color ($color)   { sprintf "\e[48;2;%d;%d;%d;m" => @$color }
    my sub rgb_fg_color ($color)   { sprintf "\e[38;2;%d;%d;%d;m" => @$color }
    my sub rgb_color    ($fg, $bg) { sprintf "\e[38;2;%d;%d;%d;48;2;%d;%d;%d;m"  => @$fg, @$bg }

    my sub fg_color ($color, $string) {
        return sprintf '%s%s%s' =>
            (ref $color
                ? scalar @$color == 3
                    ? rgb_fg_color($color)
                    : core_fg_color($color)
                : c256_fg_color($color)
            ),
            $string,
            reset_style;
    }

    my sub bg_color ($color, $string) {
        return sprintf '%s%s%s' =>
            (ref $color
                ? scalar @$color == 3
                    ? rgb_bg_color($color)
                    : core_bg_color($color)
                : c256_bg_color($color)
            ),
            $string,
            reset_style;
    }

    my sub color ($color, $string) {
        return sprintf '%s%s%s' =>
            (ref $color
                ? scalar @$color == 3
                    ? rgb_color($color)
                    : core_color($color)
                : c256_color($color)
            ),
            $string,
            reset_style;
    }

    my sub colorize ($string, $bg=false) {
        state %seen;
        my $color = [ map { clamp( 100, 255, rand() * 205 ) } qw[ r g b ] ];
        #die Dumper $color;
        $seen{$string} //= $bg ? bg_color( $color, $string ) : fg_color( $color, $string )
    }

    my sub shorten_hash ($hash) { substr $hash, 0, 8 }
    my sub shorten_type ($type) {
        my $short = $type =~ s/^MXCL\:\:Term\:\://r;
        $short =~ s/^Kontinue\:\://;
        $short =~ s/^Role\:\://;
        return $short;
    }

    my sub pad ($string, $length, $on_end=false) {
        my $left = $length - length($string);
        my $pad = $left > 0 ? ' ' x $left : '';
        return $on_end ? $string.$pad : $pad.$string;
    }

    my sub trim ($string, $length) {
        return $string if length $string <= $length;
        return substr($string, 0, ($length - 4)).'...';
    }

    sub get_terminal_size { GetTerminalSize() }

    my ($width, $height) = get_terminal_size;

    ## -------------------------------------------------------------------------

    sub traverse_term ($root, $f, $depth=0) {
        $f->( $root, $depth );
        foreach my $child ( $root->children ) {
            traverse_term( $child, $f, $depth + 1 );
        }
    }

    ## -------------------------------------------------------------------------

    #┌┬┐
    #├┼┤
    #└┴┘
    #╭┬╮
    #├┼┤
    #╰┴╯

    method stack ($top, $bottom) {
        my $max_width = max( map length, (@$top, @$bottom) );
        return [
            map { pad($_, $max_width, true) } (@$top, @$bottom)
        ]
    }

    method shelve ($left, $right, $divider=' ') {
        my $max_height = max( scalar $left->@*, scalar $right->@* );

        my $l_width = max( map length($_), @$left  );
        my $r_width = max( map length($_), @$right );

        my @lines;
        foreach my $i (0 .. ($max_height - 1)) {
            my $line = '';
            if ($i < scalar @$left) {
                $line .= pad($left->[$i], $l_width, true);
            } else {
                $line .= ' ' x $l_width;
            }

            $line .= $divider;

            if ($i < scalar @$right) {
                $line .= $right->[$i];
            } else {
                $line .= ' ' x $r_width;
            }

            push @lines => $line;
        }
        return \@lines;
    }

    method term_tree ($term, %options) {
        state $max_width = $width - 54;

        $options{pprint_width} //= $max_width;
        $options{pprint_width}   = $max_width if $options{pprint_width} > $max_width;

        my $avail = $options{pprint_width};
        my %seen;
        my @lines;
        push @lines => (
            (sprintf ' %-39s │ %8s │ %s' => qw[ type hash pprint ]),
            (('─' x 41).'┼──────────┼'.('─' x $avail))
        );
        traverse_term( $term, sub ($t, $d) {
            unless (exists $seen{ $t->hash }) {
                my $indent = '';
                   $indent = '  ' x $d if $d;
                my $branch = sprintf '%s- %s' => $indent, $t->type;
                my $line   = sprintf '%-40s │ %s │ %s' =>
                             $branch,
                             shorten_hash($t->hash),
                             trim($t->pprint, $avail);

                push @lines => $line;
                $seen{$t->hash}++ if $options{filter_seen};
            }
        });
        return \@lines;
    }

    method arena_commit_table ($arena, %options) {
        my $total = 0;

        my @lines;
        foreach my $commit ($arena->commit_log->@*) {
            $total += scalar $commit->changed->@*;

            my $msg_length  = max(length $commit->message, 40);
            my $avail_space = $msg_length + 8;

            my $top     = '╭──────────┬───────┬─'.('─' x $msg_length).'─╮';
            my $head_b  = '├──────────┴───────┴─'.('─' x $msg_length).'─┤';
            my $top_div = '├──────────┬─────────'.('─' x $msg_length).'─┤';
            my $mid_div = '├──────────┼─────────'.('─' x $msg_length).'─┤';
            my $bottom  = '╰──────────┴─────────'.('─' x $msg_length).'─╯';

            my $header = sprintf "│ %-8s │ %4d+ │ %-${msg_length}s │" =>
                shorten_hash($commit->hash),
                (scalar $commit->changed->@*),
                $commit->message;

            my $head_fmt = "│ %8s │ ".(' ' x $avail_space)." │";
            my $row_fmt  = "│ %8s │ %-${avail_space}s │";
            my $stat_fmt = "│ %-8s : %-${avail_space}s │";


            push @lines => (
                $top,
                $header,
                $head_b,
            );

            if (my $parent = $commit->parent) {
                push @lines => sprintf $stat_fmt => 'parent', shorten_hash($parent->hash);
            }

            push @lines => sprintf $stat_fmt => 'terms', $total;
            push @lines => $top_div;
            push @lines => sprintf $head_fmt => 'roots';
            push @lines => $mid_div;
            foreach my $root ($commit->roots->@*) {
                push @lines => sprintf $row_fmt => shorten_hash($root->hash), $root->type;
            }
            if ($options{show_inserts}) {
                push @lines => $mid_div;
                push @lines => sprintf $head_fmt => 'inserts';
                push @lines => $mid_div;
                foreach my $change ($commit->changed->@*) {
                    push @lines => sprintf $row_fmt => shorten_hash($change->hash), $change->type;
                }
            }
            push @lines => $bottom;
        }

        return \@lines;
    }

    method arena_timing_stat_table ($arena) {
        my $statz = $arena->statz;
        my $timez = $arena->timez;
        return [ grep $_, split /\n/ => sprintf q[
╭───────────────╮
│ ARENA/TIMINGS │
├───────────────┴─────────────╮
│   allocs = %-16s │
│   cached = %-16s │
│  hashing = %-16s │
│      MD5 = %-16s │
╰─────────────────────────────╯]
        => map sprintf('%.08f', $_),
           map { $_ ? $_ * 1000 : 0 }
           $timez->@{qw[ allocated cached hashing MD5 ]}
        ]
    }

    method arena_term_stat_table ($arena) {
        my $statz = $arena->statz;
        my $timez = $arena->timez;
        return [ grep $_, split /\n/ => sprintf q[
╭─────────────╮
│ ARENA/TERMS │
├─────────────┴───────────────╮
│     live = %-16d │
│   unique = %-16d │
│     dups = %-16d │
╰─────────────────────────────╯]
        => map { defined $_ ? $_ : 0 }
           $statz->@{qw[ active allocated cached ]},
        ]
    }

    method arena_type_table ($arena, %options) {
        my $typez  = $arena->typez;
        my @sorted = keys %$typez;

        if ($options{sort_by_active}) {
            @sorted = sort {
                $typez->{$b}->{active} <=> $typez->{$a}->{active}
            } @sorted;
        }

        my @lines;
        push @lines => (
             '╭─────────────╮',
             '│ ARENA/TYPES │',
            ('├──────┬──────┼──────┬───────────────────────╮'),
             '│ live │ uniq │ dups │ types                 │',
            ('├──────┼──────┼──────┼───────────────────────┤'),
        );

        foreach my ($type, $short) (map { $_, shorten_type($_) } @sorted) {
            push @lines =>
                sprintf '│ %4d │ %4d │ %4d │ %s │' =>
                    $typez->{$type}->@{qw[ active allocated cached ]},
                    pad($short, 21, true),
        }

        push @lines => ('╰──────┴──────┴──────┴───────────────────────╯');

        return \@lines;
    }

    method arena_hash_table ($arena, %options) {
        my $terms   = $arena->storage;
        my $hashz   = $arena->hashz;
        my @sorted  = map $_->hash, $arena->full_history;

        $options{sort_by_active} //= $options{top_k};

        if ($options{sort_by_active}) {
            @sorted = sort {
                $hashz->{$b}->{active} <=> $hashz->{$a}->{active}
            } @sorted;

            if (my $top_k = $options{top_k}) {
                @sorted = grep { $hashz->{$_}->{active} >= $top_k } @sorted;
            }
        }
        elsif ($options{sort_by_type}) {
            @sorted = sort {
                $terms->{$a}->type cmp $terms->{$b}->type
            } @sorted;
        }

        my sub serializer ($term, %opts) {
            my $f = $opts{show_types}
                ? sub ($x) { colorize(shorten_type(blessed $x)).'<'.colorize(shorten_hash($x->hash)).'>' }
                : sub ($x) { colorize(shorten_hash($x->hash), true) };

            my %bits = $term->DECOMPOSE;
            return join ' ' => map {
                my $bit = $bits{$_};
                blessed $bit
                    ? (sprintf '%s: %s' => $_, $f->($bit))
                    : not(ref $bit)
                        ? (sprintf '%s: %s' => $_, colorize($bit))
                        : (
                            sprintf '%s: %s%s' => $_,
                                (join ' ' =>
                                    map { $f->($_) }
                                    grep defined,
                                    [@$bit]->@[ 0 .. 10 ]
                                ),
                                (scalar(@$bit) > 10 ? ' ...' : '')
                        )
            } sort { $a cmp $b } grep !/^__/, keys %bits;
        }

        my @lines;
        foreach my $hash (@sorted) {
            my $short = colorize(shorten_hash($hash));
            my $type  = colorize(shorten_type(blessed $terms->{$hash}));
            push @lines =>
                sprintf '%3d %s %s %s' =>
                    $hashz->{$hash}->{active},
                    $short,
                    $type,
                    serializer($terms->{$hash}, %options)
        }

        return \@lines;
    }

}

__END__

## 8-16 colors

        NORMAL | BRIGHT
        FG  BG | FG  BG
Black   30  40 | 90  100
Red     31  41 | 91  101
Green   32  42 | 92  102
Yellow  33  43 | 93  103
Blue    34  44 | 94  104
Magenta 35  45 | 95  105
Cyan    36  46 | 96  106
White   37  47 | 97  107
Default 39  49 | --  ---

# Set style to bold, red foreground.
\x1b[1;31mHello

# Set style to dimmed white foreground with red background.
\x1b[2;37;41mWorld

## 256

ESC[38;5;{ID}m  Set foreground color.
ESC[48;5;{ID}m  Set background color.

ID = 0 - 255

  0-7   : standard colors (as in ESC [ 30–37 m)
  8–15  : high intensity colors (as in ESC [ 90–97 m)
 16-231 : 6 × 6 × 6 cube (216 colors)
232-255 : grayscale from dark to light in 24 steps.

## RGB

ESC[38;2;{r};{g};{b}m   Set foreground color as RGB.
ESC[48;2;{r};{g};{b}m   Set background color as RGB.


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
