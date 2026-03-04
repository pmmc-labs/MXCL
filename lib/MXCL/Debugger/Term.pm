
use v5.42;
use utf8;
use open ':std', ':encoding(UTF-8)';
use experimental qw[ class switch ];

class MXCL::Debugger::Term {
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
        return $string if length $string <= $length;
        return substr($string, 0, ($length - 4)).'...';
    }

    sub get_terminal_size { GetTerminalSize() }

    my ($MAX_WIDTH, $MAX_HEIGHT) = get_terminal_size;

    ## -------------------------------------------------------------------------

    sub traverse_term ($root, $f, $depth=0) {
        given ($root->type) {
            when ('Nil') {
                return;
            }
            when ('Cons') {
                $f->( $root, $depth, true );
                foreach my $child ( $root->uncons ) {
                    traverse_term( $child, $f, $depth + 1 );
                }
                $f->( $root, $depth, false );
            }
            default {
                $f->( $root, $depth );
            }
        }
    }

    method visualize_term ($ctx, $term, %options) {
        my @lines;
        traverse_term( $term, sub ($t, $d, $is_cons=undef) {
            my $indent = '';
               $indent = '│ ' x $d if $d > 0;
            my $fmt = colorize(shorten_hash($t->hash), " %8s ")." │ %s";
            if (not defined $is_cons) {
                push @lines => sprintf $fmt =>
                    shorten_hash($t->hash),
                    (sprintf "\e[2m%s\e[0m%s\e[2m : %s\e[0m" => $indent, $t->value, $t->type);
            }
            elsif ($is_cons == true) {
                push @lines => sprintf $fmt =>
                    shorten_hash($t->hash),
                    (sprintf "\e[2m%s╭─\e[0m" => $indent);
            }
            elsif ($is_cons == false) {
                push @lines => sprintf $fmt =>
                    '...',
                    (sprintf "\e[2m%s╰─\e[0m" => $indent);
            }
        });
        say join "\n" => @lines;
    }

}
