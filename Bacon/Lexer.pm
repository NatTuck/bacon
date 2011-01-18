package Bacon::Lexer;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

# Tokens taken from ANSI C Lex specification origionally by Jeff Lee,
# found at http://www.lysator.liu.se/c/ANSI-C-grammar-l.html

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(make_lexer);

use File::Slurp;

use Bacon::MatchToken;
use Bacon::Token;

my @symbols = qw#
    auto break case char const continue default do
    double else enum extern float for goto if int 
    long register return short signed sizeof static
    struct switch typedef union unsigned void volatile
    while inline
    kernel array2d array3d image2d image3d
    fail assert
    + - * / { } ( ) [ ] < > ; @ : = & ! ~ % ^ | ? .
#;
push @symbols, ',';

my @token = (
    SPACE   => '\s+',
    CONSTANT => '(0[xX])?[0-9]+(\.[0-9]*)?[uU]?[lL]?',
    STRING => '\"[^"]*\"',
    ELLIPSIS => q("..."),
    RIGHT_ASSIGN => q(">>="),
    LEFT_ASSIGN => q("<<="),
    ADD_ASSIGN => q("+="),
    SUB_ASSIGN => q("-="),
    MUL_ASSIGN => q("*="),
    DIV_ASSIGN => q("/="),
    MOD_ASSIGN => q("%="),
    AND_ASSIGN => q("&="),
    XOR_ASSIGN => q("^="),
    OR_ASSIGN => q("|="),
    RIGHT_OP => q(">>"),
    LEFT_OP => q("<<"),
    INC_OP => q("++"),
    DEC_OP => q("--"),
    PTR_OP => q("->"),
    AND_OP => q("&&"),
    OR_OP => q("||"),
    LE_OP => q("<="),
    GE_OP => q(">="),
    EQ_OP => q("=="),
    NE_OP => q("!="),
);

for my $sym (@symbols) {
    push @token, uc($sym);
    push @token, qq{"$sym"};
}

push @token, (IDENTIFIER => '[$]?[A-Za-z_][A-Za-z0-9_]*');

my @pats = ();

while (scalar @token > 0) {
    my ($sym, $pat) = (shift @token, shift @token);
    push @pats, Bacon::MatchToken->new($sym, $pat);
}

sub make_lexer {
    my ($file) = @_;
    my $input = read_file($file);

    my $line  = 1;

    return sub {
      again:  
        while ($input =~ /^\n/) {
            $input =~ s/^\n//;
            ++$line;
        }

        if ($input =~ m{^//}) {
            $input =~ s{\A//.*?$}{}m;
            goto again;
        }

        if ($input =~ m{\A/\*.*?\*/}ms) {
            $input =~ m{\A/\*.*?\*/}ms;
            my $comment = $&;
            my @ns = $comment =~ /\n/g;
            $line += scalar @ns;
            substr($input, 0, length $comment, '');
            goto again;
        }

        if (length $input == 0) {
            return ('', undef);
        }

        for my $pat (@pats) {
            my ($sym, $text) = $pat->match(\$input);
            if (defined $sym) {
                goto again if $sym eq 'SPACE';
                my $tok = Bacon::Token->new(
                    type => $sym,  text => $text, 
                    file => $file, line => $line
                );
                return ($sym, $tok);
            }
        }

        die "Could not tokenize input near line $line:\n" . 
            substr($input, 0, 16);
    };
}

1;
