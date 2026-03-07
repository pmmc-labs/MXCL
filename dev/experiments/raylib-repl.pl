#!perl

use v5.42;
use experimental qw[ class ];

use Raylib::App;
use MXCL::Context;

my $WIDTH  = 800;
my $HEIGHT = 500;

class REPL::Text {
    use Raylib::FFI;

    field $text     :param = '';
    field $color    :param = Raylib::Color::WHITE;
    field $position :param = [ 0,0 ];

    method text     :lvalue { $text     }
    method color    :lvalue { $color    }
    method position :lvalue { $position }

    method draw ($update=undef) {
        Raylib::FFI::DrawText( ($update // $text), @$position, 20, $color );
    }
}

class REPL::Text::Input :isa(REPL::Text) {
    use Raylib::Keyboard;

    field $context :reader;
    field $output  :reader;

    field $prompt = '@ : ';
    field @buffer;

    ADJUST {
        $self->text     = $prompt;
        $self->color    = Raylib::Color::WHITE;
        $self->position = [ 10, ($HEIGHT - 20) ];

        $output  = REPL::Text::Output->new;
        $context = MXCL::Context->new->initialize;
    }

    my %SHIFT_MAP = (
        q(`)  => q(~),  q(1) => q(!),  q(2) => q(@),  q(3) => q(#),
        q(4)  => q($),  q(5) => q(%),  q(6) => q(^),  q(7) => q(&),
        q(8)  => q(*),  q(9) => q[(],  q(0) => q[)],  q(-) => q(_),
        q(=)  => q(+),  q([) => q({),  q(]) => q(}),  q(\\) => q(|),
        q(;)  => q(:),  q(') => q("),  q(,) => q(<),  q(.) => q(>),
        q(/)  => q(?),
    );

    my sub apply_shift ($ch) {
        return uc($ch)           if $ch =~ /[a-zA-Z]/;
        return $SHIFT_MAP{$ch}   // $ch;
    }

    method reject { pop @buffer }
    method accept ($char) {
        if (Raylib::FFI::IsKeyDown(KEY_LEFT_SHIFT())) {
            $char = apply_shift($char);
        } elsif ($char =~ /[a-zA-Z]/) {
            $char = lc $char;
        }
        push @buffer => $char
    }

    method complete {
        my $code = join '' => @buffer;
        @buffer = ();
        $output->echo( $code );

        my $result = $self->evaluate( $code );
           $result = blessed $result
            ? ($result->stack->isa('MXCL::Term::Nil')
                ? 'nil'
                : (join ' ' => map $_->pprint, $result->stack->uncons))
            : "${result}";
        $output->accept( $result );
    }

    method evaluate ($source, %options) {
        try {
            my $program = $context->compile_source( $source );
            my $result  = $context->evaluate( $context->base_scope, $program );
            return $result;
        } catch ($e) {
            return "GOT ERROR! ${e}";
        }
    }

    method draw {
        my $source = join '' => @buffer;
        $self->SUPER::draw( join '' => $prompt, $source );
        $output->draw;
    }
}

class REPL::Text::Output :isa(REPL::Text) {
    ADJUST {
        $self->text     = '';
        $self->color    = Raylib::Color::SKYBLUE;
        $self->position = [ 10, 10 ];
    }

    method echo ($line) {
        $self->text .= "@ ${line}\n";
    }

    method accept ($line) {
        $self->text .= "> ${line}\n";
    }
}

class REPL {
    use Raylib::Keyboard;

    field $app   = Raylib::App->window( $WIDTH, $HEIGHT, 'Map' );
    field $input = REPL::Text::Input->new;

    ADJUST {
        $app->fps(60);
    }

    field $keyboard = Raylib::Keyboard->new(
        key_map => {
            KEY_APOSTROPHE()    => sub { $input->accept(chr(39)) },
            KEY_COMMA()         => sub { $input->accept(chr(44)) },
            KEY_MINUS()         => sub { $input->accept(chr(45)) },
            KEY_PERIOD()        => sub { $input->accept(chr(46)) },
            KEY_SLASH()         => sub { $input->accept(chr(47)) },
            KEY_ZERO()          => sub { $input->accept(chr(48)) },
            KEY_ONE()           => sub { $input->accept(chr(49)) },
            KEY_TWO()           => sub { $input->accept(chr(50)) },
            KEY_THREE()         => sub { $input->accept(chr(51)) },
            KEY_FOUR()          => sub { $input->accept(chr(52)) },
            KEY_FIVE()          => sub { $input->accept(chr(53)) },
            KEY_SIX()           => sub { $input->accept(chr(54)) },
            KEY_SEVEN()         => sub { $input->accept(chr(55)) },
            KEY_EIGHT()         => sub { $input->accept(chr(56)) },
            KEY_NINE()          => sub { $input->accept(chr(57)) },
            KEY_SEMICOLON()     => sub { $input->accept(chr(59)) },
            KEY_EQUAL()         => sub { $input->accept(chr(61)) },
            KEY_A()             => sub { $input->accept(chr(65)) },
            KEY_B()             => sub { $input->accept(chr(66)) },
            KEY_C()             => sub { $input->accept(chr(67)) },
            KEY_D()             => sub { $input->accept(chr(68)) },
            KEY_E()             => sub { $input->accept(chr(69)) },
            KEY_F()             => sub { $input->accept(chr(70)) },
            KEY_G()             => sub { $input->accept(chr(71)) },
            KEY_H()             => sub { $input->accept(chr(72)) },
            KEY_I()             => sub { $input->accept(chr(73)) },
            KEY_J()             => sub { $input->accept(chr(74)) },
            KEY_K()             => sub { $input->accept(chr(75)) },
            KEY_L()             => sub { $input->accept(chr(76)) },
            KEY_M()             => sub { $input->accept(chr(77)) },
            KEY_N()             => sub { $input->accept(chr(78)) },
            KEY_O()             => sub { $input->accept(chr(79)) },
            KEY_P()             => sub { $input->accept(chr(80)) },
            KEY_Q()             => sub { $input->accept(chr(81)) },
            KEY_R()             => sub { $input->accept(chr(82)) },
            KEY_S()             => sub { $input->accept(chr(83)) },
            KEY_T()             => sub { $input->accept(chr(84)) },
            KEY_U()             => sub { $input->accept(chr(85)) },
            KEY_V()             => sub { $input->accept(chr(86)) },
            KEY_W()             => sub { $input->accept(chr(87)) },
            KEY_X()             => sub { $input->accept(chr(88)) },
            KEY_Y()             => sub { $input->accept(chr(89)) },
            KEY_Z()             => sub { $input->accept(chr(90)) },
            KEY_LEFT_BRACKET()  => sub { $input->accept(chr(91)) },
            KEY_BACKSLASH()     => sub { $input->accept(chr(92)) },
            KEY_RIGHT_BRACKET() => sub { $input->accept(chr(93)) },
            KEY_GRAVE()         => sub { $input->accept(chr(96)) },
            KEY_SPACE()         => sub { $input->accept(" ") },
            KEY_TAB()           => sub { $input->accept("\t") },
            KEY_BACKSPACE()     => sub { $input->reject },
            KEY_ENTER()         => sub { $input->complete },
        },
    );

    method run {
        while ( !$app->exiting ) {
            $keyboard->handle_events();
            $app->clear();
            $app->draw(sub { $input->draw });
        }
    }
}

REPL->new->run;
