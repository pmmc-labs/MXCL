
use v5.42;
use utf8;
use open ':std', ':encoding(UTF-8)';
use experimental qw[ class switch ];

class MXCL::Debugger::Tape {
    use Time::HiRes   qw[ sleep ];
    use Term::ReadKey qw[ GetTerminalSize ];
    use List::Util    qw[ min max ];
    use Data::Dumper  qw[ Dumper ];

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
        $string =~ s/\n/\\n/g;
        return $string if length $string <= $length;
        return substr($string, 0, ($length - 4)).'...';
    }

    sub get_terminal_size { GetTerminalSize() }

    my ($MAX_WIDTH, $MAX_HEIGHT) = get_terminal_size;

    ## -------------------------------------------------------------------------


    my sub colorize_kontinue ($k) {
        my $type  = (split /\:\:/ => $k->type)[0];
        my $color = $MXCL::Debugger::KONTINUE_COLORS{ $type };
        my ($fg, $bg) = @$color;
        return "\e[38;5;${fg};48;5;${bg}m %-18s \e[0m";
    }

    ## -------------------------------------------------------------------------

    field $options :reader :param = +{
        filter_kontinue_types  => undef,
        expand_kontinue_fields => true,
        expand_kontinue_stack  => true,
        expand_kontinue_env    => true,
        show_arena_stats       => true,
    };

    method monitor_tape_advance ($ctx, $tape, $k, $next) {
        return unless $ctx->initialized;

        if (my $filter = $options->{filter_kontinue_types}) {
            return unless $k->type =~ $filter;
        }

        my $remaining = $MAX_WIDTH - 38;

        say sprintf((join '' =>
                color([greyscale(20), greyscale(6)], '%05d '),
                colorize_kontinue($k),
                colorize(shorten_hash($k->hash), " %8s "),
                color([144, greyscale(4)], " %-${remaining}s "),
            ) =>
            $tape->steps,
            $k->type,
            shorten_hash($k->hash),
            trim(
                (join ' │ ' =>
                    (@$next ? (join ', ' => map $_->type, reverse @$next) : ()),
                    (join ', ' => map $_->type, reverse $tape->queue->@*)),
                $remaining
            )
        );

        if ($options->{expand_kontinue_fields}) {
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
                                color([greyscale(4), greyscale(10)], " %28s:"),
                                color([greyscale(4), greyscale(12)], " %-${remaining}s "),
                            ),
                            $_->[0],
                            trim($_->[1]->pprint, $remaining),
                        )
                    } @fields;
            }
        }

        if ($options->{expand_kontinue_stack}) {
            my $stack = $k->stack;
            my @stack;
            if ($stack isa MXCL::Term::Cons) {
                my @list = $stack->uncons;
                push @stack =>
                    [ 'stack:', shift @list ],
                    map { [ ' ', $_ ] } @list;
            } else {
                push @stack => [ 'stack:', $stack ];
            }

            my $sep = bg_color(greyscale(6), (' ' x 6));
            say $sep, join "\n${sep}" =>
            map {
                sprintf(
                    (join '' =>
                        color([greyscale(12), greyscale(4)], "  %28s"),
                        color([greyscale(21), greyscale(6)], " %-${remaining}s "),
                    ),
                    $_->[0],
                    trim($_->[1]->pprint, $remaining),
                )
            } @stack;
        }

        if ($options->{expand_kontinue_env}) {
            my $env = $ctx->roles->Difference(
                $ctx->roles->AsymmetricDifference( $ctx->base_scope, $k->env ),
                $ctx->base_scope,
            );
            my @env;
            foreach my $slot ($env->slots->@*) {
                push @env, [ $slot->ident->value, $slot ];
            }

            my $sep = bg_color(greyscale(6), (' ' x 6));
            say $sep, join "\n${sep}" =>
            map {
                sprintf(
                    (join '' =>
                        color([[30,50,120],[0,120,200]], " %28s:"),
                        color([[60,60,180],[60,180,240]], " %-${remaining}s "),
                    ),
                    $_->[0],
                    trim($_->[1]->pprint, $remaining),
                )
            } @env;
        }

        if ($options->{show_arena_stats}) {
            my @fields = (
                [ arena => sprintf "\e[1mallocated:\e[22m %05d \e[1mcached:\e[22m %05d \e[1mactive:\e[22m %05d " =>
                    $ctx->arena->statz->{active},
                    $ctx->arena->statz->{cached},
                    $ctx->arena->statz->{allocated} ],
            );

            if (@fields) {
                my $rest = $remaining - 47;
                my $sep = bg_color(greyscale(6), (' ' x 6));
                say $sep, join "\n${sep}" =>
                    map {
                        sprintf(
                            (join '' =>
                                bg_color(greyscale(6), "%30s"),
                                color([[130,190,130],[65,90,65]], " %${rest}s:"),
                                color([[62,89,62],[132,191,132]], " %46s "),
                            ),
                            ' ',
                            @$_,
                        )
                    } @fields;
            }
        }
    }

}
