#!perl

use v5.42;
use experimental qw[ class switch ];

use List::Util    qw[ sum min max reduce ];
use Term::ReadKey qw[ GetTerminalSize ];
use Data::Dumper  qw[ Dumper ];

sub hex2rgb ($hex) { +[ map int(($_ / 255) * 255), unpack 'C*', pack 'H*', $hex ] }

our %PANTONE = (
    BLACK               => hex2rgb('000000'),
    WHITE               => hex2rgb('FFFFFF'),
    GREY                => hex2rgb('CCCCCC'),
    RED                 => hex2rgb('FF0000'),
    GREEN               => hex2rgb('00FF00'),
    BLUE                => hex2rgb('0000FF'),
    cardinalRed         => hex2rgb('C41E3A'),
    deepCerulean        => hex2rgb('007BA7'),
    electricLime        => hex2rgb('CCFF00'),
    fuchsiaRose         => hex2rgb('C74375'),
    goldenPoppy         => hex2rgb('FCC200'),
    heliotropePurple    => hex2rgb('DF73FF'),
    irisBlue            => hex2rgb('5A4FCF'),
    jadeGreen           => hex2rgb('00A86B'),
    kellyGreen          => hex2rgb('4CBB17'),
    lapisLazuli         => hex2rgb('26619C'),
    mardiGras           => hex2rgb('880085'),
    neonCarrot          => hex2rgb('FFA343'),
    operaMauve          => hex2rgb('B784A7'),
    persianBlue         => hex2rgb('1C39BB'),
    quinacridoneMagenta => hex2rgb('8E3A59'),
    raspberryPink       => hex2rgb('E25098'),
    sapphireBlue        => hex2rgb('0F52BA'),
    tangerineYellow     => hex2rgb('FFCC00'),
    ultramarineBlue     => hex2rgb('3F00FF'),
    venetianRed         => hex2rgb('C80815'),
    wengeWood           => hex2rgb('645452'),
    xanaduGreen         => hex2rgb('738678'),
    yellowGreen         => hex2rgb('9ACD32'),
    zaffreBlue          => hex2rgb('0014A8'),
    amaranthPink        => hex2rgb('F19CBB'),
    byzantiumPurple     => hex2rgb('702963'),
    coquelicotOrange    => hex2rgb('FF3800'),
    dandelionYellow     => hex2rgb('F0E130'),
    emeraldGreen        => hex2rgb('50C878'),
    flaxFlowerBlue      => hex2rgb('1C3B2B'),
    ghostWhite          => hex2rgb('F8F8FF'),
    hollywoodCerise     => hex2rgb('F400A1'),
    indigoDye           => hex2rgb('00416A'),
    jasmineFlower       => hex2rgb('F8DE7E'),
    keppelColor         => hex2rgb('3AB09E'),
    libertyPurple       => hex2rgb('545AA7'),
    moonstoneBlue       => hex2rgb('73A9C2'),
    nadeshikoPink       => hex2rgb('F6ADC6'),
    outerSpaceBlack     => hex2rgb('414A4C'),
    persimmonOrange     => hex2rgb('EC5800'),
    quickSilver         => hex2rgb('A6A6A6'),
    razzmatazzPink      => hex2rgb('E3256B'),
    sunglowYellow       => hex2rgb('FFCC33'),
    twilightLavender    => hex2rgb('8A496B'),
    urobilinYellow      => hex2rgb('E1AD21'),
    violetColor         => hex2rgb('7F00FF'),
    waterspoutBlue      => hex2rgb('A4F4F9'),
    xanthicYellow       => hex2rgb('EEED09'),
    yaleBlue            => hex2rgb('0F4D92'),
    zompGreen           => hex2rgb('39A78E'),
    absoluteZero        => hex2rgb('0048BA'),
    acidGreen           => hex2rgb('B0BF1A'),
    aero                => hex2rgb('7CB9E8'),
    africanViolet       => hex2rgb('B284BE'),
    airSuperiorityBlue  => hex2rgb('72A0C1'),
    alabaster           => hex2rgb('EDEAE0'),
    aliceBlue           => hex2rgb('F0F8FF'),
    alloyOrange         => hex2rgb('C46210'),
    almond              => hex2rgb('EFDECD'),
    amaranth            => hex2rgb('E52B50'),
    amber               => hex2rgb('FFBF00'),
    amethyst            => hex2rgb('9966CC'),
    antiqueBrass        => hex2rgb('CD9575'),
    antiqueBronze       => hex2rgb('665D1E'),
    antiqueRuby         => hex2rgb('841B2D'),
    antiqueWhite        => hex2rgb('FAEBD7'),
    aoEnglish           => hex2rgb('008000'),
    appleGreen          => hex2rgb('8DB600'),
    apricot             => hex2rgb('FBCEB1'),
    aqua                => hex2rgb('00FFFF'),
    aquamarine          => hex2rgb('7FFFD4'),
    arcticLime          => hex2rgb('D0FF14'),
    armyGreen           => hex2rgb('4B5320'),
    artichoke           => hex2rgb('8F9779'),
    arylideYellow       => hex2rgb('E9D66B'),
    ashGray             => hex2rgb('B2BEB5'),
    asparagus           => hex2rgb('87A96B'),
    atomicTangerine     => hex2rgb('FF9966'),
    auburn              => hex2rgb('A52A2A'),
    aureolin            => hex2rgb('FDEE00'),
    avocado             => hex2rgb('568203'),
    azure               => hex2rgb('007FFF'),
    babyBlue            => hex2rgb('89CFF0'),
    babyBlueEyes        => hex2rgb('A1CAF1'),
    babyPink            => hex2rgb('F4C2C2'),
    babyPowder          => hex2rgb('FEFEFA'),
    bakerMillerPink     => hex2rgb('FF91AF'),
    bananaMania         => hex2rgb('FAE7B5'),
    barbiePink          => hex2rgb('DA1884'),
    barnRed             => hex2rgb('7C0A02'),
    battleshipGrey      => hex2rgb('848482'),
    bazaar              => hex2rgb('98777B'),
    beauBlue            => hex2rgb('BCD4E6'),
    beaver              => hex2rgb('9F8170'),
    begonia             => hex2rgb('FA6E79'),
    beige               => hex2rgb('F5F5DC'),
);

