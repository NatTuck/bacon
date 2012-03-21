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
use File::Temp;

use Bacon::MatchToken;
use Bacon::Token;

my @symbols = qw#
    enum extern register
    global local private
    auto break case char const continue default double do else
    float for goto if int long return short signed
    sizeof static struct switch typedef union void volatile while
    inline uchar ushort uint ulong
    kernel Array2D Array3D Array2Z Array3Z Image2D Image3D Array
    fail assert
    + - * / { } ( ) [ ] < > ; : = & ! ~ % ^ | ? .
#;
push @symbols, ',';

my @token = (
    SETUP   => 'SETUP:',
    BODY    => 'BODY:',
    SPACE   => '\s+',
    CONSTANT => '(?:0[xX][0-9a-fA-F]+|[0-9]+(\.[0-9]*)?[uU]?[lL]?f?)',
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
    RANGE => q("@range"),
    GROUP => q("@group"),
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

sub preprocess {
    my (@lines) = @_;

    # Find and replace OpenCL include
    # directives.
    for (@lines) {
        chomp;
        s/^\s*#include\s+"(.*)\.cl"\s*$/\@include "$1.cl"/m;
    }

    # Run the rest through the C preprocessor.
    my $tmp1 = File::Temp->new(SUFFIX => '.tmp');
    $tmp1->print(join("\n", @lines), "\n");

    my $tmp2 = File::Temp->new(SUFFIX => '.tmp');
    my $base = $ENV{BACON_BASE};
    system(qq{cpp -I "$base/include/bcn" -o "$tmp2" "$tmp1"});

    system(qq{cp "$tmp2" /tmp/debug-cpp.bc});

    return read_file($tmp2);
}

sub make_lexer {
    my ($src_file) = @_;
    my $input = preprocess(read_file($src_file));

    my $file = $src_file;
    my $line = 1;

    my @tokens = ();

  token: 
    while ($input =~ /\S/) {
      again:  
        if ($input =~ /^\n/) {
            $input =~ s/^\n//;
            ++$line;
            goto again;
        }

        if ($input =~ m{^//}) {
            $input =~ s{\A//.*?$}{}m;
            goto again;
        }

        if ($input =~ /^#(.*?)\n/) {
            my $dv = $1;
            $input =~ s/^#.*?\n/\n/m;
            if ($dv =~ /^\s+(\d+)\s+"(.*)?"/) {
                $line = $1;
                $file = $2;
                $file = $src_file if ($file =~ /\.tmp$/);
            }
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
                push @tokens, [$sym, $tok];
                next token;
            }
        }

        die "Could not tokenize input near line $line:\n" . 
            substr($input, 0, 16);
    }

    return sub {
        return undef unless (scalar @tokens);
        return @{shift @tokens};
    };
}

1;
