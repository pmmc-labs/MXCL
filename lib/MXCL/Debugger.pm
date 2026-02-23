
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
        my $color = [ map { clamp( 0, 255, ((rand() * 25) * 10)) } qw[ r g b ] ];
        #die Dumper $color;
        $seen{$string} //= $bg ? bg_color( $color, $string ) : fg_color( $color, $string )
    }

    my sub shorten ($hash) { substr $hash, 0, 8 }

    my sub pad ($string, $length) {
        ((' ' x ($length - length($string))).$string)
    }

    my sub trim ($string, $length) {
        return $string if length $string <= $length;
        return substr($string, 0, ($length - 4)).'...';
    }

    sub get_terminal_size { GetTerminalSize() }

    method DEBUG_ARENA ($arena) {
        my $terms   = $arena->terms;
        my $history = $arena->history;

        my ($width, $height) = get_terminal_size;

        my @lines;
        foreach my $hash (@$history) {
            my $short = colorize(shorten($hash));
            my $type  = colorize(pad($terms->{$hash}->type, 20), true);
            my $rest = $width - ((8 + 3) + (20 + 3));
            push @lines =>
                sprintf '%s | %s | %s' =>
                    $short,
                    $type,
                    trim($terms->{$hash}->pprint, $rest),
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
