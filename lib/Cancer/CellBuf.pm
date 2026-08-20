use v5.42;

package Cancer::CellBuf v0.0.1 {
    use parent 'Exporter';
    our %EXPORT_TAGS = (
        all => [
            our @EXPORT_OK
                = qw[
                Cell Line Buffer Screen TabStops Style Link
                BlankCell EmptyCell
                Pos Rect
                wrap_text fill_rect fill clear_rect clear
                set_content_rect set_content render render_line
                ]
        ]
    );
    #
    use Cancer::CellBuf::Cell;
    use Cancer::CellBuf::Line;
    use Cancer::CellBuf::Buffer;
    use Cancer::CellBuf::Screen;
    use Cancer::CellBuf::TabStops;
    use Cancer::CellBuf::Style;
    use Cancer::CellBuf::Link;
    use Cancer::CellBuf::Geom   qw[Pos Rect];
    use Cancer::CellBuf::Writer qw[fill_rect fill clear_rect clear set_content_rect set_content render render_line];
    use Cancer::CellBuf::Wrap   qw[wrap_text];
    #
    sub BlankCell { Cancer::CellBuf::Cell::BlankCell() }
    sub EmptyCell { Cancer::CellBuf::Cell::EmptyCell() }
}
1;