my ($MAX_WIDTH, $MAX_HEIGHT) = GetTerminalSize();

class Cell {
    use constant LEFT   => -1;
    use constant CENTER =>  0;
    use constant RIGHT  =>  1;

    use constant TOP    => -1;
    use constant MIDDLE =>  0;
    use constant BOTTOM =>  1;

    use constant BOLD      => 1;
    use constant FAINT     => 2;
    use constant ITALIC    => 3;
    use constant UNDERLINE => 4;
    use constant INVERT    => 7;
    use constant HIDE      => 8;
    use constant STRIKE    => 9;

    field $content  :param :reader;
    field $align    :param :reader = LEFT;
    field $valign   :param :reader = TOP;
    field $width    :param :reader = undef;
    field $height   :param :reader = undef;
    field $fg_color :param :reader = undef;
    field $bg_color :param :reader = undef;
    field $padding  :param :reader = ' ';
    field $styles   :param :reader = +[];

    method clone (%options) {
        __CLASS__->new(
            # ... copy everything
            content  => $content,
            align    => $align,
            valign   => $valign,
            width    => $width,
            height   => $height,
            fg_color => $fg_color,
            bg_color => $bg_color,
            padding  => $padding,
            styles   => $styles,
            # ... and override as needed
            %options
        )
    }

    method render  {
        my $w = $width // length $content;
        my $output;
        if ($w < length $content) {
            $output = substr $content, 0, $w;
        }
        else {
            my $remaining = $w - length $content;
            given ($align) {
                when (LEFT) {
                    $output = $content . ($padding x $remaining);
                }
                when (CENTER) {
                    my ($lhs, $rhs) = (0, 0);
                    if (($remaining % 2) == 0) {
                        my $split = int($remaining/2);
                        ($lhs, $rhs) = ($split, $split)
                    } else {
                        my $split = $remaining / 2;
                        ($lhs, $rhs) = (ceil($split), floor($split))
                    }
                    $output = ($padding x $lhs) . $content . ($padding x $rhs);
                }
                when (RIGHT) {
                    $output = ($padding x $remaining) . $content;
                }
            }
        }

        my @codes = @$styles;
        push @codes => 38, 2, @$fg_color if defined $fg_color;
        push @codes => 48, 2, @$bg_color if defined $bg_color;

        my ($prefix, $postfix) = ('', '');
        if (@codes) {
            $prefix  = "\e[".(join ';' => @codes).";m";
            $postfix = "\e[0m";
        }

        my @lines;
        if (defined $height && $height > 1) {
            my $blank_line = $padding x $w;
            my $remaining  = $height - 1;
            given ($valign) {
                when (TOP) {
                    push @lines => $output, (($blank_line) x $remaining);
                }
                when (MIDDLE) {
                    if (($remaining % 2) == 0) {
                        my $split = int($remaining/2);
                        push @lines => (($blank_line) x $split), $output, (($blank_line) x $split);
                    } else {
                        my $split = $remaining / 2;
                        my ($above, $below) = (floor($split), ceil($split));
                        say "HEIGHT: ${height} REMAINING: ${remaining} SPLIT: ${split} ABOVE: ",$above," BELOW: ",$below;
                        push @lines => (($blank_line) x $above), $output, (($blank_line) x $below)
                    }
                }
                when (BOTTOM) {
                    push @lines => (($blank_line) x $remaining), $output;
                }
            }
        } else {
            push @lines => $output;
        }

        my @output;
        foreach my $line (@lines) {
            push @output => join '' => ($prefix, $line, $postfix)
        }

        return \@output;
    }
}

class Row {
    field $cells  :param :reader;
    field $height :reader;

    ADJUST {
        $height = List::Util::max( map { $_->height // 0 } @$cells );
        @$cells = map { $_->clone(height => $_->height) } @$cells;
    }

    method render {
        my @outputs = map $_->render, @$cells;

        return +[ join '' => map $_->[0], @outputs ]
            if !$height || $height == 1;

        my @output;
        for (my $i = 0; $i < $height; $i++) {
            push @output => join '' => map { $_->[$i] } @outputs;
        }

        return \@output;
    }
}


my @colors = sort { $a cmp $b } keys %PANTONE;
my $max_length = max map length($_), @colors;

my @rows;
foreach my ($c1, $c2, $c3, $c4, $c5, $c6, $c7, $c8) (@colors) {
    my @row;
    foreach (grep defined, $c1, $c2, $c3, $c4, $c5, $c6, $c7, $c8) {
        push @row => Cell->new(
            content  => $_,
            align    => Cell->CENTER,
            valign   => Cell->MIDDLE,
            width    => $max_length,
            height   => 3,
            bg_color => $PANTONE{$_},
            fg_color => $PANTONE{BLACK},
            padding  => ' ',
        )
    }
    push @rows => Row->new( cells => \@row );
}

say foreach map $_->render->@*, @rows;

__END__




