
use v5.42;
use utf8;
use open ':std', ':encoding(UTF-8)';
use experimental qw[ class switch ];

class MXCL::Tape::Debugger {
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

    my sub pick_color_type ($color, $fg=false, $bg=false) {
        return ref $color
                ? scalar @$color == 3
                ? rgb_fg_color($color) : core_fg_color($color)
                                       : c256_fg_color($color) if $fg;
        return ref $color
                ? scalar @$color == 3
                ? rgb_bg_color($color) : core_bg_color($color)
                                       : c256_bg_color($color) if $bg;

        return ref $color && ref $color->[0]
                ? scalar @{$color->[0]} == 3 ? rgb_color(@$color) : core_color($color)
                : c256_color(@$color)
    }

    my sub fg_color ($color, $string) {
        return sprintf '%s%s%s' => pick_color_type($color, true), $string, reset_style;
    }

    my sub bg_color ($color, $string) {
        return sprintf '%s%s%s' => pick_color_type($color, false, true), $string, reset_style;
    }

    my sub color ($color, $string) {
        return sprintf '%s%s%s' => pick_color_type($color), $string, reset_style;
    }

    my sub colorize ($string, $template, $bg=false) {
        state %seen;
        my $color = [ map { clamp( 8, 16, rand() * 20 ) * 16 } qw[ r g b ] ];
        #die Dumper $color;
        $seen{$string} //= $bg ? bg_color( $color, $template ) : fg_color( $color, $template )
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

    my ($MAX_WIDTH, $MAX_HEIGHT) = get_terminal_size;

    ## -------------------------------------------------------------------------

    method monitor_tape_advance ($ctx, $tape, $k, $next) {
        my $remaining = $MAX_WIDTH - 60;

        say sprintf((join '' =>
                color([greyscale(20), greyscale(6)], '%05d '),
                colorize($k->type, ' %-18s ', true),
                colorize(shorten_hash($k->hash), " %8s "),
                color([greyscale(21), greyscale(2)], " %-${remaining}s"),
            ) =>
            $tape->steps,
            $k->type,
            shorten_hash($k->hash),
            ($k->stack isa MXCL::Term::Nil ? ' ' : trim($k->stack->pprint, $remaining)),
        );

        my %kont   = $k->DECOMPOSE;
        my $env    = delete $kont{env};
        my $stack  = delete $kont{stack};
        my @fields = grep {
            blessed($_->[1])
        } map {
            [ $_, $kont{$_} ]
        } sort {
            $a cmp $b
        } keys %kont;

        if (@fields) {
            my $sep = bg_color(greyscale(6), (' ' x 6));
            say $sep, join "\n${sep}" =>
                map {
                    sprintf(
                        (join '' =>
                            color([greyscale(12), greyscale(4)], " %28s:"),
                            color([greyscale(21), greyscale(6)], " %-${remaining}s"),
                            #color([greyscale(16), greyscale(8)], " %10s"),
                        ),
                        $_->[0],
                        trim($_->[1]->pprint, $remaining),
                        #' '
                    )
                } @fields;
        }
    }
    ## -------------------------------------------------------------------------

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
}
