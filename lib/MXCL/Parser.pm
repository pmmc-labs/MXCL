
use v5.42;
use experimental qw[ class switch ];

use MXCL::Term::Parser::Token;
use MXCL::Term::Parser::Compound;

class MXCL::Parser {
    field $alloc :param :reader;

    method parse ($source) {
        my $tokens = $self->tokenize($source);

        my @exprs;
        while (@$tokens) {
            my $expr = $self->parse_expression($tokens);
            push @exprs => $expr;
        }

        return \@exprs;
    }

    method tokenize ($source) {
        my @tokens;
        my $line_no = 0;
        my $line_at = 0;
        my $char_at = 0;
        while ($source =~ m/(\+\{|\}|\+\[|\]|\(|\)|"(?:[^"\\])*"|;[^\n]*|\s|[^\s\(\)\{\}\[\]]+)/g) {
            my $match = $1;
            if ($match eq "\n") {
                $line_no++;
                $char_at = $line_at = pos($source);
            }
            elsif ($match eq " " || $match =~ /^;/) {
                $char_at = pos($source);
            }
            else {
                my $start = $char_at - $line_at;
                $char_at = pos($source);

                push @tokens => $alloc->Token(
                    source => $match,
                    start  => $start,
                    end    => $char_at - $line_at,
                    line   => $line_no,
                    pos    => pos($source)
                );
            }
        }
        return \@tokens;
    }

    method parse_expression ($tokens) {
        my $token = shift @$tokens;

        return $self->parse_compound(MXCL::Parser::CompoundBuilder->new( open => $token ), $tokens)
            if $self->is_opening_bracket($token);

        if ($token->source eq "'") {
            return $self->build_compound(MXCL::Parser::CompoundBuilder->new(
                open  => $token,
                items => [ $self->parse_expression($tokens) ]
            ));
        }

        return $token;
    }

    method build_compound ($builder) {
        return $alloc->Compound(
            ($builder->open  // $alloc->Token(source => '(')),
            ($builder->items->@*),
            ($builder->close // $alloc->Token(source => ')')),
        )
    }

    method parse_compound ( $compound, $tokens ) {
        if ($self->is_closing_bracket($tokens->[0])) {
            my $close = shift @$tokens;
            $compound->close = $self->do_brackets_match($compound, $close);
            return $self->build_compound( $compound );
        }
        my $expr = $self->parse_expression($tokens);
        return $self->parse_compound( $compound->push( $expr ), $tokens );
    }

    method is_opening_bracket ($token) {
        return $token->source eq '('
            || $token->source eq '+{'
            || $token->source eq '+['
    }

    method is_closing_bracket ($token) {
        return $token->source eq ')'
            || $token->source eq '}'
            || $token->source eq ']'
    }

    method do_brackets_match ($compound, $close) {
        given ($close->source) {
            when (')') {
                $compound->open->source eq '('
                    || die ("Unbalanced Brackets: Expected ) and got "
                            .$compound->open->source)
            }
            when (']') {
                $compound->open->source eq '+['
                    || die ("Unbalanced Brackets: Expected ] and got "
                            .$compound->open->source)
            }
            when ('}') {
                $compound->open->source eq '+{'
                    || die ("Unbalanced Brackets: Expected } and got "
                            .$compound->open->source)
            }
        }

        return $close;
    }
}

class MXCL::Parser::CompoundBuilder {
    field $items :param :reader = +[];

    field $open  :param = undef;
    field $close :param = undef;

    method open  :lvalue { $open  }
    method close :lvalue { $close }

    method push (@items) { push @$items => @items; $self }

    method stringify {
        sprintf 'CompoundBuilder:%s %s %s' =>
                ($open->source // '~'),
                (join ', ' => map $_->stringify, @$items),
                ($close->source // '~')
    }

    method pprint { $self->stringify }
}


