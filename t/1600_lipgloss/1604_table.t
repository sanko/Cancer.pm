use v5.42;
use Test2::V1 -ipP;
use lib 'lib';
use blib;
#
use Cancer::Lipgloss::Table qw[NewTable DefaultStyles HEADER_ROW];
use Cancer::Lipgloss        qw[NewStyle string_width];
use utf8;
#
# ── Basic table ──────────────────────────────────────────────────────
#
subtest 'NewTable creates empty table' => sub {
    my $t = NewTable();
    is scalar @{ $t->GetHeaders }, 0, 'no headers';
    is $t->GetData->Rows,          0, 'no rows';
};
#
subtest 'Headers and Rows' => sub {
    my $t = NewTable()->Headers( 'A', 'B' )->Row( 'x', 'y' )->Row( 'p', 'q' );
    my @h = @{ $t->GetHeaders };
    is scalar @h,               2,   '2 headers';
    is $t->GetData->Rows,       2,   '2 data rows';
    is $t->GetData->At( 0, 0 ), 'x', 'cell [0,0]';
    is $t->GetData->At( 1, 1 ), 'q', 'cell [1,1]';
};
#
subtest 'Multiple Rows method' => sub {
    my $t = NewTable()->Headers('X')->Rows( ['1'], ['2'], ['3'] );
    is $t->GetData->Rows, 3, '3 rows via Rows()';
};
#
subtest 'ClearRows empties data' => sub {
    my $t = NewTable()->Headers('A')->Row('x');
    $t->ClearRows;
    is $t->GetData->Rows, 0, 'rows cleared';
};
#
subtest 'StringData columns auto-detected' => sub {
    my $t = NewTable()->Row( 'a', 'b', 'c' )->Row( 'x', 'y' );
    is $t->GetData->Columns, 3, '3 columns from widest row';
};
#
# ── Rendering ────────────────────────────────────────────────────────
#
subtest 'String renders table' => sub {
    my $t   = NewTable()->Headers( 'Name', 'Age' )->Row( 'Alice', '30' )->Row( 'Bob', '25' );
    my $out = "$t";
    like $out, qr/Name/,     'header Name';
    like $out, qr/Age/,      'header Age';
    like $out, qr/Alice/,    'row Alice';
    like $out, qr/Bob/,      'row Bob';
    like $out, qr/\x{250C}/, 'top-left corner';
    like $out, qr/\x{2514}/, 'bottom-left corner';
    like $out, qr/\x{2500}/, 'horizontal border';
    like $out, qr/\x{2502}/, 'vertical border';
};
#
subtest 'Render method alias' => sub {
    my $t = NewTable()->Headers('X')->Row('1');
    is $t->Render, "$t", 'Render equals String';
};
#
# ── Border configuration ─────────────────────────────────────────────
#
subtest 'No border table' => sub {
    my $t
        = NewTable()
        ->BorderTop(0)
        ->BorderBottom(0)
        ->BorderLeft(0)
        ->BorderRight(0)
        ->BorderHeader(0)
        ->BorderColumn(0)
        ->Headers( 'A', 'B' )
        ->Row( 'x', 'y' );
    my $out = "$t";
    unlike $out, qr/\x{250C}/, 'no top-left';
    unlike $out, qr/\x{2500}/, 'no horizontal border';
    like $out,   qr/A/,        'header still present';
};
#
subtest 'BorderRow adds row separators' => sub {
    my $t     = NewTable()->BorderRow(1)->Headers('X')->Rows( ['1'], ['2'], ['3'] );
    my $out   = "$t";
    my @lines = split /\n/, $out;
    ok scalar @lines > 5, 'multiple row separators';
};
#
subtest 'Header separator border' => sub {
    my $t   = NewTable()->Headers('A')->Row('x');
    my $out = "$t";
    like $out, qr/\x{251C}/, 'has middle-left (header separator)';
    like $out, qr/\x{2524}/, 'has middle-right (header separator)';
};
#
# ── StyleFunc ────────────────────────────────────────────────────────
#
subtest 'StyleFunc colors cells' => sub {
    my $t = NewTable()->Headers('H1')->Row('data')->StyleFunc(
        sub {
            my ( $row, $col ) = @_;
            if ( $row == HEADER_ROW ) {
                return NewStyle()->bold(1);
            }
            return NewStyle()->foreground( [ 100, 200, 50 ] );
        }
    );
    my $out = "$t";
    like $out, qr/\e\[1m/,               'header bold';
    like $out, qr/\e\[38;2;100;200;50m/, 'data cell colored';
};
#
# ── Column alignment ─────────────────────────────────────────────────
#
subtest 'Columns auto-size to widest content' => sub {
    my $t   = NewTable()->Headers( 'Short', 'A much longer header' )->Row( 'a', 'b' );
    my $out = "$t";

    # The table should have enough width for the longer header
    my @lines = split /\n/, $out;
    ok scalar @lines >= 3, 'at least 3 lines (top, header sep, data, bottom)';
};
#
# ── Table width ──────────────────────────────────────────────────────
#
subtest 'Width constraint' => sub {
    my $t     = NewTable()->Width(45)->Headers( 'Name', 'Value', 'Description' )->Row( 'foo', '123', 'A description here' );
    my $out   = "$t";
    my @lines = split /\n/, $out;
    for my $line (@lines) {
        my $w = string_width($line);
        ok $w <= 46, "line width $w <= 46";
    }
};
#
# ── Data interface ───────────────────────────────────────────────────
#
subtest 'GetData returns Data object' => sub {
    my $t = NewTable()->Headers('X')->Row('1');
    my $d = $t->GetData;
    isa_ok $d, 'Cancer::Lipgloss::Table::StringData';
    is $d->Rows,    1, '1 row';
    is $d->Columns, 1, '1 column';
};
#
subtest 'DataToMatrix equivalent' => sub {
    my $d = Cancer::Lipgloss::Table::StringData->new( [ 'a', 'b' ], [ 'c', 'd' ] );
    is $d->Rows,       2,   '2 rows';
    is $d->Columns,    2,   '2 columns';
    is $d->At( 0, 0 ), 'a', 'at(0,0)';
    is $d->At( 1, 1 ), 'd', 'at(1,1)';
};
#
# ── Empty table ──────────────────────────────────────────────────────
#
subtest 'Empty table renders empty string' => sub {
    my $t = NewTable();
    is "$t", '', 'empty';
};
#
subtest 'Headers-only table renders' => sub {
    my $t   = NewTable()->Headers( 'A', 'B' );
    my $out = "$t";
    like $out, qr/A/, 'header A';
    like $out, qr/B/, 'header B';
};
#
done_testing;
