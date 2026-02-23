
use v5.42;
use utf8;
use open ':std', ':encoding(UTF-8)';
use experimental qw[ class ];


class MXCL::Debugger {
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

    my sub shorten_hash ($hash) { '#'.substr $hash, 0, 8 }
    my sub shorten_type ($type) {
        my $short = $type =~ s/^MXCL\:\:Term\:\://r;
        $short =~ s/^Kontinue\:\:/k\//;
        $short =~ s/^Role\:\:/r\//;
        $short = "t/${short}" if $short =~ /^[^rk]/;
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

    #┌┬┐
    #├┼┤
    #└┴┘
    #╭┬╮
    #├┼┤
    #╰┴╯

    method arena_timing_stat_table ($arena) {
        my $statz = $arena->statz;
        my $timez = $arena->timez;
        return [ split /\\n/ => sprintf q[
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
           $timez->@{qw[ misses hits hashing MD5 ]}
        ]
    }

    method arena_term_stat_table ($arena) {
        my $statz = $arena->statz;
        my $timez = $arena->timez;
        return [ split /\\n/ => sprintf q[
╭─────────────╮
│ ARENA/TERMS │
├─────────────┴───────────────╮
│     live = %-16d │
│   unique = %-16d │
│     dups = %-16d │
╰─────────────────────────────╯]
        => map { defined $_ ? $_ : 0 }
           $statz->@{qw[ alive misses hits ]},
        ]
    }

    method arena_type_table ($arena, %options) {
        my $terms   = $arena->terms;
        my $typez   = $arena->typez;
        my @sorted  = keys %$typez;

        if ($options{sort_by_alive}) {
            @sorted = sort {
                $typez->{$b}->{alive} <=> $typez->{$a}->{alive}
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
                    $typez->{$type}->@{qw[ alive misses hits ]},
                    colorize(pad($short, 21, true)),
        }

        push @lines => ('╰──────┴──────┴──────┴───────────────────────╯');

        return \@lines;
    }

    method arena_hash_table ($arena, %options) {
        my $terms   = $arena->terms;
        my $history = $arena->history;
        my $hashz   = $arena->hashz;
        my @sorted  = @$history;

        $options{sort_by_alive} //= $options{top_k};

        if ($options{sort_by_alive}) {
            @sorted = sort {
                $hashz->{$b}->{alive} <=> $hashz->{$a}->{alive}
            } @sorted;

            if (my $top_k = $options{top_k}) {
                @sorted = grep { $hashz->{$_}->{alive} >= $top_k } @sorted;
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
                    $hashz->{$hash}->{alive},
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
