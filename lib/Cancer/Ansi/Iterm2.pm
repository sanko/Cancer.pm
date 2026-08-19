package Cancer::Ansi::Iterm2 v0.0.1 {
    use v5.42;
    use Exporter 'import';
    our @EXPORT_OK = qw[
        Auto Cells Pixels Percent
        FileOpts File MultipartFile FilePart FileEnd
    ];
    use constant Auto => 'auto';
    sub Cells   ($n) {"$n"}
    sub Pixels  ($n) {"${n}px"}
    sub Percent ($n) {"${n}%"}

    sub FileOpts ($f) {
        my @opts;
        push @opts, "name=$f->{Name}"       if $f->{Name};
        push @opts, "size=$f->{Size}"       if $f->{Size};
        push @opts, "width=$f->{Width}"     if $f->{Width};
        push @opts, "height=$f->{Height}"   if $f->{Height};
        push @opts, "preserveAspectRatio=0" if $f->{IgnoreAspectRatio};
        push @opts, "inline=1"              if $f->{Inline};
        push @opts, "doNotMoveCursor=1"     if $f->{DoNotMoveCursor};
        return join ';', @opts;
    }

    sub File ($f) {
        my $s = 'File=' . FileOpts($f);
        $s .= ":$f->{Content}" if defined $f->{Content};
        return $s;
    }
    sub MultipartFile ($f) { 'MultipartFile=' . FileOpts($f) }
    sub FilePart      ($f) { 'FilePart=' . $f->{Content} }
    sub FileEnd       ($f) {'FileEnd'}
};
#
1;
